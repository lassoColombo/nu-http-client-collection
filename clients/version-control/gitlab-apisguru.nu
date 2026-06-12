# Auto-generated client for Gitlab vv3
# Source: https://api.apis.guru/v2/specs/gitlab.com/v3/swagger.json
# Auth: --token flag or $env.GITLAB_TOKEN

const BASE_URL = "https://gitlab.com/api"
const DEFAULT_AUTH = "private_header"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GITLAB_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "private_header" => { {headers: {PRIVATE_HEADER: $token_val}, query: ""} }
    "query-private_token" => { {headers: {}, query: $"private_token=($token_val)"} }
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

def base-url-completer [] { ["https://gitlab.com/api"] }
def auth-scheme-completer [] { ["private_header" "query-private_token"] }

# Completers for enum parameters
def default-branch-protection-completer [] { ["0" "1" "2"] }
def default-project-visibility-completer [] { ["0" "10" "20"] }
def default-snippet-visibility-completer [] { ["0" "10" "20"] }
def default-group-visibility-completer [] { ["0" "10" "20"] }
def import-sources-completer [] { ["bitbucket" "fogbugz" "git" "github" "gitlab" "gitlab_project" "google_code"] }
def enabled-git-access-protocol-completer [] { ["http" "nil" "ssh"] }
def order-by-completer [] { ["name" "path"] }
def sort-completer [] { ["asc" "desc"] }
def state-completer [] { ["all" "closed" "opened"] }
def order-by-completer-1 [] { ["created_at" "updated_at"] }
def visibility-completer [] { ["internal" "private" "public"] }
def order-by-completer-2 [] { ["created_at" "id" "last_activity_at" "name" "path" "updated_at"] }
def visibility-level-completer [] { ["0" "10" "20"] }
def scope-completer [] { ["canceled" "failed" "pending" "running" "success"] }
def state-event-completer [] { ["close" "reopen"] }
def state-event-completer-1 [] { ["close" "merge" "reopen"] }
def state-completer-1 [] { ["all" "closed" "merged" "opened"] }
def state-completer-2 [] { ["active" "all" "closed"] }
def state-event-completer-2 [] { ["activate" "close"] }
def scope-completer-1 [] { ["branches" "running" "tags"] }
def line-type-completer [] { ["new" "old"] }
def encoding-completer [] { ["base64"] }
def scope-completer-2 [] { ["active" "online" "paused" "shared" "specific"] }
def group-access-completer [] { ["10" "20" "30" "40"] }
def state-completer-3 [] { ["canceled" "failed" "pending" "running" "success"] }
def scope-completer-3 [] { ["active" "online" "paused"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "application-settings get" } } | get name | first)
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

# Get the current application settings
#
# GET /v3/application/settings
# operationId: getV3ApplicationSettings
export def "application-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<after_sign_out_path: string, after_sign_up_text: string, container_registry_token_expire_delay: string, created_at: string, default_branch_protection: string, default_group_visibility: string, default_project_visibility: string, default_projects_limit: string, default_snippet_visibility: string, domain_blacklist: string, domain_blacklist_enabled: string, domain_whitelist: string, gravatar_enabled: string, home_page_url: string, id: string, koding_enabled: string, koding_url: string, max_attachment_size: string, plantuml_enabled: string, plantuml_url: string, repository_storage: string, repository_storages: string, restricted_visibility_levels: string, session_expire_delay: string, sign_in_text: string, signin_enabled: string, signup_enabled: string, updated_at: string, user_oauth_applications: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/application/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify application settings
#
# PUT /v3/application/settings
# operationId: putV3ApplicationSettings
export def "application-settings put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-branch-protection: int@default-branch-protection-completer # Determine if developers can push to master
  --default-project-visibility: int@default-project-visibility-completer # The default project visibility
  --default-snippet-visibility: int@default-snippet-visibility-completer # The default snippet visibility
  --default-group-visibility: int@default-group-visibility-completer # The default group visibility
  --restricted-visibility-levels: list # Selected levels cannot be used by non-admin users for projects or snippets. If the public level is restricted, user profiles are only visible to logged in users.
  --import-sources: list@import-sources-completer # Enabled sources for code import during project creation. OmniAuth must be configured for GitHub, Bitbucket, and GitLab.com
  --disabled-oauth-sign-in-sources: list # Disable certain OAuth sign-in sources
  --enabled-git-access-protocol: string@enabled-git-access-protocol-completer # Allow only the selected protocols to be used for Git access.
  --gravatar-enabled: oneof<nothing, bool> # Flag indicating if the Gravatar service is enabled
  --default-projects-limit: int # The maximum number of personal projects
  --max-attachment-size: int # Maximum attachment size in MB
  --session-expire-delay: int # Session duration in minutes. GitLab restart is required to apply changes.
  --user-oauth-applications: oneof<nothing, bool> # Allow users to register any application to use GitLab as an OAuth provider
  --user-default-external: oneof<nothing, bool> # Newly registered users will by default be external
  --signup-enabled: oneof<nothing, bool> # Flag indicating if sign up is enabled
  --send-user-confirmation-email: oneof<nothing, bool> # Send confirmation email on sign-up
  --domain-whitelist: string # ONLY users with e-mail addresses that match these domain(s) will be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com
  --domain-blacklist-enabled: oneof<nothing, bool> # Enable domain blacklist for sign ups
  domain_blacklist: string # Users with e-mail addresses that match these domain(s) will NOT be able to sign-up. Wildcards allowed. Use separate lines for multiple entries. Ex: domain.com, *.domain.com
  --after-sign-up-text: string # Text shown after sign up
  --signin-enabled: oneof<nothing, bool> # Flag indicating if sign in is enabled
  --require-two-factor-authentication: oneof<nothing, bool> # Require all users to setup Two-factor authentication
  two_factor_grace_period: int # Amount of time (in hours) that users are allowed to skip forced configuration of two-factor authentication
  --home-page-url: string # We will redirect non-logged in users to this page
  --after-sign-out-path: string # We will redirect users to this page after they sign out
  --sign-in-text: string # The sign in text of the GitLab application
  --help-page-text: string # Custom text displayed on the help page
  --shared-runners-enabled: oneof<nothing, bool> # Enable shared runners for new projects
  shared_runners_text: string # Shared runners text 
  --max-artifacts-size: int # Set the maximum file size each build's artifacts can have
  --container-registry-token-expire-delay: int # Authorization token duration (minutes)
  --metrics-enabled: oneof<nothing, bool> # Enable the InfluxDB metrics
  metrics_host: string # The InfluxDB host
  metrics_port: int # The UDP port to use for connecting to InfluxDB
  metrics_pool_size: int # The amount of InfluxDB connections to open
  metrics_timeout: int # The amount of seconds after which an InfluxDB connection will time out
  metrics_method_call_threshold: int # A method call is only tracked when it takes longer to complete than the given amount of milliseconds.
  metrics_sample_interval: int # The sampling interval in seconds
  metrics_packet_size: int # The amount of points to store in a single UDP packet
  --sidekiq-throttling-enabled: oneof<nothing, bool> # Enable Sidekiq Job Throttling
  sidekiq_throttling_queus: list # Choose which queues you wish to throttle
  sidekiq_throttling_factor: float # The factor by which the queues should be throttled. A value between 0.0 and 1.0, exclusive.
  --recaptcha-enabled: oneof<nothing, bool> # Helps prevent bots from creating accounts
  recaptcha_site_key: string # Generate site key at http://www.google.com/recaptcha
  recaptcha_private_key: string # Generate private key at http://www.google.com/recaptcha
  --akismet-enabled: oneof<nothing, bool> # Helps prevent bots from creating issues
  akismet_api_key: string # Generate API key at http://www.akismet.com
  --admin-notification-email: string # Abuse reports will be sent to this address if it is set. Abuse reports are always available in the admin area.
  --sentry-enabled: oneof<nothing, bool> # Sentry is an error reporting and logging tool which is currently not shipped with GitLab, get it here: https://getsentry.com
  sentry_dsn: string # Sentry Data Source Name
  --repository-storage: string # Storage paths for new projects
  --repository-checks-enabled: oneof<nothing, bool> # GitLab will periodically run 'git fsck' in all project and wiki repositories to look for silent disk corruption issues.
  --koding-enabled: oneof<nothing, bool> # Enable Koding
  koding_url: string # The Koding team URL
  --plantuml-enabled: oneof<nothing, bool> # Enable PlantUML
  plantuml_url: string # The PlantUML server URL
  --version-check-enabled: oneof<nothing, bool> # Let GitLab inform you when an update is available.
  --email-author-in-body: oneof<nothing, bool> # Some email servers do not support overriding the email sender name. Enable this option to include the name of the author of the issue, merge request or comment in the email body instead.
  --html-emails-enabled: oneof<nothing, bool> # By default GitLab sends emails in HTML and plain text formats so mail clients can choose what format to use. Disable this option if you only want to send emails in plain text format.
  --housekeeping-enabled: oneof<nothing, bool> # Enable automatic repository housekeeping (git repack, git gc)
  --housekeeping-bitmaps-enabled: oneof<nothing, bool> # Creating pack file bitmaps makes housekeeping take a little longer but bitmaps should accelerate 'git clone' performance.
  housekeeping_incremental_repack_period: int # Number of Git pushes after which an incremental 'git repack' is run.
  housekeeping_full_repack_period: int # Number of Git pushes after which a full 'git repack' is run.
  housekeeping_gc_period: int # Number of Git pushes after which 'git gc' is run.
]: any -> record<after_sign_out_path: string, after_sign_up_text: string, container_registry_token_expire_delay: string, created_at: string, default_branch_protection: string, default_group_visibility: string, default_project_visibility: string, default_projects_limit: string, default_snippet_visibility: string, domain_blacklist: string, domain_blacklist_enabled: string, domain_whitelist: string, gravatar_enabled: string, home_page_url: string, id: string, koding_enabled: string, koding_url: string, max_attachment_size: string, plantuml_enabled: string, plantuml_url: string, repository_storage: string, repository_storages: string, restricted_visibility_levels: string, session_expire_delay: string, sign_in_text: string, signin_enabled: string, signup_enabled: string, updated_at: string, user_oauth_applications: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/application/settings")
  let body = {default_branch_protection: $default_branch_protection, default_project_visibility: $default_project_visibility, default_snippet_visibility: $default_snippet_visibility, default_group_visibility: $default_group_visibility, restricted_visibility_levels: $restricted_visibility_levels, import_sources: $import_sources, disabled_oauth_sign_in_sources: $disabled_oauth_sign_in_sources, enabled_git_access_protocol: $enabled_git_access_protocol, gravatar_enabled: $gravatar_enabled, default_projects_limit: $default_projects_limit, max_attachment_size: $max_attachment_size, session_expire_delay: $session_expire_delay, user_oauth_applications: $user_oauth_applications, user_default_external: $user_default_external, signup_enabled: $signup_enabled, send_user_confirmation_email: $send_user_confirmation_email, domain_whitelist: $domain_whitelist, domain_blacklist_enabled: $domain_blacklist_enabled, domain_blacklist: $domain_blacklist, after_sign_up_text: $after_sign_up_text, signin_enabled: $signin_enabled, require_two_factor_authentication: $require_two_factor_authentication, two_factor_grace_period: $two_factor_grace_period, home_page_url: $home_page_url, after_sign_out_path: $after_sign_out_path, sign_in_text: $sign_in_text, help_page_text: $help_page_text, shared_runners_enabled: $shared_runners_enabled, shared_runners_text: $shared_runners_text, max_artifacts_size: $max_artifacts_size, container_registry_token_expire_delay: $container_registry_token_expire_delay, metrics_enabled: $metrics_enabled, metrics_host: $metrics_host, metrics_port: $metrics_port, metrics_pool_size: $metrics_pool_size, metrics_timeout: $metrics_timeout, metrics_method_call_threshold: $metrics_method_call_threshold, metrics_sample_interval: $metrics_sample_interval, metrics_packet_size: $metrics_packet_size, sidekiq_throttling_enabled: $sidekiq_throttling_enabled, sidekiq_throttling_queus: $sidekiq_throttling_queus, sidekiq_throttling_factor: $sidekiq_throttling_factor, recaptcha_enabled: $recaptcha_enabled, recaptcha_site_key: $recaptcha_site_key, recaptcha_private_key: $recaptcha_private_key, akismet_enabled: $akismet_enabled, akismet_api_key: $akismet_api_key, admin_notification_email: $admin_notification_email, sentry_enabled: $sentry_enabled, sentry_dsn: $sentry_dsn, repository_storage: $repository_storage, repository_checks_enabled: $repository_checks_enabled, koding_enabled: $koding_enabled, koding_url: $koding_url, plantuml_enabled: $plantuml_enabled, plantuml_url: $plantuml_url, version_check_enabled: $version_check_enabled, email_author_in_body: $email_author_in_body, html_emails_enabled: $html_emails_enabled, housekeeping_enabled: $housekeeping_enabled, housekeeping_bitmaps_enabled: $housekeeping_bitmaps_enabled, housekeeping_incremental_repack_period: $housekeeping_incremental_repack_period, housekeeping_full_repack_period: $housekeeping_full_repack_period, housekeeping_gc_period: $housekeeping_gc_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Validation of .gitlab-ci.yml content
#
# POST /v3/ci/lint
# operationId: postV3CiLint
export def "ci-lint post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  content: string # Content of .gitlab-ci.yml
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/ci/lint")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v3/deploy_keys
#
# operationId: getV3DeployKeys
export def "deploy-keys get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/deploy_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the available template
#
# GET /v3/dockerfiles
# operationId: getV3Dockerfiles
export def "dockerfiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/dockerfiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/dockerfiles/{name}
# operationId: getV3DockerfilesName
export def "dockerfiles get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/dockerfiles/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the available template
#
# GET /v3/gitignores
# operationId: getV3Gitignores
export def "gitignores list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/gitignores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/gitignores/{name}
# operationId: getV3GitignoresName
export def "gitignores get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/gitignores/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the available template
#
# GET /v3/gitlab_ci_ymls
# operationId: getV3GitlabCiYmls
export def "gitlab-ci-ymls list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/gitlab_ci_ymls")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/gitlab_ci_ymls/{name}
# operationId: getV3GitlabCiYmlsName
export def "gitlab-ci-ymls get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/gitlab_ci_ymls/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a groups list
#
# GET /v3/groups
# operationId: getV3Groups
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --statistics: oneof<nothing, bool> # Include project statistics
  --all-available: oneof<nothing, bool> # Show all group that you have access to
  --search: string # Search for a specific group
  --order-by: string@order-by-completer # Order by name or path (default: name)
  --qp-sort: string@sort-completer # Sort by asc (ascending) or desc (descending) (default: asc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --skip-groups: list # Array of group ids to exclude from list
]: any -> record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statistics" $statistics "scalar") (serialize-qp "all_available" $all_available "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/groups" $qp)
  let body = {skip_groups: $skip_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a group. Available only for users who can create groups.
#
# POST /v3/groups
# operationId: postV3Groups
export def "groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the group
  path: string # The path of the group
  --description: string # The description of the group
  --visibility-level: int # The visibility level of the group
  --lfs-enabled: oneof<nothing, bool> # Enable/disable LFS for the projects in this group
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
]: any -> record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/groups")
  let body = {name: $name, path: $path, description: $description, visibility_level: $visibility_level, lfs_enabled: $lfs_enabled, request_access_enabled: $request_access_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get list of owned groups for authenticated user
#
# GET /v3/groups/owned
# operationId: getV3GroupsOwned
export def "groups-owned get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --statistics: oneof<nothing, bool> # Include project statistics
]: nothing -> record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/groups/owned" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a group.
#
# DELETE /v3/groups/{id}
# operationId: deleteV3GroupsId
export def "groups delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single group, with containing projects.
#
# GET /v3/groups/{id}
# operationId: getV3GroupsId
export def "groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, request_access_enabled: string, shared_projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, statistics: string, visibility_level: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a group. Available only for users who can administrate groups.
#
# PUT /v3/groups/{id}
# operationId: putV3GroupsId
export def "groups put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the group
  --path: string # The path of the group
  --description: string # The description of the group
  --visibility-level: int # The visibility level of the group
  --lfs-enabled: oneof<nothing, bool> # Enable/disable LFS for the projects in this group
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
]: any -> record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, request_access_enabled: string, statistics: string, visibility_level: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)")
  let body = {name: $name, path: $path, description: $description, visibility_level: $visibility_level, lfs_enabled: $lfs_enabled, request_access_enabled: $request_access_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets a list of access requests for a group.
#
# GET /v3/groups/{id}/access_requests
# operationId: getV3GroupsIdAccessRequests
export def "groups-access-requests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/groups/($id)/access_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Requests access for the authenticated user to a group.
#
# POST /v3/groups/{id}/access_requests
# operationId: postV3GroupsIdAccessRequests
export def "groups-access-requests post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/access_requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Denies an access request for the given user.
#
# DELETE /v3/groups/{id}/access_requests/{user_id}
# operationId: deleteV3GroupsIdAccessRequestsUserId
export def "groups-access-requests delete" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/access_requests/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approves an access request for the given user.
#
# PUT /v3/groups/{id}/access_requests/{user_id}/approve
# operationId: putV3GroupsIdAccessRequestsUserIdApprove
export def "groups-access-requests-approve put" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-level: int # A valid access level (defaults: `30`, developer access level)
]: any -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/access_requests/($user_id)/approve")
  let body = {access_level: $access_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of group issues
#
# GET /v3/groups/{id}/issues
# operationId: getV3GroupsIdIssues
export def "groups-issues get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Return opened, closed, or all issues (default: opened)
  --labels: string # Comma-separated list of label names
  --milestone: string # Return issues for a specific milestone
  --order-by: string@order-by-completer-1 # Return issues ordered by `created_at` or `updated_at` fields. (default: created_at)
  --qp-sort: string@sort-completer # Return issues sorted in `asc` or `desc` order. (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "milestone" $milestone "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/groups/($id)/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of group or project members viewable by the authenticated user.
#
# GET /v3/groups/{id}/members
# operationId: getV3GroupsIdMembers
export def "groups-members list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query string to search for members
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/groups/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a member to a group or project.
#
# POST /v3/groups/{id}/members
# operationId: postV3GroupsIdMembers
export def "groups-members post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: int # The user ID of the new member
  access_level: int # A valid access level (defaults: `30`, developer access level)
  --expires-at: string # Date string in the format YEAR-MONTH-DAY
]: any -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/members")
  let body = {user_id: $user_id, access_level: $access_level, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes a user from a group or project.
#
# DELETE /v3/groups/{id}/members/{user_id}
# operationId: deleteV3GroupsIdMembersUserId
export def "groups-members delete" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a member of a group or project.
#
# GET /v3/groups/{id}/members/{user_id}
# operationId: getV3GroupsIdMembersUserId
export def "groups-members get" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a member of a group or project.
#
# PUT /v3/groups/{id}/members/{user_id}
# operationId: putV3GroupsIdMembersUserId
export def "groups-members put" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_level: int # A valid access level
  --expires-at: string # Date string in the format YEAR-MONTH-DAY
]: any -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/members/($user_id)")
  let body = {access_level: $access_level, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get group level notification level settings, defaults to Global
#
# GET /v3/groups/{id}/notification_settings
# operationId: getV3GroupsIdNotificationSettings
export def "groups-notification-settings get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<events: string, level: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/notification_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update group level notification level settings, defaults to Global
#
# PUT /v3/groups/{id}/notification_settings
# operationId: putV3GroupsIdNotificationSettings
export def "groups-notification-settings put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string # The group notification level
  --new-note: oneof<nothing, bool> # Enable/disable this notification
  --new-issue: oneof<nothing, bool> # Enable/disable this notification
  --reopen-issue: oneof<nothing, bool> # Enable/disable this notification
  --close-issue: oneof<nothing, bool> # Enable/disable this notification
  --reassign-issue: oneof<nothing, bool> # Enable/disable this notification
  --new-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reopen-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --close-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reassign-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --merge-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --failed-pipeline: oneof<nothing, bool> # Enable/disable this notification
  --success-pipeline: oneof<nothing, bool> # Enable/disable this notification
]: any -> record<events: string, level: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/notification_settings")
  let body = {level: $level, new_note: $new_note, new_issue: $new_issue, reopen_issue: $reopen_issue, close_issue: $close_issue, reassign_issue: $reassign_issue, new_merge_request: $new_merge_request, reopen_merge_request: $reopen_merge_request, close_merge_request: $close_merge_request, reassign_merge_request: $reassign_merge_request, merge_merge_request: $merge_merge_request, failed_pipeline: $failed_pipeline, success_pipeline: $success_pipeline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of projects in this group.
#
# GET /v3/groups/{id}/projects
# operationId: getV3GroupsIdProjects
export def "groups-projects get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --qp-sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "archived" $archived "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "simple" $simple "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/groups/($id)/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transfer a project to the group namespace. Available only for admin.
#
# POST /v3/groups/{id}/projects/{project_id}
# operationId: postV3GroupsIdProjectsProjectId
export def "groups-projects post" [
  id: string
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, description: string, id: string, lfs_enabled: string, name: string, path: string, projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, request_access_enabled: string, shared_projects: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, statistics: string, visibility_level: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/groups/($id)/projects/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of system hooks
#
# GET /v3/hooks
# operationId: getV3Hooks
export def "hooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/hooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new system hook
#
# POST /v3/hooks
# operationId: postV3Hooks
export def "hooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The URL to send the request to
  --body-token: string # The token used to validate payloads
  --push-events: oneof<nothing, bool> # Trigger hook on push events
  --tag-push-events: oneof<nothing, bool> # Trigger hook on tag push events
  --enable-ssl-verification: oneof<nothing, bool> # Do SSL verification when triggering the hook
]: any -> record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/hooks")
  let body = {url: $body_url, token: $body_token, push_events: $push_events, tag_push_events: $tag_push_events, enable_ssl_verification: $enable_ssl_verification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a hook
#
# DELETE /v3/hooks/{id}
# operationId: deleteV3HooksId
export def "hooks delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test a hook
#
# GET /v3/hooks/{id}
# operationId: getV3HooksId
export def "hooks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, enable_ssl_verification: string, id: string, push_events: string, tag_push_events: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/hooks/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v3/internal/allowed
#
# operationId: postV3InternalAllowed
export def "internal-allowed post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/internal/allowed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v3/internal/broadcast_message
#
# operationId: getV3InternalBroadcastMessage
export def "internal-broadcast-message get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/internal/broadcast_message")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v3/internal/check
#
# operationId: getV3InternalCheck
export def "internal-check get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/internal/check")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v3/internal/discover
#
# operationId: getV3InternalDiscover
export def "internal-discover get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/internal/discover")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v3/internal/lfs_authenticate
#
# operationId: postV3InternalLfsAuthenticate
export def "internal-lfs-authenticate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/internal/lfs_authenticate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v3/internal/merge_request_urls
#
# operationId: getV3InternalMergeRequestUrls
export def "internal-merge-request-urls get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/internal/merge_request_urls")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v3/internal/two_factor_recovery_codes
#
# operationId: postV3InternalTwoFactorRecoveryCodes
export def "internal-two-factor-recovery-codes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/internal/two_factor_recovery_codes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get currently authenticated user's issues
#
# GET /v3/issues
# operationId: getV3Issues
export def "issues get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Return opened, closed, or all issues (default: all)
  --labels: string # Comma-separated list of label names
  --milestone: string # Return issues for a specific milestone
  --order-by: string@order-by-completer-1 # Return issues ordered by `created_at` or `updated_at` fields. (default: created_at)
  --qp-sort: string@sort-completer # Return issues sorted in `asc` or `desc` order. (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "milestone" $milestone "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single ssh key by id. Only available to admin users
#
# GET /v3/keys/{id}
# operationId: getV3KeysId
export def "keys get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string, user: record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/keys/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the available license template
#
# GET /v3/licenses
# operationId: getV3Licenses
export def "licenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --popular: oneof<nothing, bool> # If passed, returns only popular licenses
]: nothing -> record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "popular" $popular "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/licenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the text for a specific license
#
# GET /v3/licenses/{name}
# operationId: getV3LicensesName
export def "licenses get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/licenses/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a namespaces list
#
# GET /v3/namespaces
# operationId: getV3Namespaces
export def "namespaces get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search query for namespaces
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<id: string, kind: string, name: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/namespaces" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get global notification level settings and email, defaults to Participate
#
# GET /v3/notification_settings
# operationId: getV3NotificationSettings
export def "notification-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<events: string, level: string, notification_email: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/notification_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update global notification level settings and email, defaults to Participate
#
# PUT /v3/notification_settings
# operationId: putV3NotificationSettings
export def "notification-settings put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string # The global notification level
  --notification-email: string # The email address to send notifications
  --new-note: oneof<nothing, bool> # Enable/disable this notification
  --new-issue: oneof<nothing, bool> # Enable/disable this notification
  --reopen-issue: oneof<nothing, bool> # Enable/disable this notification
  --close-issue: oneof<nothing, bool> # Enable/disable this notification
  --reassign-issue: oneof<nothing, bool> # Enable/disable this notification
  --new-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reopen-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --close-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reassign-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --merge-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --failed-pipeline: oneof<nothing, bool> # Enable/disable this notification
  --success-pipeline: oneof<nothing, bool> # Enable/disable this notification
]: any -> record<events: string, level: string, notification_email: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/notification_settings")
  let body = {level: $level, notification_email: $notification_email, new_note: $new_note, new_issue: $new_issue, reopen_issue: $reopen_issue, close_issue: $close_issue, reassign_issue: $reassign_issue, new_merge_request: $new_merge_request, reopen_merge_request: $reopen_merge_request, close_merge_request: $close_merge_request, reassign_merge_request: $reassign_merge_request, merge_merge_request: $merge_merge_request, failed_pipeline: $failed_pipeline, success_pipeline: $success_pipeline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a projects list for authenticated user
#
# GET /v3/projects
# operationId: getV3Projects
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --qp-sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
]: nothing -> record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "simple" $simple "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new project
#
# POST /v3/projects
# operationId: postV3Projects
export def "projects post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project
  --path: string # The path of the repository
  --description: string # The description of the project
  --issues-enabled: oneof<nothing, bool> # Flag indication if the issue tracker is enabled
  --merge-requests-enabled: oneof<nothing, bool> # Flag indication if merge requests are enabled
  --wiki-enabled: oneof<nothing, bool> # Flag indication if the wiki is enabled
  --builds-enabled: oneof<nothing, bool> # Flag indication if builds are enabled
  --snippets-enabled: oneof<nothing, bool> # Flag indication if snippets are enabled
  --shared-runners-enabled: oneof<nothing, bool> # Flag indication if shared runners are enabled for that project
  --container-registry-enabled: oneof<nothing, bool> # Flag indication if the container registry is enabled for that project
  --lfs-enabled: oneof<nothing, bool> # Flag indication if Git LFS is enabled for that project
  --public: oneof<nothing, bool> # Create a public project. The same as visibility_level = 20.
  --visibility-level: int@visibility-level-completer # Create a public project. The same as visibility_level = 20.
  --public-builds: oneof<nothing, bool> # Perform public builds
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
  --only-allow-merge-if-build-succeeds: oneof<nothing, bool> # Only allow to merge if builds succeed
  --only-allow-merge-if-all-discussions-are-resolved: oneof<nothing, bool> # Only allow to merge if all discussions are resolved
  --namespace-id: int # Namespace ID for the new project. Default to the user namespace.
  --import-url: string # URL from which the project is imported
]: any -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/projects")
  let body = {name: $name, path: $path, description: $description, issues_enabled: $issues_enabled, merge_requests_enabled: $merge_requests_enabled, wiki_enabled: $wiki_enabled, builds_enabled: $builds_enabled, snippets_enabled: $snippets_enabled, shared_runners_enabled: $shared_runners_enabled, container_registry_enabled: $container_registry_enabled, lfs_enabled: $lfs_enabled, public: $public, visibility_level: $visibility_level, public_builds: $public_builds, request_access_enabled: $request_access_enabled, only_allow_merge_if_build_succeeds: $only_allow_merge_if_build_succeeds, only_allow_merge_if_all_discussions_are_resolved: $only_allow_merge_if_all_discussions_are_resolved, namespace_id: $namespace_id, import_url: $import_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all projects for admin user
#
# GET /v3/projects/all
# operationId: getV3ProjectsAll
export def "projects-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --qp-sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
  --statistics: oneof<nothing, bool> # Include project statistics
]: nothing -> record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "simple" $simple "scalar") (serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/projects/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fork new project for the current user or provided namespace.
#
# POST /v3/projects/fork/{id}
# operationId: postV3ProjectsForkId
export def "projects-fork post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --namespace: string # The ID or name of the namespace that the project will be forked into
]: any -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/fork/($id)")
  let body = {namespace: $namespace} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get an owned projects list for authenticated user
#
# GET /v3/projects/owned
# operationId: getV3ProjectsOwned
export def "projects-owned get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --qp-sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
  --statistics: oneof<nothing, bool> # Include project statistics
]: nothing -> record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "simple" $simple "scalar") (serialize-qp "statistics" $statistics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/projects/owned" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for projects the current user has access to
#
# GET /v3/projects/search/{query}
# operationId: getV3ProjectsSearchQuery
export def "projects-search get" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --qp-sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/search/($query)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets starred project for the authenticated user
#
# GET /v3/projects/starred
# operationId: getV3ProjectsStarred
export def "projects-starred get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --qp-sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
]: nothing -> record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "simple" $simple "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/projects/starred" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new project for a specified user. Only available to admin users.
#
# POST /v3/projects/user/{user_id}
# operationId: postV3ProjectsUserUserId
export def "projects-user post" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the project
  --default-branch: string # The default branch of the project
  --description: string # The description of the project
  --issues-enabled: oneof<nothing, bool> # Flag indication if the issue tracker is enabled
  --merge-requests-enabled: oneof<nothing, bool> # Flag indication if merge requests are enabled
  --wiki-enabled: oneof<nothing, bool> # Flag indication if the wiki is enabled
  --builds-enabled: oneof<nothing, bool> # Flag indication if builds are enabled
  --snippets-enabled: oneof<nothing, bool> # Flag indication if snippets are enabled
  --shared-runners-enabled: oneof<nothing, bool> # Flag indication if shared runners are enabled for that project
  --container-registry-enabled: oneof<nothing, bool> # Flag indication if the container registry is enabled for that project
  --lfs-enabled: oneof<nothing, bool> # Flag indication if Git LFS is enabled for that project
  --public: oneof<nothing, bool> # Create a public project. The same as visibility_level = 20.
  --visibility-level: int@visibility-level-completer # Create a public project. The same as visibility_level = 20.
  --public-builds: oneof<nothing, bool> # Perform public builds
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
  --only-allow-merge-if-build-succeeds: oneof<nothing, bool> # Only allow to merge if builds succeed
  --only-allow-merge-if-all-discussions-are-resolved: oneof<nothing, bool> # Only allow to merge if all discussions are resolved
  --namespace-id: int # Namespace ID for the new project. Default to the user namespace.
  --import-url: string # URL from which the project is imported
]: any -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/user/($user_id)")
  let body = {name: $name, default_branch: $default_branch, description: $description, issues_enabled: $issues_enabled, merge_requests_enabled: $merge_requests_enabled, wiki_enabled: $wiki_enabled, builds_enabled: $builds_enabled, snippets_enabled: $snippets_enabled, shared_runners_enabled: $shared_runners_enabled, container_registry_enabled: $container_registry_enabled, lfs_enabled: $lfs_enabled, public: $public, visibility_level: $visibility_level, public_builds: $public_builds, request_access_enabled: $request_access_enabled, only_allow_merge_if_build_succeeds: $only_allow_merge_if_build_succeeds, only_allow_merge_if_all_discussions_are_resolved: $only_allow_merge_if_all_discussions_are_resolved, namespace_id: $namespace_id, import_url: $import_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of visible projects for authenticated user
#
# GET /v3/projects/visible
# operationId: getV3ProjectsVisible
export def "projects-visible get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string@order-by-completer-2 # Return projects ordered by field (default: created_at)
  --qp-sort: string@sort-completer # Return projects sorted in ascending and descending order (default: desc)
  --archived: oneof<nothing, bool> # Limit by archived status
  --visibility: string@visibility-completer # Limit by visibility
  --search: string # Return list of authorized projects matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --simple: oneof<nothing, bool> # Return only the ID, URL, name, and path of each project
]: nothing -> record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "visibility" $visibility "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "simple" $simple "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/projects/visible" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a project
#
# DELETE /v3/projects/{id}
# operationId: deleteV3ProjectsId
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single project
#
# GET /v3/projects/{id}
# operationId: getV3ProjectsId
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
]: nothing -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, permissions: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing project
#
# PUT /v3/projects/{id}
# operationId: putV3ProjectsId
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
  --name: string # The name of the project
  --default-branch: string # The default branch of the project
  --path: string # The path of the repository
  --description: string # The description of the project
  --issues-enabled: oneof<nothing, bool> # Flag indication if the issue tracker is enabled
  --merge-requests-enabled: oneof<nothing, bool> # Flag indication if merge requests are enabled
  --wiki-enabled: oneof<nothing, bool> # Flag indication if the wiki is enabled
  --builds-enabled: oneof<nothing, bool> # Flag indication if builds are enabled
  --snippets-enabled: oneof<nothing, bool> # Flag indication if snippets are enabled
  --shared-runners-enabled: oneof<nothing, bool> # Flag indication if shared runners are enabled for that project
  --container-registry-enabled: oneof<nothing, bool> # Flag indication if the container registry is enabled for that project
  --lfs-enabled: oneof<nothing, bool> # Flag indication if Git LFS is enabled for that project
  --public: oneof<nothing, bool> # Create a public project. The same as visibility_level = 20.
  --visibility-level: int@visibility-level-completer # Create a public project. The same as visibility_level = 20.
  --public-builds: oneof<nothing, bool> # Perform public builds
  --request-access-enabled: oneof<nothing, bool> # Allow users to request member access
  --only-allow-merge-if-build-succeeds: oneof<nothing, bool> # Only allow to merge if builds succeed
  --only-allow-merge-if-all-discussions-are-resolved: oneof<nothing, bool> # Only allow to merge if all discussions are resolved
]: any -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)")
  let body = {name: $name, default_branch: $default_branch, path: $path, description: $description, issues_enabled: $issues_enabled, merge_requests_enabled: $merge_requests_enabled, wiki_enabled: $wiki_enabled, builds_enabled: $builds_enabled, snippets_enabled: $snippets_enabled, shared_runners_enabled: $shared_runners_enabled, container_registry_enabled: $container_registry_enabled, lfs_enabled: $lfs_enabled, public: $public, visibility_level: $visibility_level, public_builds: $public_builds, request_access_enabled: $request_access_enabled, only_allow_merge_if_build_succeeds: $only_allow_merge_if_build_succeeds, only_allow_merge_if_all_discussions_are_resolved: $only_allow_merge_if_all_discussions_are_resolved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Trigger a GitLab project build
#
# POST /v3/projects/{id}/(ref/{ref}/)trigger/builds
# operationId: postV3ProjectsId(refRef)triggerBuilds
export def "projects-ref-trigger-builds post" [
  id: string
  ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The unique token of trigger
]: any -> record<id: string, variables: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/(ref/($ref)/)trigger/builds")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Gets a list of access requests for a project.
#
# GET /v3/projects/{id}/access_requests
# operationId: getV3ProjectsIdAccessRequests
export def "projects-access-requests get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/access_requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Requests access for the authenticated user to a project.
#
# POST /v3/projects/{id}/access_requests
# operationId: postV3ProjectsIdAccessRequests
export def "projects-access-requests post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, id: string, name: string, requested_at: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/access_requests")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Denies an access request for the given user.
#
# DELETE /v3/projects/{id}/access_requests/{user_id}
# operationId: deleteV3ProjectsIdAccessRequestsUserId
export def "projects-access-requests delete" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/access_requests/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approves an access request for the given user.
#
# PUT /v3/projects/{id}/access_requests/{user_id}/approve
# operationId: putV3ProjectsIdAccessRequestsUserIdApprove
export def "projects-access-requests-approve put" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --access-level: int # A valid access level (defaults: `30`, developer access level)
]: any -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/access_requests/($user_id)/approve")
  let body = {access_level: $access_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Archive a project
#
# POST /v3/projects/{id}/archive
# operationId: postV3ProjectsIdArchive
export def "projects-archive post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/archive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all project boards
#
# GET /v3/projects/{id}/boards
# operationId: getV3ProjectsIdBoards
export def "projects-boards get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, lists: record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/boards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the lists of a project board
#
# GET /v3/projects/{id}/boards/{board_id}/lists
# operationId: getV3ProjectsIdBoardsBoardIdLists
export def "projects-boards-lists list" [
  id: string
  board_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/boards/($board_id)/lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new board list
#
# POST /v3/projects/{id}/boards/{board_id}/lists
# operationId: postV3ProjectsIdBoardsBoardIdLists
export def "projects-boards-lists post" [
  id: string
  board_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  label_id: int # The ID of an existing label
]: any -> record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/boards/($board_id)/lists")
  let body = {label_id: $label_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a board list
#
# DELETE /v3/projects/{id}/boards/{board_id}/lists/{list_id}
# operationId: deleteV3ProjectsIdBoardsBoardIdListsListId
export def "projects-boards-lists delete" [
  id: string
  board_id: int
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/boards/($board_id)/lists/($list_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of a project board
#
# GET /v3/projects/{id}/boards/{board_id}/lists/{list_id}
# operationId: getV3ProjectsIdBoardsBoardIdListsListId
export def "projects-boards-lists get" [
  id: string
  board_id: int
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/boards/($board_id)/lists/($list_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Moves a board list to a new position
#
# PUT /v3/projects/{id}/boards/{board_id}/lists/{list_id}
# operationId: putV3ProjectsIdBoardsBoardIdListsListId
export def "projects-boards-lists put" [
  id: string
  board_id: int
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  position: int # The position of the list
]: any -> record<id: string, label: record<color: string, description: string, id: string, name: string>, position: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/boards/($board_id)/lists/($list_id)")
  let body = {position: $position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a project builds
#
# GET /v3/projects/{id}/builds
# operationId: getV3ProjectsIdBuilds
export def "projects-builds list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # The scope of builds to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the artifacts file from build
#
# GET /v3/projects/{id}/builds/artifacts/{ref_name}/download
# operationId: getV3ProjectsIdBuildsArtifactsRefNameDownload
export def "projects-builds-artifacts-download get" [
  id: string
  ref_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --job: string # The name for the build
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "job" $job "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/builds/artifacts/($ref_name)/download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific build of a project
#
# GET /v3/projects/{id}/builds/{build_id}
# operationId: getV3ProjectsIdBuildsBuildId
export def "projects-builds get" [
  id: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/builds/($build_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download the artifacts file from build
#
# GET /v3/projects/{id}/builds/{build_id}/artifacts
# operationId: getV3ProjectsIdBuildsBuildIdArtifacts
export def "projects-builds-artifacts get" [
  id: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/builds/($build_id)/artifacts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Keep the artifacts to prevent them from being deleted
#
# POST /v3/projects/{id}/builds/{build_id}/artifacts/keep
# operationId: postV3ProjectsIdBuildsBuildIdArtifactsKeep
export def "projects-builds-artifacts-keep post" [
  id: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/builds/($build_id)/artifacts/keep")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a specific build of a project
#
# POST /v3/projects/{id}/builds/{build_id}/cancel
# operationId: postV3ProjectsIdBuildsBuildIdCancel
export def "projects-builds-cancel post" [
  id: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/builds/($build_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Erase build (remove artifacts and build trace)
#
# POST /v3/projects/{id}/builds/{build_id}/erase
# operationId: postV3ProjectsIdBuildsBuildIdErase
export def "projects-builds-erase post" [
  id: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/builds/($build_id)/erase")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Trigger a manual build
#
# POST /v3/projects/{id}/builds/{build_id}/play
# operationId: postV3ProjectsIdBuildsBuildIdPlay
export def "projects-builds-play post" [
  id: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/builds/($build_id)/play")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry a specific build of a project
#
# POST /v3/projects/{id}/builds/{build_id}/retry
# operationId: postV3ProjectsIdBuildsBuildIdRetry
export def "projects-builds-retry post" [
  id: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/builds/($build_id)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a trace of a specific build of a project
#
# GET /v3/projects/{id}/builds/{build_id}/trace
# operationId: getV3ProjectsIdBuildsBuildIdTrace
export def "projects-builds-trace get" [
  id: string
  build_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/builds/($build_id)/trace")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific project's deploy keys
#
# GET /v3/projects/{id}/deploy_keys
# operationId: getV3ProjectsIdDeployKeys
export def "projects-deploy-keys list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/deploy_keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new deploy key to currently authenticated user
#
# POST /v3/projects/{id}/deploy_keys
# operationId: postV3ProjectsIdDeployKeys
export def "projects-deploy-keys post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The new deploy key
  title: string # The name of the deploy key
]: any -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/deploy_keys")
  let body = {key: $key, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete deploy key for a project
#
# DELETE /v3/projects/{id}/deploy_keys/{key_id}
# operationId: deleteV3ProjectsIdDeployKeysKeyId
export def "projects-deploy-keys delete" [
  id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/deploy_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single deploy key
#
# GET /v3/projects/{id}/deploy_keys/{key_id}
# operationId: getV3ProjectsIdDeployKeysKeyId
export def "projects-deploy-keys get" [
  id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/deploy_keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a deploy key for a project
#
# DELETE /v3/projects/{id}/deploy_keys/{key_id}/disable
# operationId: deleteV3ProjectsIdDeployKeysKeyIdDisable
export def "projects-deploy-keys-disable delete" [
  id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/deploy_keys/($key_id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a deploy key for a project
#
# POST /v3/projects/{id}/deploy_keys/{key_id}/enable
# operationId: postV3ProjectsIdDeployKeysKeyIdEnable
export def "projects-deploy-keys-enable post" [
  id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/deploy_keys/($key_id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all deployments of the project
#
# GET /v3/projects/{id}/deployments
# operationId: getV3ProjectsIdDeployments
export def "projects-deployments list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<created_at: string, deployable: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>, environment: record<external_url: string, id: string, name: string, slug: string>, id: string, iid: string, ref: string, sha: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/deployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a specific deployment
#
# GET /v3/projects/{id}/deployments/{deployment_id}
# operationId: getV3ProjectsIdDeploymentsDeploymentId
export def "projects-deployments get" [
  id: string
  deployment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, deployable: record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>>, environment: record<external_url: string, id: string, name: string, slug: string>, id: string, iid: string, ref: string, sha: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/deployments/($deployment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all environments of the project
#
# GET /v3/projects/{id}/environments
# operationId: getV3ProjectsIdEnvironments
export def "projects-environments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/environments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new environment
#
# POST /v3/projects/{id}/environments
# operationId: postV3ProjectsIdEnvironments
export def "projects-environments post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the environment to be created
  --external-url: string # URL on which this deployment is viewable
  --slug: string
]: any -> record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/environments")
  let body = {name: $name, external_url: $external_url, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deletes an existing environment
#
# DELETE /v3/projects/{id}/environments/{environment_id}
# operationId: deleteV3ProjectsIdEnvironmentsEnvironmentId
export def "projects-environments delete" [
  id: string
  environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/environments/($environment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing environment
#
# PUT /v3/projects/{id}/environments/{environment_id}
# operationId: putV3ProjectsIdEnvironmentsEnvironmentId
export def "projects-environments put" [
  id: string
  environment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The new environment name
  --external-url: string # The new URL on which this deployment is viewable
  --slug: string
]: any -> record<external_url: string, id: string, name: string, project: record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string>, slug: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/environments/($environment_id)")
  let body = {name: $name, external_url: $external_url, slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get events for a single project
#
# GET /v3/projects/{id}/events
# operationId: getV3ProjectsIdEvents
export def "projects-events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author_id: string, author_username: string, created_at: string, data: string, note: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string>, project_id: string, target_id: string, target_title: string, target_type: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a forked_from relationship
#
# DELETE /v3/projects/{id}/fork
# operationId: deleteV3ProjectsIdFork
export def "projects-fork delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/fork")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark this project as forked from another
#
# POST /v3/projects/{id}/fork/{forked_from_id}
# operationId: postV3ProjectsIdForkForkedFromId
export def "projects-fork post-by-id-forked_from_id" [
  id: string
  forked_from_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/fork/($forked_from_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project hooks
#
# GET /v3/projects/{id}/hooks
# operationId: getV3ProjectsIdHooks
export def "projects-hooks list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add hook to project
#
# POST /v3/projects/{id}/hooks
# operationId: postV3ProjectsIdHooks
export def "projects-hooks post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The URL to send the request to
  --push-events: oneof<nothing, bool> # Trigger hook on push events
  --issues-events: oneof<nothing, bool> # Trigger hook on issues events
  --merge-requests-events: oneof<nothing, bool> # Trigger hook on merge request events
  --tag-push-events: oneof<nothing, bool> # Trigger hook on tag push events
  --note-events: oneof<nothing, bool> # Trigger hook on note(comment) events
  --build-events: oneof<nothing, bool> # Trigger hook on build events
  --pipeline-events: oneof<nothing, bool> # Trigger hook on pipeline events
  --wiki-page-events: oneof<nothing, bool> # Trigger hook on wiki events
  --enable-ssl-verification: oneof<nothing, bool> # Do SSL verification when triggering the hook
  --body-token: string # Secret token to validate received payloads; this will not be returned in the response
]: any -> record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/hooks")
  let body = {url: $body_url, push_events: $push_events, issues_events: $issues_events, merge_requests_events: $merge_requests_events, tag_push_events: $tag_push_events, note_events: $note_events, build_events: $build_events, pipeline_events: $pipeline_events, wiki_page_events: $wiki_page_events, enable_ssl_verification: $enable_ssl_verification, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deletes project hook
#
# DELETE /v3/projects/{id}/hooks/{hook_id}
# operationId: deleteV3ProjectsIdHooksHookId
export def "projects-hooks delete" [
  id: string
  hook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/hooks/($hook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project hook
#
# GET /v3/projects/{id}/hooks/{hook_id}
# operationId: getV3ProjectsIdHooksHookId
export def "projects-hooks get" [
  id: string
  hook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/hooks/($hook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing project hook
#
# PUT /v3/projects/{id}/hooks/{hook_id}
# operationId: putV3ProjectsIdHooksHookId
export def "projects-hooks put" [
  id: string
  hook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The URL to send the request to
  --push-events: oneof<nothing, bool> # Trigger hook on push events
  --issues-events: oneof<nothing, bool> # Trigger hook on issues events
  --merge-requests-events: oneof<nothing, bool> # Trigger hook on merge request events
  --tag-push-events: oneof<nothing, bool> # Trigger hook on tag push events
  --note-events: oneof<nothing, bool> # Trigger hook on note(comment) events
  --build-events: oneof<nothing, bool> # Trigger hook on build events
  --pipeline-events: oneof<nothing, bool> # Trigger hook on pipeline events
  --wiki-page-events: oneof<nothing, bool> # Trigger hook on wiki events
  --enable-ssl-verification: oneof<nothing, bool> # Do SSL verification when triggering the hook
  --body-token: string # Secret token to validate received payloads; this will not be returned in the response
]: any -> record<build_events: string, created_at: string, enable_ssl_verification: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, project_id: string, push_events: string, tag_push_events: string, url: string, wiki_page_events: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/hooks/($hook_id)")
  let body = {url: $body_url, push_events: $push_events, issues_events: $issues_events, merge_requests_events: $merge_requests_events, tag_push_events: $tag_push_events, note_events: $note_events, build_events: $build_events, pipeline_events: $pipeline_events, wiki_page_events: $wiki_page_events, enable_ssl_verification: $enable_ssl_verification, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of project issues
#
# GET /v3/projects/{id}/issues
# operationId: getV3ProjectsIdIssues
export def "projects-issues list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer # Return opened, closed, or all issues (default: all)
  --iid: int # Return the issue having the given `iid` (format: int32)
  --labels: string # Comma-separated list of label names
  --milestone: string # Return issues for a specific milestone
  --order-by: string@order-by-completer-1 # Return issues ordered by `created_at` or `updated_at` fields. (default: created_at)
  --qp-sort: string@sort-completer # Return issues sorted in `asc` or `desc` order. (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "iid" $iid "scalar") (serialize-qp "labels" $labels "scalar") (serialize-qp "milestone" $milestone "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new project issue
#
# POST /v3/projects/{id}/issues
# operationId: postV3ProjectsIdIssues
export def "projects-issues post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of an issue
  --created-at: string # Date time when the issue was created. Available only for admins and project owners.
  --merge-request-for-resolving-discussions: int # The IID of a merge request for which to resolve discussions
  --description: string # The description of an issue
  --assignee-id: int # The ID of a user to assign issue
  --milestone-id: int # The ID of a milestone to assign issue
  --labels: string # Comma-separated list of label names
  --due-date: string # Date time string in the format YEAR-MONTH-DAY
  --confidential: oneof<nothing, bool> # Boolean parameter if the issue should be confidential
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues")
  let body = {title: $title, created_at: $created_at, merge_request_for_resolving_discussions: $merge_request_for_resolving_discussions, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, due_date: $due_date, confidential: $confidential} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a project issue
#
# DELETE /v3/projects/{id}/issues/{issue_id}
# operationId: deleteV3ProjectsIdIssuesIssueId
export def "projects-issues delete" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single project issue
#
# GET /v3/projects/{id}/issues/{issue_id}
# operationId: getV3ProjectsIdIssuesIssueId
export def "projects-issues get" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing issue
#
# PUT /v3/projects/{id}/issues/{issue_id}
# operationId: putV3ProjectsIdIssuesIssueId
export def "projects-issues put" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of an issue
  --updated-at: string # Date time when the issue was updated. Available only for admins and project owners.
  --state-event: string@state-event-completer # State of the issue
  --description: string # The description of an issue
  --assignee-id: int # The ID of a user to assign issue
  --milestone-id: int # The ID of a milestone to assign issue
  --labels: string # Comma-separated list of label names
  --due-date: string # Date time string in the format YEAR-MONTH-DAY
  --confidential: oneof<nothing, bool> # Boolean parameter if the issue should be confidential
  --created-at: string
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)")
  let body = {title: $title, updated_at: $updated_at, state_event: $state_event, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, due_date: $due_date, confidential: $confidential, created_at: $created_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add spent time for a project issue
#
# POST /v3/projects/{id}/issues/{issue_id}/add_spent_time
# operationId: postV3ProjectsIdIssuesIssueIdAddSpentTime
export def "projects-issues-add-spent-time post" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  duration: string # The duration to be parsed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/add_spent_time")
  let body = {duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/issues/{issue_id}/award_emoji
# operationId: getV3ProjectsIdIssuesIssueIdAwardEmoji
export def "projects-issues-award-emoji list" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/award_emoji" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Award a new Emoji
#
# POST /v3/projects/{id}/issues/{issue_id}/award_emoji
# operationId: postV3ProjectsIdIssuesIssueIdAwardEmoji
export def "projects-issues-award-emoji post" [
  id: int
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/award_emoji")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/issues/{issue_id}/award_emoji/{award_id}
# operationId: deleteV3ProjectsIdIssuesIssueIdAwardEmojiAwardId
export def "projects-issues-award-emoji delete" [
  award_id: int
  id: int
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/issues/{issue_id}/award_emoji/{award_id}
# operationId: getV3ProjectsIdIssuesIssueIdAwardEmojiAwardId
export def "projects-issues-award-emoji get" [
  award_id: int
  id: int
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move an existing issue
#
# POST /v3/projects/{id}/issues/{issue_id}/move
# operationId: postV3ProjectsIdIssuesIssueIdMove
export def "projects-issues-move post" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  to_project_id: int # The ID of the new project
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/move")
  let body = {to_project_id: $to_project_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji
# operationId: getV3ProjectsIdIssuesIssueIdNotesNoteIdAwardEmoji
export def "projects-issues-notes-award-emoji list" [
  id: int
  issue_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/notes/($note_id)/award_emoji" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Award a new Emoji
#
# POST /v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji
# operationId: postV3ProjectsIdIssuesIssueIdNotesNoteIdAwardEmoji
export def "projects-issues-notes-award-emoji post" [
  id: int
  issue_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/notes/($note_id)/award_emoji")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji/{award_id}
# operationId: deleteV3ProjectsIdIssuesIssueIdNotesNoteIdAwardEmojiAwardId
export def "projects-issues-notes-award-emoji delete" [
  award_id: int
  id: int
  issue_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/notes/($note_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/issues/{issue_id}/notes/{note_id}/award_emoji/{award_id}
# operationId: getV3ProjectsIdIssuesIssueIdNotesNoteIdAwardEmojiAwardId
export def "projects-issues-notes-award-emoji get" [
  award_id: int
  id: int
  issue_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/notes/($note_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset spent time for a project issue
#
# POST /v3/projects/{id}/issues/{issue_id}/reset_spent_time
# operationId: postV3ProjectsIdIssuesIssueIdResetSpentTime
export def "projects-issues-reset-spent-time post" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/reset_spent_time")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset the time estimate for a project issue
#
# POST /v3/projects/{id}/issues/{issue_id}/reset_time_estimate
# operationId: postV3ProjectsIdIssuesIssueIdResetTimeEstimate
export def "projects-issues-reset-time-estimate post" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/reset_time_estimate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a time estimate for a project issue
#
# POST /v3/projects/{id}/issues/{issue_id}/time_estimate
# operationId: postV3ProjectsIdIssuesIssueIdTimeEstimate
export def "projects-issues-time-estimate post" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  duration: string # The duration to be parsed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/time_estimate")
  let body = {duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Show time stats for a project issue
#
# GET /v3/projects/{id}/issues/{issue_id}/time_stats
# operationId: getV3ProjectsIdIssuesIssueIdTimeStats
export def "projects-issues-time-stats get" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/time_stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a todo on an issuable
#
# POST /v3/projects/{id}/issues/{issue_id}/todo
# operationId: postV3ProjectsIdIssuesIssueIdTodo
export def "projects-issues-todo post" [
  id: string
  issue_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($issue_id)/todo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of project +noteable+ notes
#
# GET /v3/projects/{id}/issues/{noteable_id}/notes
# operationId: getV3ProjectsIdIssuesNoteableIdNotes
export def "projects-issues-notes list" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($noteable_id)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new +noteable+ note
#
# POST /v3/projects/{id}/issues/{noteable_id}/notes
# operationId: postV3ProjectsIdIssuesNoteableIdNotes
export def "projects-issues-notes post" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # The content of a note
  --created-at: string # The creation date of the note
]: any -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($noteable_id)/notes")
  let body = {body: $body_body, created_at: $created_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +noteable+ note
#
# DELETE /v3/projects/{id}/issues/{noteable_id}/notes/{note_id}
# operationId: deleteV3ProjectsIdIssuesNoteableIdNotesNoteId
export def "projects-issues-notes delete" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($noteable_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single +noteable+ note
#
# GET /v3/projects/{id}/issues/{noteable_id}/notes/{note_id}
# operationId: getV3ProjectsIdIssuesNoteableIdNotesNoteId
export def "projects-issues-notes get" [
  id: string
  note_id: int
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($noteable_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing +noteable+ note
#
# PUT /v3/projects/{id}/issues/{noteable_id}/notes/{note_id}
# operationId: putV3ProjectsIdIssuesNoteableIdNotesNoteId
export def "projects-issues-notes put" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # The content of a note
]: any -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($noteable_id)/notes/($note_id)")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unsubscribe from a resource
#
# DELETE /v3/projects/{id}/issues/{subscribable_id}/subscription
# operationId: deleteV3ProjectsIdIssuesSubscribableIdSubscription
export def "projects-issues-subscription delete" [
  id: string
  subscribable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($subscribable_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to a resource
#
# POST /v3/projects/{id}/issues/{subscribable_id}/subscription
# operationId: postV3ProjectsIdIssuesSubscribableIdSubscription
export def "projects-issues-subscription post" [
  id: string
  subscribable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/issues/($subscribable_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific project's deploy keys
#
# GET /v3/projects/{id}/keys
# operationId: getV3ProjectsIdKeys
export def "projects-keys list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new deploy key to currently authenticated user
#
# POST /v3/projects/{id}/keys
# operationId: postV3ProjectsIdKeys
export def "projects-keys post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The new deploy key
  title: string # The name of the deploy key
]: any -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/keys")
  let body = {key: $key, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete deploy key for a project
#
# DELETE /v3/projects/{id}/keys/{key_id}
# operationId: deleteV3ProjectsIdKeysKeyId
export def "projects-keys delete" [
  id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single deploy key
#
# GET /v3/projects/{id}/keys/{key_id}
# operationId: getV3ProjectsIdKeysKeyId
export def "projects-keys get" [
  id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable a deploy key for a project
#
# DELETE /v3/projects/{id}/keys/{key_id}/disable
# operationId: deleteV3ProjectsIdKeysKeyIdDisable
export def "projects-keys-disable delete" [
  id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/keys/($key_id)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a deploy key for a project
#
# POST /v3/projects/{id}/keys/{key_id}/enable
# operationId: postV3ProjectsIdKeysKeyIdEnable
export def "projects-keys-enable post" [
  id: string
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/keys/($key_id)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing label
#
# DELETE /v3/projects/{id}/labels
# operationId: deleteV3ProjectsIdLabels
export def "projects-labels delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the label to be deleted
]: nothing -> record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/labels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all labels of the project
#
# GET /v3/projects/{id}/labels
# operationId: getV3ProjectsIdLabels
export def "projects-labels get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/labels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new label
#
# POST /v3/projects/{id}/labels
# operationId: postV3ProjectsIdLabels
export def "projects-labels post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the label to be created
  color: string # The color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB)
  --description: string # The description of label to be created
  --priority: int # The priority of the label
]: any -> record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/labels")
  let body = {name: $name, color: $color, description: $description, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update an existing label. At least one optional parameter is required.
#
# PUT /v3/projects/{id}/labels
# operationId: putV3ProjectsIdLabels
export def "projects-labels put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the label to be updated
  --new-name: string # The new name of the label
  --color: string # The new color of the label given in 6-digit hex notation with leading '#' sign (e.g. #FFAABB)
  --description: string # The new description of label
  --priority: int # The priority of the label
]: any -> record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/labels")
  let body = {name: $name, new_name: $new_name, color: $color, description: $description, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unsubscribe from a resource
#
# DELETE /v3/projects/{id}/labels/{subscribable_id}/subscription
# operationId: deleteV3ProjectsIdLabelsSubscribableIdSubscription
export def "projects-labels-subscription delete" [
  id: string
  subscribable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/labels/($subscribable_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to a resource
#
# POST /v3/projects/{id}/labels/{subscribable_id}/subscription
# operationId: postV3ProjectsIdLabelsSubscribableIdSubscription
export def "projects-labels-subscription post" [
  id: string
  subscribable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<closed_issues_count: string, color: string, description: string, id: string, name: string, open_issues_count: string, open_merge_requests_count: string, priority: string, subscribed: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/labels/($subscribable_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of group or project members viewable by the authenticated user.
#
# GET /v3/projects/{id}/members
# operationId: getV3ProjectsIdMembers
export def "projects-members list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A query string to search for members
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a member to a group or project.
#
# POST /v3/projects/{id}/members
# operationId: postV3ProjectsIdMembers
export def "projects-members post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_id: int # The user ID of the new member
  access_level: int # A valid access level (defaults: `30`, developer access level)
  --expires-at: string # Date string in the format YEAR-MONTH-DAY
]: any -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/members")
  let body = {user_id: $user_id, access_level: $access_level, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Removes a user from a group or project.
#
# DELETE /v3/projects/{id}/members/{user_id}
# operationId: deleteV3ProjectsIdMembersUserId
export def "projects-members delete" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a member of a group or project.
#
# GET /v3/projects/{id}/members/{user_id}
# operationId: getV3ProjectsIdMembersUserId
export def "projects-members get" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a member of a group or project.
#
# PUT /v3/projects/{id}/members/{user_id}
# operationId: putV3ProjectsIdMembersUserId
export def "projects-members put" [
  id: string
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  access_level: int # A valid access level
  --expires-at: string # Date string in the format YEAR-MONTH-DAY
]: any -> record<access_level: string, avatar_url: string, expires_at: string, id: string, name: string, state: string, username: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/members/($user_id)")
  let body = {access_level: $access_level, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a single merge request
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}
# operationId: getV3ProjectsIdMergeRequestMergeRequestId
export def "projects-merge-request get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a merge request
#
# PUT /v3/projects/{id}/merge_request/{merge_request_id}
# operationId: putV3ProjectsIdMergeRequestMergeRequestId
export def "projects-merge-request put" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the merge request
  --target-branch: string # The target branch
  --state-event: string@state-event-completer-1 # Status of the merge request
  --description: string # The description of the merge request
  --assignee-id: int # The ID of a user to assign the merge request
  --milestone-id: int # The ID of a milestone to assign the merge request
  --labels: string # Comma-separated list of label names
  --remove-source-branch: oneof<nothing, bool> # Remove source branch when merging
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)")
  let body = {title: $title, target_branch: $target_branch, state_event: $state_event, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, remove_source_branch: $remove_source_branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Cancel merge if "Merge When Pipeline Succeeds" is enabled
#
# POST /v3/projects/{id}/merge_request/{merge_request_id}/cancel_merge_when_build_succeeds
# operationId: postV3ProjectsIdMergeRequestMergeRequestIdCancelMergeWhenBuildSucceeds
export def "projects-merge-request-cancel-merge-when-build-succeeds post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)/cancel_merge_when_build_succeeds")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show the merge request changes
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}/changes
# operationId: getV3ProjectsIdMergeRequestMergeRequestIdChanges
export def "projects-merge-request-changes get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, changes: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)/changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List issues that will be closed on merge
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}/closes_issues
# operationId: getV3ProjectsIdMergeRequestMergeRequestIdClosesIssues
export def "projects-merge-request-closes-issues get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)/closes_issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the comments of a merge request
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}/comments
# operationId: getV3ProjectsIdMergeRequestMergeRequestIdComments
export def "projects-merge-request-comments get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post a comment to a merge request
#
# POST /v3/projects/{id}/merge_request/{merge_request_id}/comments
# operationId: postV3ProjectsIdMergeRequestMergeRequestIdComments
export def "projects-merge-request-comments post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The text of the comment
]: any -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)/comments")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get the commits of a merge request
#
# GET /v3/projects/{id}/merge_request/{merge_request_id}/commits
# operationId: getV3ProjectsIdMergeRequestMergeRequestIdCommits
export def "projects-merge-request-commits get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)/commits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merge a merge request
#
# PUT /v3/projects/{id}/merge_request/{merge_request_id}/merge
# operationId: putV3ProjectsIdMergeRequestMergeRequestIdMerge
export def "projects-merge-request-merge put" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --merge-commit-message: string # Custom merge commit message
  --should-remove-source-branch: oneof<nothing, bool> # When true, the source branch will be deleted if possible
  --merge-when-build-succeeds: oneof<nothing, bool> # When true, this merge request will be merged when the pipeline succeeds
  --sha: string # When present, must have the HEAD SHA of the source branch
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($merge_request_id)/merge")
  let body = {merge_commit_message: $merge_commit_message, should_remove_source_branch: $should_remove_source_branch, merge_when_build_succeeds: $merge_when_build_succeeds, sha: $sha} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unsubscribe from a resource
#
# DELETE /v3/projects/{id}/merge_request/{subscribable_id}/subscription
# operationId: deleteV3ProjectsIdMergeRequestSubscribableIdSubscription
export def "projects-merge-request-subscription delete" [
  id: string
  subscribable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($subscribable_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to a resource
#
# POST /v3/projects/{id}/merge_request/{subscribable_id}/subscription
# operationId: postV3ProjectsIdMergeRequestSubscribableIdSubscription
export def "projects-merge-request-subscription post" [
  id: string
  subscribable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_request/($subscribable_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List merge requests
#
# GET /v3/projects/{id}/merge_requests
# operationId: getV3ProjectsIdMergeRequests
export def "projects-merge-requests list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1 # Return opened, closed, merged, or all merge requests (default: all)
  --order-by: string@order-by-completer-1 # Return merge requests ordered by `created_at` or `updated_at` fields. (default: created_at)
  --qp-sort: string@sort-completer # Return merge requests sorted in `asc` or `desc` order. (default: desc)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --iid: list # The IID of the merge requests
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests" $qp)
  let body = {iid: $iid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a merge request
#
# POST /v3/projects/{id}/merge_requests
# operationId: postV3ProjectsIdMergeRequests
export def "projects-merge-requests post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of the merge request
  source_branch: string # The source branch
  target_branch: string # The target branch
  --target-project-id: int # The target project of the merge request defaults to the :id of the project
  --description: string # The description of the merge request
  --assignee-id: int # The ID of a user to assign the merge request
  --milestone-id: int # The ID of a milestone to assign the merge request
  --labels: string # Comma-separated list of label names
  --remove-source-branch: oneof<nothing, bool> # Remove source branch when merging
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests")
  let body = {title: $title, source_branch: $source_branch, target_branch: $target_branch, target_project_id: $target_project_id, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, remove_source_branch: $remove_source_branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a merge request
#
# DELETE /v3/projects/{id}/merge_requests/{merge_request_id}
# operationId: deleteV3ProjectsIdMergeRequestsMergeRequestId
export def "projects-merge-requests delete" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single merge request
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}
# operationId: getV3ProjectsIdMergeRequestsMergeRequestId
export def "projects-merge-requests get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a merge request
#
# PUT /v3/projects/{id}/merge_requests/{merge_request_id}
# operationId: putV3ProjectsIdMergeRequestsMergeRequestId
export def "projects-merge-requests put" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the merge request
  --target-branch: string # The target branch
  --state-event: string@state-event-completer-1 # Status of the merge request
  --description: string # The description of the merge request
  --assignee-id: int # The ID of a user to assign the merge request
  --milestone-id: int # The ID of a milestone to assign the merge request
  --labels: string # Comma-separated list of label names
  --remove-source-branch: oneof<nothing, bool> # Remove source branch when merging
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)")
  let body = {title: $title, target_branch: $target_branch, state_event: $state_event, description: $description, assignee_id: $assignee_id, milestone_id: $milestone_id, labels: $labels, remove_source_branch: $remove_source_branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add spent time for a project merge_request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/add_spent_time
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdAddSpentTime
export def "projects-merge-requests-add-spent-time post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  duration: string # The duration to be parsed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/add_spent_time")
  let body = {duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdAwardEmoji
export def "projects-merge-requests-award-emoji list" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/award_emoji" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Award a new Emoji
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdAwardEmoji
export def "projects-merge-requests-award-emoji post" [
  id: int
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/award_emoji")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji/{award_id}
# operationId: deleteV3ProjectsIdMergeRequestsMergeRequestIdAwardEmojiAwardId
export def "projects-merge-requests-award-emoji delete" [
  award_id: int
  id: int
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/award_emoji/{award_id}
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdAwardEmojiAwardId
export def "projects-merge-requests-award-emoji get" [
  award_id: int
  id: int
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel merge if "Merge When Pipeline Succeeds" is enabled
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/cancel_merge_when_build_succeeds
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdCancelMergeWhenBuildSucceeds
export def "projects-merge-requests-cancel-merge-when-build-succeeds post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/cancel_merge_when_build_succeeds")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show the merge request changes
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/changes
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdChanges
export def "projects-merge-requests-changes get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, changes: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List issues that will be closed on merge
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/closes_issues
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdClosesIssues
export def "projects-merge-requests-closes-issues get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/closes_issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the comments of a merge request
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/comments
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdComments
export def "projects-merge-requests-comments get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post a comment to a merge request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/comments
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdComments
export def "projects-merge-requests-comments post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The text of the comment
]: any -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, note: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/comments")
  let body = {note: $note} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get the commits of a merge request
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/commits
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdCommits
export def "projects-merge-requests-commits get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/commits")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merge a merge request
#
# PUT /v3/projects/{id}/merge_requests/{merge_request_id}/merge
# operationId: putV3ProjectsIdMergeRequestsMergeRequestIdMerge
export def "projects-merge-requests-merge put" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --merge-commit-message: string # Custom merge commit message
  --should-remove-source-branch: oneof<nothing, bool> # When true, the source branch will be deleted if possible
  --merge-when-build-succeeds: oneof<nothing, bool> # When true, this merge request will be merged when the pipeline succeeds
  --sha: string # When present, must have the HEAD SHA of the source branch
]: any -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/merge")
  let body = {merge_commit_message: $merge_commit_message, should_remove_source_branch: $should_remove_source_branch, merge_when_build_succeeds: $merge_when_build_succeeds, sha: $sha} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdNotesNoteIdAwardEmoji
export def "projects-merge-requests-notes-award-emoji list" [
  id: int
  merge_request_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/notes/($note_id)/award_emoji" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Award a new Emoji
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdNotesNoteIdAwardEmoji
export def "projects-merge-requests-notes-award-emoji post" [
  id: int
  merge_request_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/notes/($note_id)/award_emoji")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji/{award_id}
# operationId: deleteV3ProjectsIdMergeRequestsMergeRequestIdNotesNoteIdAwardEmojiAwardId
export def "projects-merge-requests-notes-award-emoji delete" [
  award_id: int
  id: int
  merge_request_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/notes/($note_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/notes/{note_id}/award_emoji/{award_id}
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdNotesNoteIdAwardEmojiAwardId
export def "projects-merge-requests-notes-award-emoji get" [
  award_id: int
  id: int
  merge_request_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/notes/($note_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset spent time for a project merge_request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/reset_spent_time
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdResetSpentTime
export def "projects-merge-requests-reset-spent-time post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/reset_spent_time")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset the time estimate for a project merge_request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/reset_time_estimate
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdResetTimeEstimate
export def "projects-merge-requests-reset-time-estimate post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/reset_time_estimate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a time estimate for a project merge_request
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/time_estimate
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdTimeEstimate
export def "projects-merge-requests-time-estimate post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  duration: string # The duration to be parsed
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/time_estimate")
  let body = {duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Show time stats for a project merge_request
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/time_stats
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdTimeStats
export def "projects-merge-requests-time-stats get" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/time_stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a todo on an issuable
#
# POST /v3/projects/{id}/merge_requests/{merge_request_id}/todo
# operationId: postV3ProjectsIdMergeRequestsMergeRequestIdTodo
export def "projects-merge-requests-todo post" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/todo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of merge request diff versions
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/versions
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdVersions
export def "projects-merge-requests-versions list" [
  id: string
  merge_request_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<base_commit_sha: string, created_at: string, head_commit_sha: string, id: string, merge_request_id: string, real_size: string, start_commit_sha: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/versions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single merge request diff version
#
# GET /v3/projects/{id}/merge_requests/{merge_request_id}/versions/{version_id}
# operationId: getV3ProjectsIdMergeRequestsMergeRequestIdVersionsVersionId
export def "projects-merge-requests-versions get" [
  id: string
  merge_request_id: int
  version_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<base_commit_sha: string, commits: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, created_at: string, diffs: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>, head_commit_sha: string, id: string, merge_request_id: string, real_size: string, start_commit_sha: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($merge_request_id)/versions/($version_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of project +noteable+ notes
#
# GET /v3/projects/{id}/merge_requests/{noteable_id}/notes
# operationId: getV3ProjectsIdMergeRequestsNoteableIdNotes
export def "projects-merge-requests-notes list" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($noteable_id)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new +noteable+ note
#
# POST /v3/projects/{id}/merge_requests/{noteable_id}/notes
# operationId: postV3ProjectsIdMergeRequestsNoteableIdNotes
export def "projects-merge-requests-notes post" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # The content of a note
  --created-at: string # The creation date of the note
]: any -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($noteable_id)/notes")
  let body = {body: $body_body, created_at: $created_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +noteable+ note
#
# DELETE /v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}
# operationId: deleteV3ProjectsIdMergeRequestsNoteableIdNotesNoteId
export def "projects-merge-requests-notes delete" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($noteable_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single +noteable+ note
#
# GET /v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}
# operationId: getV3ProjectsIdMergeRequestsNoteableIdNotesNoteId
export def "projects-merge-requests-notes get" [
  id: string
  note_id: int
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($noteable_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing +noteable+ note
#
# PUT /v3/projects/{id}/merge_requests/{noteable_id}/notes/{note_id}
# operationId: putV3ProjectsIdMergeRequestsNoteableIdNotesNoteId
export def "projects-merge-requests-notes put" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # The content of a note
]: any -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($noteable_id)/notes/($note_id)")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unsubscribe from a resource
#
# DELETE /v3/projects/{id}/merge_requests/{subscribable_id}/subscription
# operationId: deleteV3ProjectsIdMergeRequestsSubscribableIdSubscription
export def "projects-merge-requests-subscription delete" [
  id: string
  subscribable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($subscribable_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to a resource
#
# POST /v3/projects/{id}/merge_requests/{subscribable_id}/subscription
# operationId: postV3ProjectsIdMergeRequestsSubscribableIdSubscription
export def "projects-merge-requests-subscription post" [
  id: string
  subscribable_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, downvotes: string, force_remove_source_branch: string, id: string, iid: string, labels: string, merge_commit_sha: string, merge_status: string, merge_when_build_succeeds: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, sha: string, should_remove_source_branch: string, source_branch: string, source_project_id: string, state: string, subscribed: string, target_branch: string, target_project_id: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string, work_in_progress: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/merge_requests/($subscribable_id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of project milestones
#
# GET /v3/projects/{id}/milestones
# operationId: getV3ProjectsIdMilestones
export def "projects-milestones list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-2 # Return "active", "closed", or "all" milestones (default: all)
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --iid: list # The IID of the milestone
]: any -> record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/milestones" $qp)
  let body = {iid: $iid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new project milestone
#
# POST /v3/projects/{id}/milestones
# operationId: postV3ProjectsIdMilestones
export def "projects-milestones post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of the milestone
  --description: string # The description of the milestone
  --due-date: string # The due date of the milestone. The ISO 8601 date format (%Y-%m-%d)
  --start-date: string # The start date of the milestone. The ISO 8601 date format (%Y-%m-%d)
]: any -> record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/milestones")
  let body = {title: $title, description: $description, due_date: $due_date, start_date: $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a single project milestone
#
# GET /v3/projects/{id}/milestones/{milestone_id}
# operationId: getV3ProjectsIdMilestonesMilestoneId
export def "projects-milestones get" [
  id: string
  milestone_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/milestones/($milestone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing project milestone
#
# PUT /v3/projects/{id}/milestones/{milestone_id}
# operationId: putV3ProjectsIdMilestonesMilestoneId
export def "projects-milestones put" [
  id: string
  milestone_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the milestone
  --state-event: string@state-event-completer-2 # The state event of the milestone 
  --description: string # The description of the milestone
  --due-date: string # The due date of the milestone. The ISO 8601 date format (%Y-%m-%d)
  --start-date: string # The start date of the milestone. The ISO 8601 date format (%Y-%m-%d)
]: any -> record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/milestones/($milestone_id)")
  let body = {title: $title, state_event: $state_event, description: $description, due_date: $due_date, start_date: $start_date} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all issues for a single project milestone
#
# GET /v3/projects/{id}/milestones/{milestone_id}/issues
# operationId: getV3ProjectsIdMilestonesMilestoneIdIssues
export def "projects-milestones-issues get" [
  id: string
  milestone_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<assignee: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, confidential: string, created_at: string, description: string, downvotes: string, due_date: string, id: string, iid: string, labels: string, milestone: record<created_at: string, description: string, due_date: string, id: string, iid: string, project_id: string, start_date: string, state: string, title: string, updated_at: string>, project_id: string, state: string, subscribed: string, title: string, updated_at: string, upvotes: string, user_notes_count: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/milestones/($milestone_id)/issues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project level notification level settings, defaults to Global
#
# GET /v3/projects/{id}/notification_settings
# operationId: getV3ProjectsIdNotificationSettings
export def "projects-notification-settings get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<events: string, level: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/notification_settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project level notification level settings, defaults to Global
#
# PUT /v3/projects/{id}/notification_settings
# operationId: putV3ProjectsIdNotificationSettings
export def "projects-notification-settings put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --level: string # The project notification level
  --new-note: oneof<nothing, bool> # Enable/disable this notification
  --new-issue: oneof<nothing, bool> # Enable/disable this notification
  --reopen-issue: oneof<nothing, bool> # Enable/disable this notification
  --close-issue: oneof<nothing, bool> # Enable/disable this notification
  --reassign-issue: oneof<nothing, bool> # Enable/disable this notification
  --new-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reopen-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --close-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --reassign-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --merge-merge-request: oneof<nothing, bool> # Enable/disable this notification
  --failed-pipeline: oneof<nothing, bool> # Enable/disable this notification
  --success-pipeline: oneof<nothing, bool> # Enable/disable this notification
]: any -> record<events: string, level: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/notification_settings")
  let body = {level: $level, new_note: $new_note, new_issue: $new_issue, reopen_issue: $reopen_issue, close_issue: $close_issue, reassign_issue: $reassign_issue, new_merge_request: $new_merge_request, reopen_merge_request: $reopen_merge_request, close_merge_request: $close_merge_request, reassign_merge_request: $reassign_merge_request, merge_merge_request: $merge_merge_request, failed_pipeline: $failed_pipeline, success_pipeline: $success_pipeline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new pipeline
#
# POST /v3/projects/{id}/pipeline
# operationId: postV3ProjectsIdPipeline
export def "projects-pipeline post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  ref: string # Reference
]: any -> record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/pipeline")
  let body = {ref: $ref} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all Pipelines of the project
#
# GET /v3/projects/{id}/pipelines
# operationId: getV3ProjectsIdPipelines
export def "projects-pipelines list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
  --scope: string@scope-completer-1 # Either running, branches, or tags
]: nothing -> record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/pipelines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a specific pipeline for the project
#
# GET /v3/projects/{id}/pipelines/{pipeline_id}
# operationId: getV3ProjectsIdPipelinesPipelineId
export def "projects-pipelines get" [
  id: string
  pipeline_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/pipelines/($pipeline_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel all builds in the pipeline
#
# POST /v3/projects/{id}/pipelines/{pipeline_id}/cancel
# operationId: postV3ProjectsIdPipelinesPipelineIdCancel
export def "projects-pipelines-cancel post" [
  id: string
  pipeline_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/pipelines/($pipeline_id)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry failed builds in the pipeline
#
# POST /v3/projects/{id}/pipelines/{pipeline_id}/retry
# operationId: postV3ProjectsIdPipelinesPipelineIdRetry
export def "projects-pipelines-retry post" [
  id: string
  pipeline_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<before_sha: string, committed_at: string, coverage: string, created_at: string, duration: string, finished_at: string, id: string, ref: string, sha: string, started_at: string, status: string, tag: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, yaml_errors: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/pipelines/($pipeline_id)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an archive of the repository
#
# GET /v3/projects/{id}/repository/archive
# operationId: getV3ProjectsIdRepositoryArchive
export def "projects-repository-archive get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sha: string # The commit sha of the archive to be downloaded
  --format: string # The archive format
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sha" $sha "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a raw file contents
#
# GET /v3/projects/{id}/repository/blobs/{sha}
# operationId: getV3ProjectsIdRepositoryBlobsSha
export def "projects-repository-blobs get" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filepath: string # The path to the file to display
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filepath" $filepath "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/blobs/($sha)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project repository branches
#
# GET /v3/projects/{id}/repository/branches
# operationId: getV3ProjectsIdRepositoryBranches
export def "projects-repository-branches list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create branch
#
# POST /v3/projects/{id}/repository/branches
# operationId: postV3ProjectsIdRepositoryBranches
export def "projects-repository-branches post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branch_name: string # The name of the branch
  ref: string # Create branch from commit sha or existing branch
]: any -> record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/branches")
  let body = {branch_name: $branch_name, ref: $ref} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a branch
#
# DELETE /v3/projects/{id}/repository/branches/{branch}
# operationId: deleteV3ProjectsIdRepositoryBranchesBranch
export def "projects-repository-branches delete" [
  id: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/branches/($branch)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single branch
#
# GET /v3/projects/{id}/repository/branches/{branch}
# operationId: getV3ProjectsIdRepositoryBranchesBranch
export def "projects-repository-branches get" [
  id: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/branches/($branch)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Protect a single branch
#
# PUT /v3/projects/{id}/repository/branches/{branch}/protect
# operationId: putV3ProjectsIdRepositoryBranchesBranchProtect
export def "projects-repository-branches-protect put" [
  id: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developers-can-push: oneof<nothing, bool> # Flag if developers can push to that branch
  --developers-can-merge: oneof<nothing, bool> # Flag if developers can merge to that branch
]: any -> record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/branches/($branch)/protect")
  let body = {developers_can_push: $developers_can_push, developers_can_merge: $developers_can_merge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unprotect a single branch
#
# PUT /v3/projects/{id}/repository/branches/{branch}/unprotect
# operationId: putV3ProjectsIdRepositoryBranchesBranchUnprotect
export def "projects-repository-branches-unprotect put" [
  id: string
  branch: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commit: string, developers_can_merge: string, developers_can_push: string, merged: string, name: string, protected: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/branches/($branch)/unprotect")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project repository commits
#
# GET /v3/projects/{id}/repository/commits
# operationId: getV3ProjectsIdRepositoryCommits
export def "projects-repository-commits list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref-name: string # The name of a repository branch or tag, if not given the default branch is used
  --since: string # Only commits after or in this date will be returned
  --until: string # Only commits before or in this date will be returned
  --page: int # The page for pagination (format: int32, default: 0)
  --per-page: int # The number of results per page (format: int32, default: 20)
  --path: string # The file path
]: nothing -> record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref_name" $ref_name "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Commit multiple file changes as one commit
#
# POST /v3/projects/{id}/repository/commits
# operationId: postV3ProjectsIdRepositoryCommits
export def "projects-repository-commits post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branch_name: string # The name of branch
  commit_message: string # Commit message
  actions: list # Actions to perform in commit
  --author-email: string # Author email for commit
  --author-name: string # Author name for commit
]: any -> record<author_email: string, author_name: string, authored_date: string, committed_date: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, parent_ids: string, short_id: string, stats: record<additions: string, deletions: string, total: string>, status: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits")
  let body = {branch_name: $branch_name, commit_message: $commit_message, actions: $actions, author_email: $author_email, author_name: $author_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a specific commit of a project
#
# GET /v3/projects/{id}/repository/commits/{sha}
# operationId: getV3ProjectsIdRepositoryCommitsSha
export def "projects-repository-commits get" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author_email: string, author_name: string, authored_date: string, committed_date: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, parent_ids: string, short_id: string, stats: record<additions: string, deletions: string, total: string>, status: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits/($sha)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a raw file contents
#
# GET /v3/projects/{id}/repository/commits/{sha}/blob
# operationId: getV3ProjectsIdRepositoryCommitsShaBlob
export def "projects-repository-commits-blob get" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filepath: string # The path to the file to display
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filepath" $filepath "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits/($sha)/blob" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get builds for a specific commit of a project
#
# GET /v3/projects/{id}/repository/commits/{sha}/builds
# operationId: getV3ProjectsIdRepositoryCommitsShaBuilds
export def "projects-repository-commits-builds get" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # The scope of builds to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<artifacts_file: record<filename: string, size: string>, commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, coverage: string, created_at: string, finished_at: string, id: string, name: string, pipeline: record<id: string, ref: string, sha: string, status: string>, ref: string, runner: record<active: string, description: string, id: string, is_shared: string, name: string>, stage: string, started_at: string, status: string, tag: string, user: record<avatar_url: string, bio: string, created_at: string, id: string, is_admin: string, linkedin: string, location: string, name: string, organization: string, skype: string, state: string, twitter: string, username: string, web_url: string, website_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits/($sha)/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cherry pick commit into a branch
#
# POST /v3/projects/{id}/repository/commits/{sha}/cherry_pick
# operationId: postV3ProjectsIdRepositoryCommitsShaCherryPick
export def "projects-repository-commits-cherry-pick post" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  branch: string # The name of the branch
]: any -> record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits/($sha)/cherry_pick")
  let body = {branch: $branch} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a commit's comments
#
# GET /v3/projects/{id}/repository/commits/{sha}/comments
# operationId: getV3ProjectsIdRepositoryCommitsShaComments
export def "projects-repository-commits-comments get" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, line: string, line_type: string, note: string, path: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits/($sha)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post comment to commit
#
# POST /v3/projects/{id}/repository/commits/{sha}/comments
# operationId: postV3ProjectsIdRepositoryCommitsShaComments
export def "projects-repository-commits-comments post" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  note: string # The text of the comment
  --path: string # The file path
  line: int # The line number
  line_type: string@line-type-completer # The type of the line
]: any -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, line: string, line_type: string, note: string, path: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits/($sha)/comments")
  let body = {note: $note, path: $path, line: $line, line_type: $line_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get the diff for a specific commit of a project
#
# GET /v3/projects/{id}/repository/commits/{sha}/diff
# operationId: getV3ProjectsIdRepositoryCommitsShaDiff
export def "projects-repository-commits-diff get" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits/($sha)/diff")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a commit's statuses
#
# GET /v3/projects/{id}/repository/commits/{sha}/statuses
# operationId: getV3ProjectsIdRepositoryCommitsShaStatuses
export def "projects-repository-commits-statuses get" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref: string # The ref
  --stage: string # The stage
  --name: string # The name
  --all: string # Show all statuses, default: false
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<allow_failure: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, finished_at: string, id: string, name: string, ref: string, sha: string, started_at: string, status: string, target_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref" $ref "scalar") (serialize-qp "stage" $stage "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "all" $all "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/commits/($sha)/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compare two branches, tags, or commits
#
# GET /v3/projects/{id}/repository/compare
# operationId: getV3ProjectsIdRepositoryCompare
export def "projects-repository-compare get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # The commit, branch name, or tag name to start comparison
  --qp-to: string # The commit, branch name, or tag name to stop comparison
]: nothing -> record<commit: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, commits: record<author_email: string, author_name: string, committer_email: string, committer_name: string, created_at: string, id: string, message: string, short_id: string, title: string>, compare_same_ref: string, compare_timeout: string, diffs: record<a_mode: string, b_mode: string, deleted_file: string, diff: string, new_file: string, new_path: string, old_path: string, renamed_file: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/compare" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get repository contributors
#
# GET /v3/projects/{id}/repository/contributors
# operationId: getV3ProjectsIdRepositoryContributors
export def "projects-repository-contributors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additions: string, commits: string, deletions: string, email: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/contributors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an existing file in repository
#
# DELETE /v3/projects/{id}/repository/files
# operationId: deleteV3ProjectsIdRepositoryFiles
export def "projects-repository-files delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-path: string # The path to new file. Ex. lib/class.rb
  --branch-name: string # The name of branch
  --commit-message: string # Commit Message
  --author-email: string # The email of the author
  --author-name: string # The name of the author
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_path" $file_path "scalar") (serialize-qp "branch_name" $branch_name "scalar") (serialize-qp "commit_message" $commit_message "scalar") (serialize-qp "author_email" $author_email "scalar") (serialize-qp "author_name" $author_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a file from repository
#
# GET /v3/projects/{id}/repository/files
# operationId: getV3ProjectsIdRepositoryFiles
export def "projects-repository-files get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-path: string # The path to the file. Ex. lib/class.rb
  --ref: string # The name of branch, tag, or commit
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "file_path" $file_path "scalar") (serialize-qp "ref" $ref "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new file in repository
#
# POST /v3/projects/{id}/repository/files
# operationId: postV3ProjectsIdRepositoryFiles
export def "projects-repository-files post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file_path: string # The path to new file. Ex. lib/class.rb
  branch_name: string # The name of branch
  commit_message: string # Commit Message
  --author-email: string # The email of the author
  --author-name: string # The name of the author
  content: string # File content
  --encoding: string@encoding-completer # File encoding
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/files")
  let body = {file_path: $file_path, branch_name: $branch_name, commit_message: $commit_message, author_email: $author_email, author_name: $author_name, content: $content, encoding: $encoding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update existing file in repository
#
# PUT /v3/projects/{id}/repository/files
# operationId: putV3ProjectsIdRepositoryFiles
export def "projects-repository-files put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file_path: string # The path to new file. Ex. lib/class.rb
  branch_name: string # The name of branch
  commit_message: string # Commit Message
  --author-email: string # The email of the author
  --author-name: string # The name of the author
  content: string # File content
  --encoding: string@encoding-completer # File encoding
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/files")
  let body = {file_path: $file_path, branch_name: $branch_name, commit_message: $commit_message, author_email: $author_email, author_name: $author_name, content: $content, encoding: $encoding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v3/projects/{id}/repository/merged_branches
#
# operationId: deleteV3ProjectsIdRepositoryMergedBranches
export def "projects-repository-merged-branches delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/merged_branches")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a raw blob contents by blob sha
#
# GET /v3/projects/{id}/repository/raw_blobs/{sha}
# operationId: getV3ProjectsIdRepositoryRawBlobsSha
export def "projects-repository-raw-blobs get" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/raw_blobs/($sha)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a project repository tags
#
# GET /v3/projects/{id}/repository/tags
# operationId: getV3ProjectsIdRepositoryTags
export def "projects-repository-tags list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new repository tag
#
# POST /v3/projects/{id}/repository/tags
# operationId: postV3ProjectsIdRepositoryTags
export def "projects-repository-tags post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tag_name: string # The name of the tag
  ref: string # The commit sha or branch name
  --message: string # Specifying a message creates an annotated tag
  --release-description: string # Specifying release notes stored in the GitLab database
]: any -> record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/tags")
  let body = {tag_name: $tag_name, ref: $ref, message: $message, release_description: $release_description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a repository tag
#
# DELETE /v3/projects/{id}/repository/tags/{tag_name}
# operationId: deleteV3ProjectsIdRepositoryTagsTagName
export def "projects-repository-tags delete" [
  id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/tags/($tag_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single repository tag
#
# GET /v3/projects/{id}/repository/tags/{tag_name}
# operationId: getV3ProjectsIdRepositoryTagsTagName
export def "projects-repository-tags get" [
  id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commit: string, message: string, name: string, release: record<description: string, tag_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/tags/($tag_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a release note to a tag
#
# POST /v3/projects/{id}/repository/tags/{tag_name}/release
# operationId: postV3ProjectsIdRepositoryTagsTagNameRelease
export def "projects-repository-tags-release post" [
  id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Release notes with markdown support
]: any -> record<description: string, tag_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/tags/($tag_name)/release")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update a tag's release note
#
# PUT /v3/projects/{id}/repository/tags/{tag_name}/release
# operationId: putV3ProjectsIdRepositoryTagsTagNameRelease
export def "projects-repository-tags-release put" [
  id: string
  tag_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  description: string # Release notes with markdown support
]: any -> record<description: string, tag_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/repository/tags/($tag_name)/release")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a project repository tree
#
# GET /v3/projects/{id}/repository/tree
# operationId: getV3ProjectsIdRepositoryTree
export def "projects-repository-tree get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref-name: string # The name of a repository branch or tag, if not given the default branch is used
  --path: string # The path of the tree
  --recursive: oneof<nothing, bool> # Used to get a recursive tree
]: nothing -> record<id: string, mode: string, name: string, path: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ref_name" $ref_name "scalar") (serialize-qp "path" $path "scalar") (serialize-qp "recursive" $recursive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/repository/tree" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get runners available for project
#
# GET /v3/projects/{id}/runners
# operationId: getV3ProjectsIdRunners
export def "projects-runners get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer-2 # The scope of specific runners to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<active: string, description: string, id: string, is_shared: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a runner for a project
#
# POST /v3/projects/{id}/runners
# operationId: postV3ProjectsIdRunners
export def "projects-runners post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  runner_id: int # The ID of the runner
]: any -> record<active: string, description: string, id: string, is_shared: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/runners")
  let body = {runner_id: $runner_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Disable project's runner
#
# DELETE /v3/projects/{id}/runners/{runner_id}
# operationId: deleteV3ProjectsIdRunnersRunnerId
export def "projects-runners delete" [
  id: string
  runner_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: string, description: string, id: string, is_shared: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/runners/($runner_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set asana service for project
#
# PUT /v3/projects/{id}/services/asana
# operationId: putV3ProjectsIdServicesAsana
export def "projects-services-asana put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # User API token
  --restrict-to-branch: string # Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/asana")
  let body = {api_key: $api_key, restrict_to_branch: $restrict_to_branch, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set assembla service for project
#
# PUT /v3/projects/{id}/services/assembla
# operationId: putV3ProjectsIdServicesAssembla
export def "projects-services-assembla put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The authentication token
  --subdomain: string # Subdomain setting
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/assembla")
  let body = {token: $body_token, subdomain: $subdomain, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set bamboo service for project
#
# PUT /v3/projects/{id}/services/bamboo
# operationId: putV3ProjectsIdServicesBamboo
export def "projects-services-bamboo put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bamboo_url: string # Bamboo root URL like https://bamboo.example.com
  build_key: string # Bamboo build plan key like
  username: string # A user with API access, if applicable
  password: string # Passord of the user
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/bamboo")
  let body = {bamboo_url: $bamboo_url, build_key: $build_key, username: $username, password: $password, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set bugzilla service for project
#
# PUT /v3/projects/{id}/services/bugzilla
# operationId: putV3ProjectsIdServicesBugzilla
export def "projects-services-bugzilla put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_issue_url: string # New issue URL
  issues_url: string # Issues URL
  project_url: string # Project URL
  --description: string # Description
  --title: string # Title
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/bugzilla")
  let body = {new_issue_url: $new_issue_url, issues_url: $issues_url, project_url: $project_url, description: $description, title: $title, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set buildkite service for project
#
# PUT /v3/projects/{id}/services/buildkite
# operationId: putV3ProjectsIdServicesBuildkite
export def "projects-services-buildkite put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Buildkite project GitLab token
  project_url: string # The buildkite project URL
  --enable-ssl-verification: oneof<nothing, bool> # Enable SSL verification for communication
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/buildkite")
  let body = {token: $body_token, project_url: $project_url, enable_ssl_verification: $enable_ssl_verification, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set builds-email service for project
#
# PUT /v3/projects/{id}/services/builds-email
# operationId: putV3ProjectsIdServicesBuildsEmail
export def "projects-services-builds-email put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  recipients: string # Comma-separated list of recipient email addresses
  --add-pusher: oneof<nothing, bool> # Add pusher to recipients list
  --notify-only-broken-builds: oneof<nothing, bool> # Notify only broken builds
  --build-events: string # Event will be triggered when a build status changes
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/builds-email")
  let body = {recipients: $recipients, add_pusher: $add_pusher, notify_only_broken_builds: $notify_only_broken_builds, build_events: $build_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set campfire service for project
#
# PUT /v3/projects/{id}/services/campfire
# operationId: putV3ProjectsIdServicesCampfire
export def "projects-services-campfire put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Campfire token
  --subdomain: string # Campfire subdomain
  --room: string # Campfire room
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/campfire")
  let body = {token: $body_token, subdomain: $subdomain, room: $room, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set custom-issue-tracker service for project
#
# PUT /v3/projects/{id}/services/custom-issue-tracker
# operationId: putV3ProjectsIdServicesCustomIssueTracker
export def "projects-services-custom-issue-tracker put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_issue_url: string # New issue URL
  issues_url: string # Issues URL
  project_url: string # Project URL
  --description: string # Description
  --title: string # Title
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/custom-issue-tracker")
  let body = {new_issue_url: $new_issue_url, issues_url: $issues_url, project_url: $project_url, description: $description, title: $title, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set drone-ci service for project
#
# PUT /v3/projects/{id}/services/drone-ci
# operationId: putV3ProjectsIdServicesDroneCi
export def "projects-services-drone-ci put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Drone CI token
  drone_url: string # Drone CI URL
  --enable-ssl-verification: oneof<nothing, bool> # Enable SSL verification for communication
  --push-events: string # Event will be triggered by a push to the repository
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/drone-ci")
  let body = {token: $body_token, drone_url: $drone_url, enable_ssl_verification: $enable_ssl_verification, push_events: $push_events, merge_request_events: $merge_request_events, tag_push_events: $tag_push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set emails-on-push service for project
#
# PUT /v3/projects/{id}/services/emails-on-push
# operationId: putV3ProjectsIdServicesEmailsOnPush
export def "projects-services-emails-on-push put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  recipients: string # Comma-separated list of recipient email addresses
  --disable-diffs: oneof<nothing, bool> # Disable code diffs
  --send-from-committer-email: oneof<nothing, bool> # Send from committer
  --push-events: string # Event will be triggered by a push to the repository
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/emails-on-push")
  let body = {recipients: $recipients, disable_diffs: $disable_diffs, send_from_committer_email: $send_from_committer_email, push_events: $push_events, tag_push_events: $tag_push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set external-wiki service for project
#
# PUT /v3/projects/{id}/services/external-wiki
# operationId: putV3ProjectsIdServicesExternalWiki
export def "projects-services-external-wiki put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  external_wiki_url: string # The URL of the external Wiki
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/external-wiki")
  let body = {external_wiki_url: $external_wiki_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set flowdock service for project
#
# PUT /v3/projects/{id}/services/flowdock
# operationId: putV3ProjectsIdServicesFlowdock
export def "projects-services-flowdock put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # Flowdock token
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/flowdock")
  let body = {token: $body_token, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set gemnasium service for project
#
# PUT /v3/projects/{id}/services/gemnasium
# operationId: putV3ProjectsIdServicesGemnasium
export def "projects-services-gemnasium put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # Your personal API key on gemnasium.com
  --body-token: string # The project's slug on gemnasium.com
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/gemnasium")
  let body = {api_key: $api_key, token: $body_token, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set hipchat service for project
#
# PUT /v3/projects/{id}/services/hipchat
# operationId: putV3ProjectsIdServicesHipchat
export def "projects-services-hipchat put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The room token
  --room: string # The room name or ID
  --color: string # The room color
  --notify: oneof<nothing, bool> # Enable notifications
  --api-version: string # Leave blank for default (v2)
  --server: string # Leave blank for default. https://hipchat.example.com
  --push-events: string # Event will be triggered by a push to the repository
  --issue-events: string # Event will be triggered when an issue is created/updated/closed
  --confidential-issue-events: string # Event will be triggered when a confidential issue is created/updated/closed
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
  --note-events: string # Event will be triggered when someone adds a comment
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
  --build-events: string # Event will be triggered when a build status changes
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/hipchat")
  let body = {token: $body_token, room: $room, color: $color, notify: $notify, api_version: $api_version, server: $server, push_events: $push_events, issue_events: $issue_events, confidential_issue_events: $confidential_issue_events, merge_request_events: $merge_request_events, note_events: $note_events, tag_push_events: $tag_push_events, build_events: $build_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set irker service for project
#
# PUT /v3/projects/{id}/services/irker
# operationId: putV3ProjectsIdServicesIrker
export def "projects-services-irker put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  recipients: string # Recipients/channels separated by whitespaces
  --default-irc-uri: string # Default: irc://irc.network.net:6697
  --server-host: string # Server host. Default localhost
  --server-port: int # Server port. Default 6659
  --colorize-messages: oneof<nothing, bool> # Colorize messages
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/irker")
  let body = {recipients: $recipients, default_irc_uri: $default_irc_uri, server_host: $server_host, server_port: $server_port, colorize_messages: $colorize_messages, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set jira service for project
#
# PUT /v3/projects/{id}/services/jira
# operationId: putV3ProjectsIdServicesJira
export def "projects-services-jira put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-url: string # The URL to the JIRA project which is being linked to this GitLab project, e.g., https://jira.example.com
  project_key: string # The short identifier for your JIRA project, all uppercase, e.g., PROJ
  --username: string # The username of the user created to be used with GitLab/JIRA
  --password: string # The password of the user created to be used with GitLab/JIRA
  --jira-issue-transition-id: int # The ID of a transition that moves issues to a closed state. You can find this number under the JIRA workflow administration (**Administration > Issues > Workflows**) by selecting **View** under **Operations** of the desired workflow of your project. The ID of each state can be found inside the parenthesis of each transition name under the **Transitions (id)** column ([see screenshot][trans]). By default, this ID is set to `2`
  --commit-events: string # Event will be triggered when a commit is created/updated
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/jira")
  let body = {url: $body_url, project_key: $project_key, username: $username, password: $password, jira_issue_transition_id: $jira_issue_transition_id, commit_events: $commit_events, merge_request_events: $merge_request_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set kubernetes service for project
#
# PUT /v3/projects/{id}/services/kubernetes
# operationId: putV3ProjectsIdServicesKubernetes
export def "projects-services-kubernetes put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  namespace: string # The Kubernetes namespace to use
  api_url: string # The URL to the Kubernetes cluster API, e.g., https://kubernetes.example.com
  --body-token: string # The service token to authenticate against the Kubernetes cluster with
  --ca-pem: string # A custom certificate authority bundle to verify the Kubernetes cluster with (PEM format)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/kubernetes")
  let body = {namespace: $namespace, api_url: $api_url, token: $body_token, ca_pem: $ca_pem} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set mattermost service for project
#
# PUT /v3/projects/{id}/services/mattermost
# operationId: putV3ProjectsIdServicesMattermost
export def "projects-services-mattermost put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook: string # The Mattermost webhook. e.g. http://mattermost_host/hooks/...
  --push-events: string # Event will be triggered by a push to the repository
  --issue-events: string # Event will be triggered when an issue is created/updated/closed
  --confidential-issue-events: string # Event will be triggered when a confidential issue is created/updated/closed
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
  --note-events: string # Event will be triggered when someone adds a comment
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
  --build-events: string # Event will be triggered when a build status changes
  --pipeline-events: string
  --wiki-page-events: string # Event will be triggered when a wiki page is created/updated
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/mattermost")
  let body = {webhook: $webhook, push_events: $push_events, issue_events: $issue_events, confidential_issue_events: $confidential_issue_events, merge_request_events: $merge_request_events, note_events: $note_events, tag_push_events: $tag_push_events, build_events: $build_events, pipeline_events: $pipeline_events, wiki_page_events: $wiki_page_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set mattermost-slash-commands service for project
#
# PUT /v3/projects/{id}/services/mattermost-slash-commands
# operationId: putV3ProjectsIdServicesMattermostSlashCommands
export def "projects-services-mattermost-slash-commands put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The Mattermost token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/mattermost-slash-commands")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Trigger a slash command for mattermost-slash-commands
#
# POST /v3/projects/{id}/services/mattermost_slash_commands/trigger
# operationId: postV3ProjectsIdServicesMattermostSlashCommandsTrigger
export def "projects-services-mattermost-slash-commands-trigger post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The Mattermost token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/mattermost_slash_commands/trigger")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set pipelines-email service for project
#
# PUT /v3/projects/{id}/services/pipelines-email
# operationId: putV3ProjectsIdServicesPipelinesEmail
export def "projects-services-pipelines-email put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  recipients: string # Comma-separated list of recipient email addresses
  --notify-only-broken-builds: oneof<nothing, bool> # Notify only broken builds
  --pipeline-events: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/pipelines-email")
  let body = {recipients: $recipients, notify_only_broken_builds: $notify_only_broken_builds, pipeline_events: $pipeline_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set pivotaltracker service for project
#
# PUT /v3/projects/{id}/services/pivotaltracker
# operationId: putV3ProjectsIdServicesPivotaltracker
export def "projects-services-pivotaltracker put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The Pivotaltracker token
  --restrict-to-branch: string # Comma-separated list of branches which will be automatically inspected. Leave blank to include all branches.
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/pivotaltracker")
  let body = {token: $body_token, restrict_to_branch: $restrict_to_branch, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set pushover service for project
#
# PUT /v3/projects/{id}/services/pushover
# operationId: putV3ProjectsIdServicesPushover
export def "projects-services-pushover put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # The application key
  user_key: string # The user key
  priority: string # The priority
  device: string # Leave blank for all active devices
  sound: string # The sound of the notification
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/pushover")
  let body = {api_key: $api_key, user_key: $user_key, priority: $priority, device: $device, sound: $sound, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set redmine service for project
#
# PUT /v3/projects/{id}/services/redmine
# operationId: putV3ProjectsIdServicesRedmine
export def "projects-services-redmine put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_issue_url: string # The new issue URL
  project_url: string # The project URL
  issues_url: string # The issues URL
  --description: string # The description of the tracker
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/redmine")
  let body = {new_issue_url: $new_issue_url, project_url: $project_url, issues_url: $issues_url, description: $description, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set slack service for project
#
# PUT /v3/projects/{id}/services/slack
# operationId: putV3ProjectsIdServicesSlack
export def "projects-services-slack put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook: string # The Slack webhook. e.g. https://hooks.slack.com/services/...
  --new-issue-url: string # The user name
  --channel: string # The channel name
  --push-events: string # Event will be triggered by a push to the repository
  --issue-events: string # Event will be triggered when an issue is created/updated/closed
  --confidential-issue-events: string # Event will be triggered when a confidential issue is created/updated/closed
  --merge-request-events: string # Event will be triggered when a merge request is created/updated/merged
  --note-events: string # Event will be triggered when someone adds a comment
  --tag-push-events: string # Event will be triggered when a new tag is pushed to the repository
  --build-events: string # Event will be triggered when a build status changes
  --pipeline-events: string
  --wiki-page-events: string # Event will be triggered when a wiki page is created/updated
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/slack")
  let body = {webhook: $webhook, new_issue_url: $new_issue_url, channel: $channel, push_events: $push_events, issue_events: $issue_events, confidential_issue_events: $confidential_issue_events, merge_request_events: $merge_request_events, note_events: $note_events, tag_push_events: $tag_push_events, build_events: $build_events, pipeline_events: $pipeline_events, wiki_page_events: $wiki_page_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set slack-slash-commands service for project
#
# PUT /v3/projects/{id}/services/slack-slash-commands
# operationId: putV3ProjectsIdServicesSlackSlashCommands
export def "projects-services-slack-slash-commands put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The Slack token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/slack-slash-commands")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Trigger a slash command for slack-slash-commands
#
# POST /v3/projects/{id}/services/slack_slash_commands/trigger
# operationId: postV3ProjectsIdServicesSlackSlashCommandsTrigger
export def "projects-services-slack-slash-commands-trigger post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-token: string # The Slack token
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/slack_slash_commands/trigger")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set teamcity service for project
#
# PUT /v3/projects/{id}/services/teamcity
# operationId: putV3ProjectsIdServicesTeamcity
export def "projects-services-teamcity put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  teamcity_url: string # TeamCity root URL like https://teamcity.example.com
  build_type: string # Build configuration ID
  username: string # A user with permissions to trigger a manual build
  password: string # The password of the user
  --push-events: string # Event will be triggered by a push to the repository
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/teamcity")
  let body = {teamcity_url: $teamcity_url, build_type: $build_type, username: $username, password: $password, push_events: $push_events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a service for project
#
# DELETE /v3/projects/{id}/services/{service_slug}
# operationId: deleteV3ProjectsIdServicesServiceSlug
export def "projects-services delete" [
  service_slug: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/($service_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the service settings for project
#
# GET /v3/projects/{id}/services/{service_slug}
# operationId: getV3ProjectsIdServicesServiceSlug
export def "projects-services get" [
  service_slug: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: string, build_events: string, created_at: string, id: string, issues_events: string, merge_requests_events: string, note_events: string, pipeline_events: string, properties: string, push_events: string, tag_push_events: string, title: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/services/($service_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Share the project with a group
#
# POST /v3/projects/{id}/share
# operationId: postV3ProjectsIdShare
export def "projects-share post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  group_id: int # The ID of a group
  group_access: int@group-access-completer # The group access level
  --expires-at: string # Share expiration date
]: any -> record<expires_at: string, group_access: string, group_id: string, id: string, project_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/share")
  let body = {group_id: $group_id, group_access: $group_access, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v3/projects/{id}/share/{group_id}
#
# operationId: deleteV3ProjectsIdShareGroupId
export def "projects-share delete" [
  id: string
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/share/($group_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all project snippets
#
# GET /v3/projects/{id}/snippets
# operationId: getV3ProjectsIdSnippets
export def "projects-snippets list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/snippets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new project snippet
#
# POST /v3/projects/{id}/snippets
# operationId: postV3ProjectsIdSnippets
export def "projects-snippets post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of the snippet
  file_name: string # The file name of the snippet
  code: string # The content of the snippet
  visibility_level: int@visibility-level-completer # The visibility level of the snippet
]: any -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets")
  let body = {title: $title, file_name: $file_name, code: $code, visibility_level: $visibility_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of project +noteable+ notes
#
# GET /v3/projects/{id}/snippets/{noteable_id}/notes
# operationId: getV3ProjectsIdSnippetsNoteableIdNotes
export def "projects-snippets-notes list" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($noteable_id)/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new +noteable+ note
#
# POST /v3/projects/{id}/snippets/{noteable_id}/notes
# operationId: postV3ProjectsIdSnippetsNoteableIdNotes
export def "projects-snippets-notes post" [
  id: string
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # The content of a note
  --created-at: string # The creation date of the note
]: any -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($noteable_id)/notes")
  let body = {body: $body_body, created_at: $created_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +noteable+ note
#
# DELETE /v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}
# operationId: deleteV3ProjectsIdSnippetsNoteableIdNotesNoteId
export def "projects-snippets-notes delete" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($noteable_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single +noteable+ note
#
# GET /v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}
# operationId: getV3ProjectsIdSnippetsNoteableIdNotesNoteId
export def "projects-snippets-notes get" [
  id: string
  note_id: int
  noteable_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($noteable_id)/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing +noteable+ note
#
# PUT /v3/projects/{id}/snippets/{noteable_id}/notes/{note_id}
# operationId: putV3ProjectsIdSnippetsNoteableIdNotesNoteId
export def "projects-snippets-notes put" [
  id: string
  noteable_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-body: string # The content of a note
]: any -> record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($noteable_id)/notes/($note_id)")
  let body = {body: $body_body} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a project snippet
#
# DELETE /v3/projects/{id}/snippets/{snippet_id}
# operationId: deleteV3ProjectsIdSnippetsSnippetId
export def "projects-snippets delete" [
  id: string
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single project snippet
#
# GET /v3/projects/{id}/snippets/{snippet_id}
# operationId: getV3ProjectsIdSnippetsSnippetId
export def "projects-snippets get" [
  id: string
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing project snippet
#
# PUT /v3/projects/{id}/snippets/{snippet_id}
# operationId: putV3ProjectsIdSnippetsSnippetId
export def "projects-snippets put" [
  id: string
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of the snippet
  --file-name: string # The file name of the snippet
  --code: string # The content of the snippet
  --visibility-level: int@visibility-level-completer # The visibility level of the snippet
]: any -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, expires_at: string, file_name: string, id: string, title: string, updated_at: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)")
  let body = {title: $title, file_name: $file_name, code: $code, visibility_level: $visibility_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/snippets/{snippet_id}/award_emoji
# operationId: getV3ProjectsIdSnippetsSnippetIdAwardEmoji
export def "projects-snippets-award-emoji list" [
  id: string
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/award_emoji" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Award a new Emoji
#
# POST /v3/projects/{id}/snippets/{snippet_id}/award_emoji
# operationId: postV3ProjectsIdSnippetsSnippetIdAwardEmoji
export def "projects-snippets-award-emoji post" [
  id: int
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/award_emoji")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/snippets/{snippet_id}/award_emoji/{award_id}
# operationId: deleteV3ProjectsIdSnippetsSnippetIdAwardEmojiAwardId
export def "projects-snippets-award-emoji delete" [
  award_id: int
  id: int
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/snippets/{snippet_id}/award_emoji/{award_id}
# operationId: getV3ProjectsIdSnippetsSnippetIdAwardEmojiAwardId
export def "projects-snippets-award-emoji get" [
  award_id: int
  id: int
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of project +awardable+ award emoji
#
# GET /v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji
# operationId: getV3ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmoji
export def "projects-snippets-notes-award-emoji list" [
  id: int
  snippet_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/notes/($note_id)/award_emoji" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Award a new Emoji
#
# POST /v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji
# operationId: postV3ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmoji
export def "projects-snippets-notes-award-emoji post" [
  id: int
  snippet_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of a award_emoji (without colons)
]: any -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/notes/($note_id)/award_emoji")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a +awardables+ award emoji
#
# DELETE /v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji/{award_id}
# operationId: deleteV3ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmojiAwardId
export def "projects-snippets-notes-award-emoji delete" [
  award_id: int
  id: int
  snippet_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/notes/($note_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific award emoji
#
# GET /v3/projects/{id}/snippets/{snippet_id}/notes/{note_id}/award_emoji/{award_id}
# operationId: getV3ProjectsIdSnippetsSnippetIdNotesNoteIdAwardEmojiAwardId
export def "projects-snippets-notes-award-emoji get" [
  award_id: int
  id: int
  snippet_id: int
  note_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<awardable_id: string, awardable_type: string, created_at: string, id: string, name: string, updated_at: string, user: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/notes/($note_id)/award_emoji/($award_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a raw project snippet
#
# GET /v3/projects/{id}/snippets/{snippet_id}/raw
# operationId: getV3ProjectsIdSnippetsSnippetIdRaw
export def "projects-snippets-raw get" [
  id: string
  snippet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/snippets/($snippet_id)/raw")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unstar a project
#
# DELETE /v3/projects/{id}/star
# operationId: deleteV3ProjectsIdStar
export def "projects-star delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/star")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Star a project
#
# POST /v3/projects/{id}/star
# operationId: postV3ProjectsIdStar
export def "projects-star post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/star")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post status to a commit
#
# POST /v3/projects/{id}/statuses/{sha}
# operationId: postV3ProjectsIdStatusesSha
export def "projects-statuses post" [
  id: string
  sha: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  state: string@state-completer-3 # The state of the status
  --ref: string # The ref
  --target-url: string # The target URL to associate with this status
  --description: string # A short description of the status
  --name: string # A string label to differentiate this status from the status of other systems. Default: "default"
  --context: string # A string label to differentiate this status from the status of other systems. Default: "default"
]: any -> record<allow_failure: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, description: string, finished_at: string, id: string, name: string, ref: string, sha: string, started_at: string, status: string, target_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/statuses/($sha)")
  let body = {state: $state, ref: $ref, target_url: $target_url, description: $description, name: $name, context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get triggers list
#
# GET /v3/projects/{id}/triggers
# operationId: getV3ProjectsIdTriggers
export def "projects-triggers list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/triggers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a trigger
#
# POST /v3/projects/{id}/triggers
# operationId: postV3ProjectsIdTriggers
export def "projects-triggers post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/triggers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a trigger
#
# DELETE /v3/projects/{id}/triggers/{token}
# operationId: deleteV3ProjectsIdTriggersToken
export def "projects-triggers delete" [
  id: string
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/triggers/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get specific trigger of a project
#
# GET /v3/projects/{id}/triggers/{token}
# operationId: getV3ProjectsIdTriggersToken
export def "projects-triggers get" [
  id: string
  token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, deleted_at: string, last_used: string, token: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/triggers/($token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unarchive a project
#
# POST /v3/projects/{id}/unarchive
# operationId: postV3ProjectsIdUnarchive
export def "projects-unarchive post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<archived: string, avatar_url: string, builds_enabled: string, container_registry_enabled: string, created_at: string, creator_id: string, default_branch: string, description: string, forked_from_project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, forks_count: string, http_url_to_repo: string, id: string, issues_enabled: string, last_activity_at: string, lfs_enabled: string, merge_requests_enabled: string, name: string, name_with_namespace: string, namespace: record<id: string, kind: string, name: string, path: string>, only_allow_merge_if_all_discussions_are_resolved: string, only_allow_merge_if_build_succeeds: string, open_issues_count: string, owner: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, path: string, path_with_namespace: string, public: string, public_builds: string, request_access_enabled: string, runners_token: string, shared_runners_enabled: string, shared_with_groups: string, snippets_enabled: string, ssh_url_to_repo: string, star_count: string, statistics: record<build_artifacts_size: string, commit_count: string, lfs_objects_size: string, repository_size: string, storage_size: string>, tag_list: string, visibility_level: string, web_url: string, wiki_enabled: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/unarchive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a file
#
# POST /v3/projects/{id}/uploads
# operationId: postV3ProjectsIdUploads
export def "projects-uploads post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: path # The file to be uploaded
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/uploads")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get the users list of a project
#
# GET /v3/projects/{id}/users
# operationId: getV3ProjectsIdUsers
export def "projects-users get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Return list of users matching the search criteria
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get project variables
#
# GET /v3/projects/{id}/variables
# operationId: getV3ProjectsIdVariables
export def "projects-variables list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/projects/($id)/variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new variable in a project
#
# POST /v3/projects/{id}/variables
# operationId: postV3ProjectsIdVariables
export def "projects-variables post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The key of the variable
  value: string # The value of the variable
]: any -> record<key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/variables")
  let body = {key: $key, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an existing variable from a project
#
# DELETE /v3/projects/{id}/variables/{key}
# operationId: deleteV3ProjectsIdVariablesKey
export def "projects-variables delete" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/variables/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific variable from a project
#
# GET /v3/projects/{id}/variables/{key}
# operationId: getV3ProjectsIdVariablesKey
export def "projects-variables get" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/variables/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing variable from a project
#
# PUT /v3/projects/{id}/variables/{key}
# operationId: putV3ProjectsIdVariablesKey
export def "projects-variables put" [
  id: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --value: string # The value of the variable
]: any -> record<key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/projects/($id)/variables/($key)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get runners available for user
#
# GET /v3/runners
# operationId: getV3Runners
export def "runners list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer-3 # The scope of specific runners to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<active: string, description: string, id: string, is_shared: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/runners" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all runners - shared and specific
#
# GET /v3/runners/all
# operationId: getV3RunnersAll
export def "runners-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer-2 # The scope of specific runners to show
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<active: string, description: string, id: string, is_shared: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/runners/all" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a runner
#
# DELETE /v3/runners/{id}
# operationId: deleteV3RunnersId
export def "runners delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: string, description: string, id: string, is_shared: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/runners/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get runner's details
#
# GET /v3/runners/{id}
# operationId: getV3RunnersId
export def "runners get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: string, architecture: string, contacted_at: string, description: string, id: string, is_shared: string, locked: string, name: string, platform: string, projects: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, revision: string, run_untagged: string, tag_list: string, token: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/runners/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update runner's details
#
# PUT /v3/runners/{id}
# operationId: putV3RunnersId
export def "runners put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # The description of the runner
  --active: oneof<nothing, bool> # The state of a runner
  --tag-list: list # The list of tags for a runner
  --run-untagged: oneof<nothing, bool> # Flag indicating the runner can execute untagged jobs
  --locked: oneof<nothing, bool> # Flag indicating the runner is locked
]: any -> record<active: string, architecture: string, contacted_at: string, description: string, id: string, is_shared: string, locked: string, name: string, platform: string, projects: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, revision: string, run_untagged: string, tag_list: string, token: string, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/runners/($id)")
  let body = {description: $description, active: $active, tag_list: $tag_list, run_untagged: $run_untagged, locked: $locked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Login to get token
#
# POST /v3/session
# operationId: postV3Session
export def "session post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --login: string # The username
  --email: string # The email of the user
  password: string # The password of the user
]: any -> record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, private_token: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/session")
  let body = {login: $login, email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get the Sidekiq Compound metrics. Includes queue, process, and job statistics
#
# GET /v3/sidekiq/compound_metrics
# operationId: getV3SidekiqCompoundMetrics
export def "sidekiq-compound-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/sidekiq/compound_metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Sidekiq job statistics
#
# GET /v3/sidekiq/job_stats
# operationId: getV3SidekiqJobStats
export def "sidekiq-job-stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/sidekiq/job_stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Sidekiq process metrics
#
# GET /v3/sidekiq/process_metrics
# operationId: getV3SidekiqProcessMetrics
export def "sidekiq-process-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/sidekiq/process_metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Sidekiq queue metrics
#
# GET /v3/sidekiq/queue_metrics
# operationId: getV3SidekiqQueueMetrics
export def "sidekiq-queue-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/sidekiq/queue_metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a snippets list for authenticated user
#
# GET /v3/snippets
# operationId: getV3Snippets
export def "snippets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/snippets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new snippet
#
# POST /v3/snippets
# operationId: postV3Snippets
export def "snippets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  title: string # The title of a snippet
  file_name: string # The name of a snippet file
  content: string # The content of a snippet
  --visibility-level: int@visibility-level-completer # The visibility level of the snippet
]: any -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/snippets")
  let body = {title: $title, file_name: $file_name, content: $content, visibility_level: $visibility_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# List all public snippets current_user has access to
#
# GET /v3/snippets/public
# operationId: getV3SnippetsPublic
export def "snippets-public get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/snippets/public" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove snippet
#
# DELETE /v3/snippets/{id}
# operationId: deleteV3SnippetsId
export def "snippets delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/snippets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single snippet
#
# GET /v3/snippets/{id}
# operationId: getV3SnippetsId
export def "snippets get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/snippets/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing snippet
#
# PUT /v3/snippets/{id}
# operationId: putV3SnippetsId
export def "snippets put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of a snippet
  --file-name: string # The name of a snippet file
  --content: string # The content of a snippet
  --visibility-level: int@visibility-level-completer # The visibility level of the snippet
]: any -> record<author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, created_at: string, file_name: string, id: string, raw_url: string, title: string, updated_at: string, web_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/snippets/($id)")
  let body = {title: $title, file_name: $file_name, content: $content, visibility_level: $visibility_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get a raw snippet
#
# GET /v3/snippets/{id}/raw
# operationId: getV3SnippetsIdRaw
export def "snippets-raw get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/snippets/($id)/raw")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the available template
#
# GET /v3/templates/dockerfiles
# operationId: getV3TemplatesDockerfiles
export def "templates-dockerfiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/templates/dockerfiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/templates/dockerfiles/{name}
# operationId: getV3TemplatesDockerfilesName
export def "templates-dockerfiles get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/templates/dockerfiles/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the available template
#
# GET /v3/templates/gitignores
# operationId: getV3TemplatesGitignores
export def "templates-gitignores list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/templates/gitignores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/templates/gitignores/{name}
# operationId: getV3TemplatesGitignoresName
export def "templates-gitignores get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/templates/gitignores/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the available template
#
# GET /v3/templates/gitlab_ci_ymls
# operationId: getV3TemplatesGitlabCiYmls
export def "templates-gitlab-ci-ymls list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/templates/gitlab_ci_ymls")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the text for a specific template present in local filesystem
#
# GET /v3/templates/gitlab_ci_ymls/{name}
# operationId: getV3TemplatesGitlabCiYmlsName
export def "templates-gitlab-ci-ymls get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/templates/gitlab_ci_ymls/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of the available license template
#
# GET /v3/templates/licenses
# operationId: getV3TemplatesLicenses
export def "templates-licenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --popular: oneof<nothing, bool> # If passed, returns only popular licenses
]: nothing -> record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "popular" $popular "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/templates/licenses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the text for a specific license
#
# GET /v3/templates/licenses/{name}
# operationId: getV3TemplatesLicensesName
export def "templates-licenses get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<conditions: string, content: string, description: string, html_url: string, key: string, limitations: string, name: string, nickname: string, permissions: string, popular: string, source_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/templates/licenses/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark all todos as done
#
# DELETE /v3/todos
# operationId: deleteV3Todos
export def "todos delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/todos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a todo list
#
# GET /v3/todos
# operationId: getV3Todos
export def "todos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/todos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark a todo as done
#
# DELETE /v3/todos/{id}
# operationId: deleteV3TodosId
export def "todos delete-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, id: string, project: record<http_url_to_repo: string, id: string, name: string, name_with_namespace: string, path: string, path_with_namespace: string, web_url: string>, state: string, target: string, target_type: string, target_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/todos/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the currently authenticated user
#
# GET /v3/user
# operationId: getV3User
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the currently authenticated user's email addresses
#
# GET /v3/user/emails
# operationId: getV3UserEmails
export def "user-emails list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/user/emails")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new email address to the currently authenticated user
#
# POST /v3/user/emails
# operationId: postV3UserEmails
export def "user-emails post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The new email
]: any -> record<email: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/user/emails")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an email address from the currently authenticated user
#
# DELETE /v3/user/emails/{email_id}
# operationId: deleteV3UserEmailsEmailId
export def "user-emails delete" [
  email_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/user/emails/($email_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single email address owned by the currently authenticated user
#
# GET /v3/user/emails/{email_id}
# operationId: getV3UserEmailsEmailId
export def "user-emails get" [
  email_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/user/emails/($email_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the currently authenticated user's SSH keys
#
# GET /v3/user/keys
# operationId: getV3UserKeys
export def "user-keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/user/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new SSH key to the currently authenticated user
#
# POST /v3/user/keys
# operationId: postV3UserKeys
export def "user-keys post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The new SSH key
  title: string # The title of the new SSH key
]: any -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/user/keys")
  let body = {key: $key, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an SSH key from the currently authenticated user
#
# DELETE /v3/user/keys/{key_id}
# operationId: deleteV3UserKeysKeyId
export def "user-keys delete" [
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/user/keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single key owned by currently authenticated user
#
# GET /v3/user/keys/{key_id}
# operationId: getV3UserKeysKeyId
export def "user-keys get" [
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/user/keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of users
#
# GET /v3/users
# operationId: getV3Users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --username: string # Get a single user with a specific username
  --search: string # Search for a username
  --active: oneof<nothing, bool> # Filters only active users
  --external: oneof<nothing, bool> # Filters only external users
  --blocked: oneof<nothing, bool> # Filters only blocked users
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "username" $username "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "external" $external "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a user. Available only for admins.
#
# POST /v3/users
# operationId: postV3Users
export def "users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email of the user
  password: string # The password of the new user
  name: string # The name of the user
  username: string # The username of the user
  --skype: string # The Skype username
  --linkedin: string # The LinkedIn username
  --twitter: string # The Twitter username
  --website-url: string # The website of the user
  --organization: string # The organization of the user
  --projects-limit: int # The number of projects a user can create
  --extern-uid: string # The external authentication provider UID
  --provider: string # The external provider
  --bio: string # The biography of the user
  --location: string # The location of the user
  --admin: oneof<nothing, bool> # Flag indicating the user is an administrator
  --can-create-group: oneof<nothing, bool> # Flag indicating the user can create groups
  --confirm: oneof<nothing, bool> # Flag indicating the account needs to be confirmed
  --external: oneof<nothing, bool> # Flag indicating the user is an external user
]: any -> record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/users")
  let body = {email: $email, password: $password, name: $name, username: $username, skype: $skype, linkedin: $linkedin, twitter: $twitter, website_url: $website_url, organization: $organization, projects_limit: $projects_limit, extern_uid: $extern_uid, provider: $provider, bio: $bio, location: $location, admin: $admin, can_create_group: $can_create_group, confirm: $confirm, external: $external} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a user. Available only for admins.
#
# DELETE /v3/users/{id}
# operationId: deleteV3UsersId
export def "users delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single user
#
# GET /v3/users/{id}
# operationId: getV3UsersId
export def "users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user. Available only for admins.
#
# PUT /v3/users/{id}
# operationId: putV3UsersId
export def "users put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # The email of the user
  --password: string # The password of the new user
  --name: string # The name of the user
  --username: string # The username of the user
  --skype: string # The Skype username
  --linkedin: string # The LinkedIn username
  --twitter: string # The Twitter username
  --website-url: string # The website of the user
  --organization: string # The organization of the user
  --projects-limit: int # The number of projects a user can create
  --extern-uid: string # The external authentication provider UID
  --provider: string # The external provider
  --bio: string # The biography of the user
  --location: string # The location of the user
  --admin: oneof<nothing, bool> # Flag indicating the user is an administrator
  --can-create-group: oneof<nothing, bool> # Flag indicating the user can create groups
  --confirm: oneof<nothing, bool> # Flag indicating the account needs to be confirmed
  --external: oneof<nothing, bool> # Flag indicating the user is an external user
]: any -> record<avatar_url: string, bio: string, can_create_group: string, can_create_project: string, color_scheme_id: string, confirmed_at: string, created_at: string, current_sign_in_at: string, email: string, external: string, id: string, identities: record<extern_uid: string, provider: string>, is_admin: string, last_sign_in_at: string, linkedin: string, location: string, name: string, organization: string, projects_limit: string, skype: string, state: string, theme_id: string, twitter: string, two_factor_enabled: string, username: string, web_url: string, website_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)")
  let body = {email: $email, password: $password, name: $name, username: $username, skype: $skype, linkedin: $linkedin, twitter: $twitter, website_url: $website_url, organization: $organization, projects_limit: $projects_limit, extern_uid: $extern_uid, provider: $provider, bio: $bio, location: $location, admin: $admin, can_create_group: $can_create_group, confirm: $confirm, external: $external} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Block a user. Available only for admins.
#
# PUT /v3/users/{id}/block
# operationId: putV3UsersIdBlock
export def "users-block put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)/block")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the emails addresses of a specified user. Available only for admins.
#
# GET /v3/users/{id}/emails
# operationId: getV3UsersIdEmails
export def "users-emails get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)/emails")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an email address to a specified user. Available only for admins.
#
# POST /v3/users/{id}/emails
# operationId: postV3UsersIdEmails
export def "users-emails post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # The email of the user
]: any -> record<email: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)/emails")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an email address of a specified user. Available only for admins.
#
# DELETE /v3/users/{id}/emails/{email_id}
# operationId: deleteV3UsersIdEmailsEmailId
export def "users-emails delete" [
  id: int
  email_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)/emails/($email_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the contribution events of a specified user
#
# GET /v3/users/{id}/events
# operationId: getV3UsersIdEvents
export def "users-events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Current page number (format: int32)
  --per-page: int # Number of items per page (format: int32)
]: nothing -> record<action_name: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, author_id: string, author_username: string, created_at: string, data: string, note: record<attachment: string, author: record<avatar_url: string, id: string, name: string, state: string, username: string, web_url: string>, body: string, created_at: string, downvote_: string, id: string, noteable_id: string, noteable_type: string, system: string, updated_at: string, upvote_: string>, project_id: string, target_id: string, target_title: string, target_type: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v3/users/($id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the SSH keys of a specified user. Available only for admins.
#
# GET /v3/users/{id}/keys
# operationId: getV3UsersIdKeys
export def "users-keys get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an SSH key to a specified user. Available only for admins.
#
# POST /v3/users/{id}/keys
# operationId: postV3UsersIdKeys
export def "users-keys post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  key: string # The new SSH key
  title: string # The title of the new SSH key
]: any -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)/keys")
  let body = {key: $key, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete an existing SSH key from a specified user. Available only for admins.
#
# DELETE /v3/users/{id}/keys/{key_id}
# operationId: deleteV3UsersIdKeysKeyId
export def "users-keys delete" [
  id: int
  key_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<can_push: string, created_at: string, id: string, key: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)/keys/($key_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unblock a user. Available only for admins.
#
# PUT /v3/users/{id}/unblock
# operationId: putV3UsersIdUnblock
export def "users-unblock put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v3/users/($id)/unblock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the version information of the GitLab instance.
#
# GET /v3/version
# operationId: getV3Version
export def "version get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "private_header"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v3/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
