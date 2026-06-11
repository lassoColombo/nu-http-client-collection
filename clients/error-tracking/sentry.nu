# Auto-generated client for API Reference vv0
# Source: https://raw.githubusercontent.com/getsentry/sentry-api-schema/main/openapi-derefed.json
# Auth: --token flag or $env.API_REFERENCE_TOKEN

const BASE_URL = "https://us.sentry.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_REFERENCE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "dsn" => { {headers: {Authorization: $"Dsn ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://us.sentry.io" "https://de.sentry.io" "https://{region}.sentry.io"] }
def auth-scheme-completer [] { ["bearer" "dsn"] }

# Completers for enum parameters
def defaultRole-completer [] { ["admin" "manager" "member" "owner"] }
def attachmentsRole-completer [] { ["admin" "manager" "member" "owner"] }
def debugFilesRole-completer [] { ["admin" "manager" "member" "owner"] }
def avatarType-completer [] { ["letter_avatar" "upload"] }
def storeCrashReports-completer [] { ["-1" "0" "1" "10" "100" "20" "5" "50"] }
def queryDataset-completer [] { ["discover" "error-events" "transaction-like"] }
def visibility-completer [] { ["all" "hidden" "visible"] }
def dataset-completer [] { ["errors" "logs" "profile_functions" "spans" "tracemetrics" "uptime_results"] }
def disableAggregateExtrapolation-completer [] { ["0" "1"] }
def preventMetricAggregates-completer [] { ["0" "1"] }
def excludeOther-completer [] { ["0" "1"] }
def provider-completer [] { ["custom_scm" "github" "github_enterprise" "gitlab" "jira_server" "msteams" "perforce" "slack" "slack_staging"] }
def provider-completer-1 [] { ["segment" "splunk" "sqs"] }
def groupStatsPeriod-completer [] { ["" "14d" "24h" "auto"] }
def shortIdLookup-completer [] { ["0" "1"] }
def sort-completer [] { ["date" "freq" "inbox" "new" "recommended" "trends" "user"] }
def status-completer [] { ["ignored" "muted" "resolved" "resolvedInNextRelease" "unresolved"] }
def substatus-completer [] { ["archived_forever" "archived_until_condition_met" "archived_until_escalating" "escalating" "new" "ongoing" "regressed"] }
def priority-completer [] { ["high" "low" "medium"] }
def orgRole-completer [] { ["admin" "billing" "manager" "member" "owner"] }
def teamRole-completer [] { ["admin" "contributor"] }
def status-completer-1 [] { ["active" "disabled"] }
def dataSource-completer [] { ["functions" "profiles" "spans" "transactions"] }
def status-completer-2 [] { ["active" "inactive"] }
def summaryStatsPeriod-completer [] { ["14d" "1d" "1h" "24h" "2d" "30d" "48h" "7d" "90d"] }
def healthStatsPeriod-completer [] { ["14d" "1d" "1h" "24h" "2d" "30d" "48h" "7d" "90d"] }
def sort-completer-1 [] { ["crash_free_sessions" "crash_free_users" "date" "sessions" "users"] }
def status-completer-3 [] { ["archived" "open"] }
def data-source-completer [] { ["discover" "events" "search_issues" "transactions"] }
def status-completer-4 [] { ["active" "deleted"] }
def sentryOrgRole-completer [] { ["admin" "billing" "manager" "member"] }
def field-completer [] { ["sum(quantity)" "sum(times_seen)"] }
def category-completer [] { ["attachment" "error" "profiles" "replays" "transaction"] }
def outcome-completer [] { ["abuse" "accepted" "cardinality_limited" "client_discard" "filtered" "invalid" "rate_limited"] }
def category-completer-1 [] { ["attachment" "error" "monitor" "profile" "profile_chunk" "profile_chunk_ui" "profile_duration" "profile_duration_ui" "replay" "transaction"] }
def dataset-completer-1 [] { ["discover" "events" "replays" "search_issues"] }
def use-cache-completer [] { ["0" "1"] }
def useFlagsBackend-completer [] { ["0" "1"] }
def dataset-completer-2 [] { ["logs" "preprod" "processing_errors" "spans" "tracemetrics"] }
def itemType-completer [] { ["logs" "preprod" "processing_errors" "spans" "tracemetrics"] }
def include-uptime-completer [] { ["0" "1"] }
def useCase-completer [] { ["demo" "profiling" "tempest" "user"] }
def browserSdkVersion-completer [] { ["7.x" "latest"] }
def stat-completer [] { ["blacklisted" "generated" "received" "rejected"] }
def resolution-completer [] { ["10s" "1d" "1h"] }
def type-completer [] { ["gcs" "http" "s3"] }
def region-completer [] { ["ap-east-1" "ap-northeast-1" "ap-northeast-2" "ap-south-1" "ap-southeast-1" "ap-southeast-2" "ca-central-1" "cn-north-1" "cn-northwest-1" "eu-central-1" "eu-north-1" "eu-west-1" "eu-west-2" "eu-west-3" "sa-east-1" "us-east-1" "us-east-2" "us-gov-east-1" "us-gov-west-1" "us-west-1" "us-west-2"] }
def sort-completer-2 [] { ["age" "count" "date" "id"] }
def step-completer [] { ["code_changes" "coding_agent_handoff" "open_pr" "root_cause" "solution"] }
def stopping-point-completer [] { ["code_changes" "open_pr" "root_cause" "solution"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "0-organizations List-Your-Organizations" } } | get name | first)
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

# Return a list of organizations available to the authenticated session in a region. This is particularly useful for requests with a user bound context. For API key-based requests this will only return the organization that belongs to the key.
#
# GET /api/0/organizations/
# operationId: List Your Organizations
export def "0-organizations List-Your-Organizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string@bool-completer # Specify `true` to restrict results to organizations in which you are an owner.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --qp-query: string # Filters results by using [query syntax](/product/sentry-basics/search/).  Valid query fields include: - `id`: The organization ID - `slug`: The organization slug - `status`: The organization's current status (one of `active`, `pending_deletion`, or `deletion_in_progress`) - `email` or `member_id`: Filter your organizations by the emails or [organization member IDs](/api/organizations/list-an-organizations-members/) of specific members included - `query`: Filter your organizations by name, slug, and members that contain this substring  Example: `query=(slug:foo AND status:active) OR (email:[thing-one@example.com,thing-two@example.com] AND query:bar)`
  --sortBy: string # The field to sort results by, in descending order. If not specified the results are sorted by the date they were created.  Valid fields include: - `members`: By number of members - `events`: By number of events in the past 24 hours
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
]: nothing -> table<features: list<string>, extraOptions: record, access: list<string>, onboardingTasks: list<record>, id: string, slug: string, status: record<id: string, name: string>, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, links: record<organizationUrl: string, regionUrl: string>, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/0/organizations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return details on an individual organization, including various details such as membership access and teams.
#
# GET /api/0/organizations/{organization_id_or_slug}/
# operationId: Retrieve an Organization
export def "0-organizations Retrieve-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailed: string #  Specify `"0"` to return organization details that do not include projects or teams.
]: nothing -> record<features: list<string>, extraOptions: record, access: list<string>, onboardingTasks: table<task: string, status: string, completionSeen: string, dateCompleted: string, data: any>, id: string, slug: string, status: record<id: string, name: string>, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, links: record<organizationUrl: string, regionUrl: string>, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update various attributes and configurable settings for the given organization.
#
# PUT /api/0/organizations/{organization_id_or_slug}/
# operationId: Update an Organization
export def "0-organizations Update-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # The new slug for the organization, which needs to be unique.
  --name: string # The new name for the organization.
  --isEarlyAdopter: string@bool-completer # Specify `true` to opt-in to new features before they're released to the public.
  --hideAiFeatures: string@bool-completer # Specify `true` to hide AI features from the organization.
  --defaultRole: string@defaultRole-completer # The default role new members will receive.  * `member` - Member * `admin` - Admin * `manager` - Manager * `owner` - Owner
  --openMembership: string@bool-completer # Specify `true` to allow organization members to freely join any team.
  --eventsMemberAdmin: string@bool-completer # Specify `true` to allow members to delete events (including the delete & discard action) by granting them the `event:admin` scope.
  --alertsMemberWrite: string@bool-completer # Specify `true` to allow members to create, edit, and delete alert rules by granting them the `alerts:write` scope.
  --attachmentsRole: string@attachmentsRole-completer # The role required to download event attachments, such as native crash reports or log files.  * `member` - Member * `admin` - Admin * `manager` - Manager * `owner` - Owner
  --debugFilesRole: string@debugFilesRole-completer # The role required to download debug information files, ProGuard mappings and source maps.  * `member` - Member * `admin` - Admin * `manager` - Manager * `owner` - Owner
  --hasGranularReplayPermissions: string@bool-completer # Specify `true` to enable granular replay permissions, allowing per-member access control for replay data.
  --replayAccessMembers: list # A list of user IDs who have permission to access replay data. Requires the hasGranularReplayPermissions flag to be true to be enforced. (nullable)
  --avatarType: string@avatarType-completer # The type of display picture for the organization.  * `letter_avatar` - Use initials * `upload` - Upload an image
  --avatar: string # The image to upload as the organization avatar, in base64. Required if `avatarType` is `upload`.
  --require2FA: string@bool-completer # Specify `true` to require and enforce two-factor authentication for all members.
  --allowSharedIssues: string@bool-completer # Specify `true` to allow sharing of limited details on issues to anonymous users.
  --enhancedPrivacy: string@bool-completer # Specify `true` to enable enhanced privacy controls to limit personally identifiable information (PII) as well as source code in things like notifications.
  --scrapeJavaScript: string@bool-completer # Specify `true` to allow Sentry to scrape missing JavaScript source context when possible.
  --storeCrashReports: int@storeCrashReports-completer # How many native crash reports (such as Minidumps for improved processing and download in issue details) to store per issue.  * `0` - Disabled * `1` - 1 per issue * `5` - 5 per issue * `10` - 10 per issue * `20` - 20 per issue * `50` - 50 per issue * `100` - 100 per issue * `-1` - Unlimited
  --allowJoinRequests: string@bool-completer # Specify `true` to allow users to request to join your organization.
  --dataScrubber: string@bool-completer # Specify `true` to require server-side data scrubbing for all projects.
  --dataScrubberDefaults: string@bool-completer # Specify `true` to apply the default scrubbers to prevent things like passwords and credit cards from being stored for all projects.
  --sensitiveFields: list # A list of additional global field names to match against when scrubbing data for all projects.
  --safeFields: list # A list of global field names which data scrubbers should ignore.
  --scrubIPAddresses: string@bool-completer # Specify `true` to prevent IP addresses from being stored for new events on all projects.
  --relayPiiConfig: string # Advanced data scrubbing rules that can be configured for each project as a JSON string. The new rules will only apply to new incoming events. For more details on advanced data scrubbing, see our [full documentation](/security-legal-pii/scrubbing/advanced-datascrubbing/).  > Warning: Calling this endpoint with this field fully overwrites the advanced data scrubbing rules.  Below is an example of a payload for a set of advanced data scrubbing rules for masking credit card numbers from the log message (equivalent to `[Mask] [Credit card numbers] from [$message]` in the Sentry app) and removing a specific key called `foo` (equivalent to `[Remove] [Anything] from [extra.foo]` in the Sentry app): ```json {     relayPiiConfig: "{\"rules":{\"0\":{\"type\":\"creditcard\",\"redaction\":{\"method\":\"mask\"}},\"1\":{\"type\":\"anything\",\"redaction\":{\"method\":\"remove\"}}},\"applications\":{\"$message\":[\"0\"],\"extra.foo\":[\"1\"]}}" } ```         
  --trustedRelays: list # A list of local Relays (the name, public key, and description as a JSON) registered for the organization. This feature is only available for organizations on the Business and Enterprise plans. Read more about Relay [here](/product/relay/).                                            Below is an example of a list containing a single local Relay registered for the organization:                                           ```json                                           {                                             trustedRelays: [                                                 {                                                     name: "my-relay",                                                     publicKey: "eiwr9fdruw4erfh892qy4493reyf89ur34wefd90h",                                                     description: "Configuration for my-relay."                                                 }                                             ]                                           }                                           ```                                           
  --issueAlertsThreadFlag: string@bool-completer # Specify `true` to allow the Sentry Slack integration to post replies in threads for an Issue Alert notification. Requires a Slack integration.
  --metricAlertsThreadFlag: string@bool-completer # Specify `true` to allow the Sentry Slack integration to post replies in threads for a Metric Alert notification. Requires a Slack integration.
  --cancelDeletion: string@bool-completer # Specify `true` to restore an organization that is pending deletion.
]: any -> record<features: list<string>, extraOptions: record, access: list<string>, onboardingTasks: table<task: string, status: string, completionSeen: string, dateCompleted: string, data: any>, id: string, slug: string, status: record<id: string, name: string>, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, links: record<organizationUrl: string, regionUrl: string>, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool, role: any, orgRole: string, targetSampleRate: float, samplingMode: string, planSampleRate: float, desiredSampleRate: float, experiments: record, isDefault: bool, defaultRole: string, orgRoleList: table<id: string, name: string, desc: string, scopes: list, allowed: bool, isAllowed: bool, isRetired: bool, isTeamRolesAllowed: bool, is_global: bool, isGlobal: bool, minimumTeamRole: string>, teamRoleList: table<id: string, name: string, desc: string, scopes: list, allowed: bool, isAllowed: bool, isRetired: bool, isTeamRolesAllowed: bool, isMinimumRoleFor: string>, openMembership: bool, allowSharedIssues: bool, enhancedPrivacy: bool, dataScrubber: bool, dataScrubberDefaults: bool, sensitiveFields: list<string>, safeFields: list<string>, storeCrashReports: int, attachmentsRole: string, debugFilesRole: string, eventsMemberAdmin: bool, alertsMemberWrite: bool, scrubIPAddresses: bool, scrapeJavaScript: bool, allowJoinRequests: bool, relayPiiConfig: string, trustedRelays: table<name: string, description: string, publicKey: string, created: string, lastModified: string>, pendingAccessRequests: int, hideAiFeatures: bool, aggregatedDataConsent: bool, isDynamicallySampled: bool, issueAlertsThreadFlag: bool, metricAlertsThreadFlag: bool, requiresSso: bool, defaultAutofixAutomationTuning: string, defaultSeerScannerAutomation: bool, enableSeerCoding: bool, defaultCodingAgent: string, defaultCodingAgentIntegrationId: string, defaultAutomatedRunStoppingPoint: string, autoEnableCodeReview: bool, autoOpenPrs: bool, defaultCodeReviewTriggers: list<string>, teams: table<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list, hasAccess: bool, isPending: bool, memberCount: int, avatar: record, externalTeams: list, organization: record, projects: list>, projects: table<latestDeploys: record, options: record, stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list, firstEvent: string, firstTransactionEvent: bool, access: list, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, team: record, teams: list, platforms: list, hasUserReports: bool, environments: list, latestRelease: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/")
  let body = {slug: $slug, name: $name, isEarlyAdopter: $isEarlyAdopter, hideAiFeatures: $hideAiFeatures, defaultRole: $defaultRole, openMembership: $openMembership, eventsMemberAdmin: $eventsMemberAdmin, alertsMemberWrite: $alertsMemberWrite, attachmentsRole: $attachmentsRole, debugFilesRole: $debugFilesRole, hasGranularReplayPermissions: $hasGranularReplayPermissions, replayAccessMembers: $replayAccessMembers, avatarType: $avatarType, avatar: $avatar, require2FA: $require2FA, allowSharedIssues: $allowSharedIssues, enhancedPrivacy: $enhancedPrivacy, scrapeJavaScript: $scrapeJavaScript, storeCrashReports: $storeCrashReports, allowJoinRequests: $allowJoinRequests, dataScrubber: $dataScrubber, dataScrubberDefaults: $dataScrubberDefaults, sensitiveFields: $sensitiveFields, safeFields: $safeFields, scrubIPAddresses: $scrubIPAddresses, relayPiiConfig: $relayPiiConfig, trustedRelays: $trustedRelays, issueAlertsThreadFlag: $issueAlertsThreadFlag, metricAlertsThreadFlag: $metricAlertsThreadFlag, cancelDeletion: $cancelDeletion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get integration provider information about all available integrations for an organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/config/integrations/
# operationId: Get Integration Provider Information
export def "0-organizations-config-integrations Get-Integration-Provider-Information" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --providerKey: string # Specific integration provider to filter by such as `slack`. See our [Integrations Documentation](/product/integrations/) for an updated list of providers.
]: nothing -> record<providers: table<key: string, slug: string, name: string, metadata: any, canAdd: bool, canDisable: bool, features: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "providerKey" $providerKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/config/integrations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an Organization's Custom Dashboards
#
# GET /api/0/organizations/{organization_id_or_slug}/dashboards/
# operationId: listOrganizationDashboards
export def "0-organizations-dashboards listOrganizationDashboards" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, title: string, dateCreated: string, createdBy: record<identities: list, avatar: record, authenticators: list, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list>, environment: list<string>, filters: record<release: list, releaseId: list, globalFilter: list>, lastVisited: string, widgetDisplay: list<string>, widgetPreview: list<record>, permissions: record<isEditableByEveryone: bool, teamsWithEditAccess: list>, isFavorited: bool, projects: list<int>, prebuiltId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/dashboards/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a New Dashboard for an Organization
#
# POST /api/0/organizations/{organization_id_or_slug}/dashboards/
# operationId: createOrganizationDashboard
# --widgets item shape: {id?: string, title?: string, description?: string, thresholds?: record, display_type?: "line"|"area"|"bar"|"table"|"big_number"|"details"|"categorical_bar"|"wheel"|"rage_and_dead_clicks"|"server_tree"|"text"|"agents_traces_table", interval?: string, queries?: list, widget_type?: "discover"|"issue"|"metrics"|"error-events"|"transaction-like"|"spans"|"logs"|"tracemetrics"|"preprod-app-size", limit?: int, layout?: any, axis_range?: "auto"|"dataMin", legend_type?: "default"|"breakdown"}
export def "0-organizations-dashboards createOrganizationDashboard" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  title: string # The user defined title for this dashboard.
  --id: string # A dashboard's unique id.
  --widgets: list # A json list of widgets saved in this dashboard. — item shape: {id?: string, title?: string, description?: string, thresholds?: record, display_type?: "line"|"area"|"bar"|"table"|"big_number"|"details"|"categorical_bar"|"wheel"|"rage_and_dead_clicks"|"server_tree"|"text"|"agents_traces_table", interval?: string, queries?: list, widget_type?: "discover"|"issue"|"metrics"|"error-events"|"transaction-like"|"spans"|"logs"|"tracemetrics"|"preprod-app-size", limit?: int, layout?: any, axis_range?: "auto"|"dataMin", legend_type?: "default"|"breakdown"}
  --projects: list # The saved projects filter for this dashboard.
  --environment: list # The saved environment filter for this dashboard. (nullable)
  --period: string # The saved time range period for this dashboard. (nullable)
  --start: string # The saved start time for this dashboard. (nullable, format: date-time)
  --end: string # The saved end time for this dashboard. (nullable, format: date-time)
  --filters: record # The saved filters for this dashboard.
  --utc: string@bool-completer # Setting that lets you display saved time range for this dashboard in UTC.
  --permissions: any # Permissions that restrict users from editing dashboards (nullable)
  --is-favorited: string@bool-completer # Favorite the dashboard automatically for the request user (default: false)
]: any -> record<environment: list<string>, period: string, utc: string, expired: bool, start: string, end: string, id: string, title: string, dateCreated: string, createdBy: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>, widgets: table<id: string, title: string, description: string, displayType: string, thresholds: record, interval: string, dateCreated: string, dashboardId: string, queries: list, limit: int, widgetType: string, layout: record, axisRange: string, legendType: string, datasetSource: string, exploreUrls: list, changedReason: list>, projects: list<int>, filters: record<release: list<string>, releaseId: list<string>, globalFilter: list<record>>, permissions: record<isEditableByEveryone: bool, teamsWithEditAccess: list<int>>, isFavorited: bool, prebuiltId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/dashboards/")
  let body = {title: $title, id: $id, widgets: $widgets, projects: $projects, environment: $environment, period: $period, start: $start, end: $end, filters: $filters, utc: $utc, permissions: $permissions, is_favorited: $is_favorited} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an Organization's Custom Dashboard
#
# GET /api/0/organizations/{organization_id_or_slug}/dashboards/{dashboard_id}/
# operationId: getOrganizationDashboard
export def "0-organizations-dashboards get" [
  organization_id_or_slug: string
  dashboard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<environment: list<string>, period: string, utc: string, expired: bool, start: string, end: string, id: string, title: string, dateCreated: string, createdBy: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>, widgets: table<id: string, title: string, description: string, displayType: string, thresholds: record, interval: string, dateCreated: string, dashboardId: string, queries: list, limit: int, widgetType: string, layout: record, axisRange: string, legendType: string, datasetSource: string, exploreUrls: list, changedReason: list>, projects: list<int>, filters: record<release: list<string>, releaseId: list<string>, globalFilter: list<record>>, permissions: record<isEditableByEveryone: bool, teamsWithEditAccess: list<int>>, isFavorited: bool, prebuiltId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/dashboards/($dashboard_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an Organization's Custom Dashboard
#
# PUT /api/0/organizations/{organization_id_or_slug}/dashboards/{dashboard_id}/
# operationId: updateOrganizationDashboard
# --widgets item shape: {id?: string, title?: string, description?: string, thresholds?: record, display_type?: "line"|"area"|"bar"|"table"|"big_number"|"details"|"categorical_bar"|"wheel"|"rage_and_dead_clicks"|"server_tree"|"text"|"agents_traces_table", interval?: string, queries?: list, widget_type?: "discover"|"issue"|"metrics"|"error-events"|"transaction-like"|"spans"|"logs"|"tracemetrics"|"preprod-app-size", limit?: int, layout?: any, axis_range?: "auto"|"dataMin", legend_type?: "default"|"breakdown"}
export def "0-organizations-dashboards updateOrganizationDashboard" [
  organization_id_or_slug: string
  dashboard_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # A dashboard's unique id.
  --title: string # The user-defined dashboard title.
  --widgets: list # A json list of widgets saved in this dashboard. — item shape: {id?: string, title?: string, description?: string, thresholds?: record, display_type?: "line"|"area"|"bar"|"table"|"big_number"|"details"|"categorical_bar"|"wheel"|"rage_and_dead_clicks"|"server_tree"|"text"|"agents_traces_table", interval?: string, queries?: list, widget_type?: "discover"|"issue"|"metrics"|"error-events"|"transaction-like"|"spans"|"logs"|"tracemetrics"|"preprod-app-size", limit?: int, layout?: any, axis_range?: "auto"|"dataMin", legend_type?: "default"|"breakdown"}
  --projects: list # The saved projects filter for this dashboard.
  --environment: list # The saved environment filter for this dashboard. (nullable)
  --period: string # The saved time range period for this dashboard. (nullable)
  --start: string # The saved start time for this dashboard. (nullable, format: date-time)
  --end: string # The saved end time for this dashboard. (nullable, format: date-time)
  --filters: record # The saved filters for this dashboard.
  --utc: string@bool-completer # Setting that lets you display saved time range for this dashboard in UTC.
  --permissions: any # Permissions that restrict users from editing dashboards (nullable)
]: any -> record<environment: list<string>, period: string, utc: string, expired: bool, start: string, end: string, id: string, title: string, dateCreated: string, createdBy: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>, widgets: table<id: string, title: string, description: string, displayType: string, thresholds: record, interval: string, dateCreated: string, dashboardId: string, queries: list, limit: int, widgetType: string, layout: record, axisRange: string, legendType: string, datasetSource: string, exploreUrls: list, changedReason: list>, projects: list<int>, filters: record<release: list<string>, releaseId: list<string>, globalFilter: list<record>>, permissions: record<isEditableByEveryone: bool, teamsWithEditAccess: list<int>>, isFavorited: bool, prebuiltId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/dashboards/($dashboard_id)/")
  let body = {id: $id, title: $title, widgets: $widgets, projects: $projects, environment: $environment, period: $period, start: $start, end: $end, filters: $filters, utc: $utc, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Organization's Custom Dashboard
#
# DELETE /api/0/organizations/{organization_id_or_slug}/dashboards/{dashboard_id}/
# operationId: deleteOrganizationDashboard
export def "0-organizations-dashboards delete" [
  organization_id_or_slug: string
  dashboard_id: int
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/dashboards/($dashboard_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an Organization's Monitors
#
# GET /api/0/organizations/{organization_id_or_slug}/detectors/
# operationId: Fetch an Organization's Monitors
export def "0-organizations-detectors Fetch-an-Organizations-Monitors" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --qp-query: string # An optional search query for filtering monitors.  Available fields are: - `name` - `type`: e.g. `error`, `metric_issue`, `issue_stream` - `assignee`: email, username, #team, me, none         
  --sortBy: string # The property to sort results by. If not specified, the results are sorted by id.  Available fields are: - `name` - `id` - `type` - `connectedWorkflows` - `latestGroup` - `openIssues`  Prefix with `-` to sort in descending order.         
  --id: list # The ID of the monitor you'd like to query.
]: nothing -> table<owner: record<type: string, id: string, name: string, email: string>, createdBy: string, latestGroup: record, description: string, id: string, projectId: string, name: string, type: string, workflowIds: list<string>, dateCreated: string, dateUpdated: string, dataSources: list<record>, conditionGroup: record, config: record, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/detectors/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk enable or disable an Organization's Monitors
#
# PUT /api/0/organizations/{organization_id_or_slug}/detectors/
# operationId: Mutate an Organization's Monitors
export def "0-organizations-detectors Mutate-an-Organizations-Monitors" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --qp-query: string # An optional search query for filtering monitors.  Available fields are: - `name` - `type`: e.g. `error`, `metric_issue`, `issue_stream` - `assignee`: email, username, #team, me, none         
  --id: list # The ID of the monitor you'd like to query.
  --enabled: string@bool-completer # Whether to enable or disable the monitors
]: any -> table<owner: record<type: string, id: string, name: string, email: string>, createdBy: string, latestGroup: record, description: string, id: string, projectId: string, name: string, type: string, workflowIds: list<string>, dateCreated: string, dateUpdated: string, dataSources: list<record>, conditionGroup: record, config: record, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/detectors/" $qp)
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete Monitors for a given organization
#
# DELETE /api/0/organizations/{organization_id_or_slug}/detectors/
# operationId: Bulk Delete Monitors
export def "0-organizations-detectors Bulk-Delete-Monitors" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --qp-query: string # An optional search query for filtering monitors.  Available fields are: - `name` - `type`: e.g. `error`, `metric_issue`, `issue_stream` - `assignee`: email, username, #team, me, none         
  --sortBy: string # The property to sort results by. If not specified, the results are sorted by id.  Available fields are: - `name` - `id` - `type` - `connectedWorkflows` - `latestGroup` - `openIssues`  Prefix with `-` to sort in descending order.         
  --id: list # The ID of the monitor you'd like to query.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/detectors/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return details on an individual monitor
#
# GET /api/0/organizations/{organization_id_or_slug}/detectors/{detector_id}/
# operationId: Fetch a Monitor
export def "0-organizations-detectors Fetch-a-Monitor" [
  organization_id_or_slug: string
  detector_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<owner: record<type: string, id: string, name: string, email: string>, createdBy: string, latestGroup: record, description: string, id: string, projectId: string, name: string, type: string, workflowIds: list<string>, dateCreated: string, dateUpdated: string, dataSources: list<record>, conditionGroup: record, config: record, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/detectors/($detector_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing monitor
#
# PUT /api/0/organizations/{organization_id_or_slug}/detectors/{detector_id}/
# operationId: Update a Monitor by ID
export def "0-organizations-detectors Update-a-Monitor-by-ID" [
  organization_id_or_slug: string
  detector_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the monitor.
  type: string # The type of monitor - `metric_issue`.
  --workflow-ids: list # The IDs of the alerts to connect this monitor to. Use the 'Fetch Alerts' endpoint to find the IDs.
  --data-sources: list #              The data sources for the monitor to use based on what you want to measure.              **Number of Errors Metric Monitor**             - `eventTypes`: Any of `error` or `default`.             ```json                 [                     {                         "aggregate": "count()",                         "dataset" : "events",                         "environment": "prod",                         "eventTypes": ["default", "error"],                         "query": "is:unresolved",                         "queryType": 0,                         "timeWindow": 3600,                     },                 ],             ```              **Users Experiencing Errors Metric Monitor**             - `eventTypes`: Any of `error` or `default`.             ```json                 [                     {                         "aggregate": "count_unique(tags[sentry:user])",                         "dataset" : "events",                         "environment": "prod",                         "eventTypes": ["default", "error"],                         "query": "is:unresolved",                         "queryType": 0,                         "timeWindow": 3600,                     },                 ],             ```               **Throughput Metric Monitor**             ```json                 [                     {                         "aggregate":"count(span.duration)",                         "dataset":"events_analytics_platform",                         "environment":"prod",                         "eventTypes":["trace_item_span"]                         "query":"",                         "queryType":1,                         "timeWindow":3600,                         "extrapolationMode":"unknown",                     },                 ],             ```              **Duration Metric Monitor**             ```json                 [                     {                         "aggregate":"p95(span.duration)",                         "dataset":"events_analytics_platform",                         "environment":"prod",                         "eventTypes":["trace_item_span"]                         "query":"",                         "queryType":1,                         "timeWindow":3600,                         "extrapolationMode":"unknown",                     },                 ],             ```              **Failure Rate Metric Monitor**             ```json                 [                     {                         "aggregate":"failure_rate()",                         "dataset":"events_analytics_platform",                         "environment":"prod",                         "eventTypes":["trace_item_span"]                         "query":"",                         "queryType":1,                         "timeWindow":3600,                         "extrapolationMode":"unknown",                     },                 ],             ```              **Largest Contentful Paint Metric Monitor**             - `dataset`: If a custom percentile is used, dataset is `transactions`. Otherwise, dataset is `events_analytics_platform`.             - `aggregate`: Valid values are `avg(measurements.lcp)`, `p50(measurements.lcp)`, `p75(measurements.lcp)`, `p95(measurements.lcp)`, `p99(measurements.lcp)`, `p100(measurements.lcp)`, and `percentile(measurements.lcp,x)`, where `x` is your custom percentile.              ```json                 [                     {                         "aggregate":"p95(measurements.lcp)",                         "dataset":"events_analytics_platform",                         "environment":"prod",                         "eventTypes":["trace_item_span"]                         "query":"",                         "queryType":1,                         "timeWindow":3600,                         "extrapolationMode":"unknown",                     },                 ],             ```              **Custom Metric Monitor**             - `dataset`: If a custom percentile is used, dataset is `transactions`. Otherwise, dataset is `events_analytics_platform`.             - `aggregate`: Valid values are:             `avg(x)`, where `x` is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p50(x)`, where `x` is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p75(x)`, where x is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p95(x)`, where x is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p99(x)`, where x is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p100(x)`, where `x` is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `percentile(x,y)`, where `x` is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`, and `y` is the custom percentile.             `failure_rate()`             `apdex(x)`, where `x` is the value of the Apdex score.             `count()`              ```json             [                 {                     "aggregate": "p75(measurements.ttfb)"                     "dataset": "events_analytics_platform",                     "queryType": 1,                 },             ],
  --config: record #              The issue detection type configuration.               - `detectionType`                 - `static`: Threshold based monitor                 - `percent`: Change based monitor                 - `dynamic`: Dynamic monitor             - `comparisonDelta`: If selecting a **change** detection type, the comparison delta is the time period at which to compare against in minutes.             For example, a value of 3600 compares the metric tracked against data 1 hour ago.                 - `300`: 5 minutes                 - `900`: 15 minutes                 - `3600`: 1 hour                 - `86400`: 1 day                 - `604800`: 1 week                 - `2592000`: 1 month              **Threshold**             ```json             {                 "detectionType": "static",             }             ```             **Change**             ```json             {                 "detectionType": "percent",                 "comparisonDelta": 3600,             }             ```             **Dynamic**             ```json             {                 "detectionType": "dynamic",             }             ```         
  --condition-group: any #              Issue detection configuration for when to create an issue and at what priority level.               - `logicType`: `any`             - `type`: Any of `gt` (greater than), `lte` (less than or equal), or `anomaly_detection` (dynamic)             - `comparison`: Any positive integer. This is threshold that must be crossed for the monitor to create an issue, e.g. "Create a metric issue when there are more than 5 unresolved error events".                 - If creating a **dynamic** monitor, see the options below.                     - `seasonality`: `auto`                     - `sensitivity`: Level of responsiveness. Options are one of `low`, `medium`, or `high`                     - `thresholdType`: If you want to be alerted to anomalies that are moving above, below, or in both directions in relation to your threshold.                         - `0`: Above                         - `1`: Below                         - `2`: Above and below              - `conditionResult`: The issue state change when the threshold is crossed.                 - `75`: High priority                 - `50`: Low priority                 - `0`: Resolved               **Threshold and Change Monitor**             ```json                 "logicType": "any",                 "conditions": [                     {                         "type": "gt",                         "comparison": 10,                         "conditionResult": 75                     },                     {                         "type": "lte",                         "comparison": 10,                         "conditionResult": 0                     }                 ],                 "actions": []             ```              **Threshold Monitor with Medium Priority**             ```json                 "logicType": "any",                 "conditions": [                     {                         type: "gt",                         comparison: 5,                         conditionResult: 75                     },                     {                         type: "gt",                         comparison: 2,                         conditionResult: 50                     },                     {                         type: "lte",                         comparison: 2,                         conditionResult: 0                     }                 ],                 "actions": []             ```              **Dynamic Monitor**             ```json                 "logicType": "any",                 "conditions": [                     {                         "type": "anomaly_detection",                         "comparison": {                             "seasonality": "auto",                             "sensitivity": "medium",                             "thresholdType": 2                         },                         "conditionResult": 75                     }                 ],                 "actions": []             ```         
  --owner: string #              The ID user or team who owns the monitor or alert prefaced by the string 'user' or 'team'.              **User**             ```json                 "user:123456"             ```              **Team**             ```json                 "team:456789"             ```          (nullable)
  --description: string # A description of the monitor. Will be used in the resulting issue. (nullable)
  --enabled: string@bool-completer # Set to False if you want to disable the monitor.
]: any -> record<owner: record<type: string, id: string, name: string, email: string>, createdBy: string, latestGroup: record, description: string, id: string, projectId: string, name: string, type: string, workflowIds: list<string>, dateCreated: string, dateUpdated: string, dataSources: list<record>, conditionGroup: record, config: record, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/detectors/($detector_id)/")
  let body = {name: $name, type: $type, workflow_ids: $workflow_ids, data_sources: $data_sources, config: $config, condition_group: $condition_group, owner: $owner, description: $description, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a monitor
#
# DELETE /api/0/organizations/{organization_id_or_slug}/detectors/{detector_id}/
# operationId: Delete a Monitor
export def "0-organizations-detectors Delete-a-Monitor" [
  organization_id_or_slug: string
  detector_id: int
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/detectors/($detector_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an Organization's Discover Saved Queries
#
# GET /api/0/organizations/{organization_id_or_slug}/discover/saved/
# operationId: listOrganizationDiscoverSavedQueries
export def "0-organizations-discover-saved listOrganizationDiscoverSavedQueries" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --qp-query: string # The name of the Discover query you'd like to filter by.
  --sortBy: string # The property to sort results by. If not specified, the results are sorted by query name.  Available fields are: - `name` - `dateCreated` - `dateUpdated` - `mostPopular` - `recentlyViewed` - `myqueries`         
]: nothing -> table<environment: list<string>, query: string, fields: list<string>, widths: list<string>, conditions: list<string>, aggregations: list<string>, range: string, start: string, end: string, orderby: string, limit: string, yAxis: list<string>, display: string, topEvents: int, interval: string, exploreQuery: record, id: string, name: string, projects: list<int>, version: int, queryDataset: string, datasetSource: string, expired: bool, dateCreated: string, dateUpdated: string, createdBy: record<identities: list, avatar: record, authenticators: list, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/discover/saved/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a New Saved Query
#
# POST /api/0/organizations/{organization_id_or_slug}/discover/saved/
# operationId: createOrganizationDiscoverSavedQuery
export def "0-organizations-discover-saved createOrganizationDiscoverSavedQuery" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The user-defined saved query name.
  --projects: list # The saved projects filter for this query.
  --queryDataset: string@queryDataset-completer # The dataset you would like to query. Note: `discover` is a **deprecated** value. The allowed values are: `error-events`, `transaction-like`  * `discover` * `error-events` * `transaction-like` (default: error-events)
  --start: string # The saved start time for this saved query. (nullable, format: date-time)
  --end: string # The saved end time for this saved query. (nullable, format: date-time)
  --range: string # The saved time range period for this saved query. (nullable)
  --body-fields: list # The fields, functions, or equations that can be requested for the query. At most 20 fields can be selected per request. Each field can be one of the following types: - A built-in key field. See possible fields in the [properties table](/product/sentry-basics/search/searchable-properties/#properties-table), under any field that is an event property.     - example: `field=transaction` - A tag. Tags should use the `tag[]` formatting to avoid ambiguity with any fields     - example: `field=tag[isEnterprise]` - A function which will be in the format of `function_name(parameters,...)`. See possible functions in the [query builder documentation](/product/discover-queries/query-builder/#stacking-functions).     - when a function is included, Discover will group by any tags or fields     - example: `field=count_if(transaction.duration,greater,300)` - An equation when prefixed with `equation|`. Read more about [equations here](/product/discover-queries/query-builder/query-equations/).     - example: `field=equation|count_if(transaction.duration,greater,300) / count() * 100`  (nullable)
  --orderby: string # How to order the query results. Must be something in the `field` list, excluding equations. (nullable)
  --environment: list # The name of environments to filter by. (nullable)
  --body-query: string # Filters results by using [query syntax](/product/sentry-basics/search/). (nullable)
  --yAxis: list # Aggregate functions to be plotted on the chart. (nullable)
  --display: string # Visualization type for saved query chart. Allowed values are: - default - previous - top5 - daily - dailytop5 - bar  (nullable)
  --topEvents: int # Number of top events' timeseries to be visualized. (nullable)
  --interval: string # Resolution of the time series. (nullable)
]: any -> record<environment: list<string>, query: string, fields: list<string>, widths: list<string>, conditions: list<string>, aggregations: list<string>, range: string, start: string, end: string, orderby: string, limit: string, yAxis: list<string>, display: string, topEvents: int, interval: string, exploreQuery: record, id: string, name: string, projects: list<int>, version: int, queryDataset: string, datasetSource: string, expired: bool, dateCreated: string, dateUpdated: string, createdBy: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/discover/saved/")
  let body = {name: $name, projects: $projects, queryDataset: $queryDataset, start: $start, end: $end, range: $range, fields: $body_fields, orderby: $orderby, environment: $environment, query: $body_query, yAxis: $yAxis, display: $display, topEvents: $topEvents, interval: $interval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an Organization's Discover Saved Query
#
# GET /api/0/organizations/{organization_id_or_slug}/discover/saved/{query_id}/
# operationId: getOrganizationDiscoverSavedQuery
export def "0-organizations-discover-saved get" [
  organization_id_or_slug: string
  query_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<environment: list<string>, query: string, fields: list<string>, widths: list<string>, conditions: list<string>, aggregations: list<string>, range: string, start: string, end: string, orderby: string, limit: string, yAxis: list<string>, display: string, topEvents: int, interval: string, exploreQuery: record, id: string, name: string, projects: list<int>, version: int, queryDataset: string, datasetSource: string, expired: bool, dateCreated: string, dateUpdated: string, createdBy: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/discover/saved/($query_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Edit an Organization's Discover Saved Query
#
# PUT /api/0/organizations/{organization_id_or_slug}/discover/saved/{query_id}/
# operationId: updateOrganizationDiscoverSavedQuery
export def "0-organizations-discover-saved updateOrganizationDiscoverSavedQuery" [
  organization_id_or_slug: string
  query_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The user-defined saved query name.
  --projects: list # The saved projects filter for this query.
  --queryDataset: string@queryDataset-completer # The dataset you would like to query. Note: `discover` is a **deprecated** value. The allowed values are: `error-events`, `transaction-like`  * `discover` * `error-events` * `transaction-like` (default: error-events)
  --start: string # The saved start time for this saved query. (nullable, format: date-time)
  --end: string # The saved end time for this saved query. (nullable, format: date-time)
  --range: string # The saved time range period for this saved query. (nullable)
  --body-fields: list # The fields, functions, or equations that can be requested for the query. At most 20 fields can be selected per request. Each field can be one of the following types: - A built-in key field. See possible fields in the [properties table](/product/sentry-basics/search/searchable-properties/#properties-table), under any field that is an event property.     - example: `field=transaction` - A tag. Tags should use the `tag[]` formatting to avoid ambiguity with any fields     - example: `field=tag[isEnterprise]` - A function which will be in the format of `function_name(parameters,...)`. See possible functions in the [query builder documentation](/product/discover-queries/query-builder/#stacking-functions).     - when a function is included, Discover will group by any tags or fields     - example: `field=count_if(transaction.duration,greater,300)` - An equation when prefixed with `equation|`. Read more about [equations here](/product/discover-queries/query-builder/query-equations/).     - example: `field=equation|count_if(transaction.duration,greater,300) / count() * 100`  (nullable)
  --orderby: string # How to order the query results. Must be something in the `field` list, excluding equations. (nullable)
  --environment: list # The name of environments to filter by. (nullable)
  --body-query: string # Filters results by using [query syntax](/product/sentry-basics/search/). (nullable)
  --yAxis: list # Aggregate functions to be plotted on the chart. (nullable)
  --display: string # Visualization type for saved query chart. Allowed values are: - default - previous - top5 - daily - dailytop5 - bar  (nullable)
  --topEvents: int # Number of top events' timeseries to be visualized. (nullable)
  --interval: string # Resolution of the time series. (nullable)
]: any -> record<environment: list<string>, query: string, fields: list<string>, widths: list<string>, conditions: list<string>, aggregations: list<string>, range: string, start: string, end: string, orderby: string, limit: string, yAxis: list<string>, display: string, topEvents: int, interval: string, exploreQuery: record, id: string, name: string, projects: list<int>, version: int, queryDataset: string, datasetSource: string, expired: bool, dateCreated: string, dateUpdated: string, createdBy: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/discover/saved/($query_id)/")
  let body = {name: $name, projects: $projects, queryDataset: $queryDataset, start: $start, end: $end, range: $range, fields: $body_fields, orderby: $orderby, environment: $environment, query: $body_query, yAxis: $yAxis, display: $display, topEvents: $topEvents, interval: $interval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Organization's Discover Saved Query
#
# DELETE /api/0/organizations/{organization_id_or_slug}/discover/saved/{query_id}/
# operationId: deleteOrganizationDiscoverSavedQuery
export def "0-organizations-discover-saved delete" [
  organization_id_or_slug: string
  query_id: int
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/discover/saved/($query_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists an organization's environments.
#
# GET /api/0/organizations/{organization_id_or_slug}/environments/
# operationId: List an Organization's Environments
export def "0-organizations-environments List-an-Organizations-Environments" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility: string@visibility-completer # The visibility of the environments to filter by. Defaults to `visible`.
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/environments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This resolves an event ID to the project slug and internal issue ID and internal event ID.
#
# GET /api/0/organizations/{organization_id_or_slug}/eventids/{event_id}/
# operationId: Resolve an Event ID
export def "0-organizations-eventids Resolve-an-Event-ID" [
  organization_id_or_slug: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<organizationSlug: string, projectSlug: string, groupId: string, eventId: string, event: record<id: string, groupID: string, eventID: string, projectID: string, message: string, title: string, location: string, user: record<id: string, email: string, username: string, ip_address: string, name: string, geo: record, data: record>, tags: list<record>, platform: string, dateReceived: string, contexts: record, size: int, entries: list<any>, dist: string, sdk: record, context: record, packages: record, type: string, metadata: any, errors: list<any>, occurrence: any, _meta: record, crashFile: string, culprit: string, dateCreated: string, fingerprints: list<string>, groupingConfig: any, startTimestamp: string, endTimestamp: string, measurements: any, breakdowns: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/eventids/($event_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves explore data for a given organization.  **Note**: This endpoint is intended to get a table of results, and is not for doing a full export of data sent to Sentry.  The `field` query parameter determines what fields will be selected in the `data` and `meta` keys of the endpoint response. - The `data` key contains a list of results row by row that match the `query` made - The `meta` key contains information about the response, including the unit or type of the fields requested
#
# GET /api/0/organizations/{organization_id_or_slug}/events/
# operationId: Query Explore Events in Table Format
export def "0-organizations-events Query-Explore-Events-in-Table-Format" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: list # The fields, functions, or equations to request for the query. At most 20 fields can be selected per request. Each field can be one of the following types: - A built-in key field. See possible fields in the [properties table](/concepts/search/searchable-properties/), under any field that matches the dataset passed to the dataset parameter     - example: `field=transaction` - A tag. Tags should use the `tag[{name}, {type}]` formatting to avoid ambiguity with any fields,     - example: `field=tag[isEnterprise, string]`     - example: `field=tag[numberOfBytes, number]` - A function which will be in the format of `function_name(parameters,...)`. See possible functions in the [query builder documentation](/product/discover-queries/query-builder/#stacking-functions).     - when a function is included, Discover will group by any tags or fields     - example: `field=count_if(transaction.duration,greater,300)` - An equation when prefixed with `equation|`. Read more about [equations here](/product/discover-queries/query-builder/query-equations/).     - example: `field=equation|count_if(transaction.duration,greater,300) / count() * 100`
  --dataset: string@dataset-completer # Which dataset to query. The chosen dataset determines which fields are queryable. - `errors` - Error events. - `logs` - Structured log events. - `profile_functions` - Function-level Profiling data. - `spans` - Distributed tracing span events. - `tracemetrics` - Application Metrics. - `uptime_results` - Uptime monitoring check results.
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --environment: list # The name of environments to filter by.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
  --qp-query: string # Filters results by using [query syntax](/product/sentry-basics/search/).  Example: `query=(transaction:foo AND release:abc) OR (transaction:[bar,baz] AND release:def)`
  --qp-sort: string # What to order the results of the query by. Must be something in the `field` list, excluding equations.
  --allowAggregateConditions: string@bool-completer # If false, aggregate conditions in the query string are disallowed. Defaults to true.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> record<data: list<record>, meta: record<fields: record, units: record, tips: record, datasetReason: string, isMetricsData: bool, isMetricsExtractedData: bool, dataset: string, discoverSplitDecision: any, dataScanned: string, bytesScanned: int, debug_info: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "field" $field "multi") (serialize-qp "dataset" $dataset "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "environment" $environment "multi") (serialize-qp "project" $project "multi") (serialize-qp "start" $start "scalar") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "allowAggregateConditions" $allowAggregateConditions "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/events/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves explore data for a given organization as a timeseries.  This endpoint can return timeseries for either 1 or many axis, and results grouped to the top events depending on the parameters passed
#
# GET /api/0/organizations/{organization_id_or_slug}/events-timeseries/
# operationId: Query Explore Events in Timeseries Format
export def "0-organizations-events-timeseries Query-Explore-Events-in-Timeseries-Format" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dataset: string@dataset-completer # Which dataset to query. The chosen dataset determines which fields are queryable. - `errors` - Error events. - `logs` - Structured log events. - `profile_functions` - Function-level Profiling data. - `spans` - Distributed tracing span events. - `tracemetrics` - Application Metrics. - `uptime_results` - Uptime monitoring check results.
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --environment: list # The name of environments to filter by.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --topEvents: int # The number of top event results to return, must be between 1 and 10. When TopEvents is passed, both sort and groupBy are required parameters
  --comparisonDelta: int # The delta in seconds to return additional offset timeseries by
  --interval: int # The size of the bucket for the timeseries to have, must be a value smaller than the window being queried. If the interval is invalid a default interval will be selected instead
  --qp-sort: string # What to order the results of the query by. Must be something in the `field` list, excluding equations.
  --groupBy: list # List of fields to group by, *Required* for topEvents queries as this and sort determine what the top events are
  --yAxis: string # The aggregate field to create the timeseries for, defaults to `count()` when not included
  --qp-query: string # Filters results by using [query syntax](/product/sentry-basics/search/).  Example: `query=(transaction:foo AND release:abc) OR (transaction:[bar,baz] AND release:def)`
  --disableAggregateExtrapolation: string@disableAggregateExtrapolation-completer # Whether to disable the use of extrapolation and return the sampled values, due to sampling the number returned may be less than the actual values sent to Sentry
  --preventMetricAggregates: string@preventMetricAggregates-completer # Whether to throw an error when aggregates are passed in the query or groupBy
  --excludeOther: string@excludeOther-completer # Only applicable with TopEvents, whether to include the 'other' timeseries which represents all the events that aren't in the top groups.
]: nothing -> record<meta: record<dataset: string, start: float, end: float>, timeSeries: table<values: list, yAxis: string, groupBy: list, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dataset" $dataset "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "environment" $environment "multi") (serialize-qp "project" $project "multi") (serialize-qp "start" $start "scalar") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "topEvents" $topEvents "scalar") (serialize-qp "comparisonDelta" $comparisonDelta "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "groupBy" $groupBy "multi") (serialize-qp "yAxis" $yAxis "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "disableAggregateExtrapolation" $disableAggregateExtrapolation "scalar") (serialize-qp "preventMetricAggregates" $preventMetricAggregates "scalar") (serialize-qp "excludeOther" $excludeOther "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/events-timeseries/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link a user from an external provider to a Sentry user.
#
# POST /api/0/organizations/{organization_id_or_slug}/external-users/
# operationId: Create an External User
export def "0-organizations-external-users Create-an-External-User" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The user ID in Sentry.
  external_name: string # The associated name for the provider.
  provider: string@provider-completer # The provider of the external actor.  * `github` * `github_enterprise` * `jira_server` * `slack` * `slack_staging` * `perforce` * `gitlab` * `msteams` * `custom_scm`
  integration_id: int # The Integration ID.
  --external-id: string # The associated user ID for provider. (nullable)
]: any -> record<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/external-users/")
  let body = {user_id: $user_id, external_name: $external_name, provider: $provider, integration_id: $integration_id, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a user in an external provider that is currently linked to a Sentry user.
#
# PUT /api/0/organizations/{organization_id_or_slug}/external-users/{external_user_id}/
# operationId: Update an External User
export def "0-organizations-external-users Update-an-External-User" [
  organization_id_or_slug: string
  external_user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The user ID in Sentry.
  external_name: string # The associated name for the provider.
  provider: string@provider-completer # The provider of the external actor.  * `github` * `github_enterprise` * `jira_server` * `slack` * `slack_staging` * `perforce` * `gitlab` * `msteams` * `custom_scm`
  integration_id: int # The Integration ID.
  --external-id: string # The associated user ID for provider. (nullable)
]: any -> record<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/external-users/($external_user_id)/")
  let body = {user_id: $user_id, external_name: $external_name, provider: $provider, integration_id: $integration_id, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the link between a user from an external provider and a Sentry user.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/external-users/{external_user_id}/
# operationId: Delete an External User
export def "0-organizations-external-users Delete-an-External-User" [
  organization_id_or_slug: string
  external_user_id: int
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/external-users/($external_user_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of data forwarders for an organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/forwarding/
# operationId: Retrieve Data Forwarders for an Organization
export def "0-organizations-forwarding Retrieve-Data-Forwarders-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, organizationId: string, isEnabled: bool, enrollNewProjects: bool, enrolledProjects: list<record>, provider: string, config: record, projectConfigs: list<record>, dateAdded: string, dateUpdated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/forwarding/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new data forwarder for an organization. Only one data forwarder can be created per provider for a given organization.  Project-specific overrides can only be created after creating the data forwarder.
#
# POST /api/0/organizations/{organization_id_or_slug}/forwarding/
# operationId: Create a Data Forwarder for an Organization
export def "0-organizations-forwarding Create-a-Data-Forwarder-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: int # The ID of the organization related to the data forwarder.
  provider: string@provider-completer-1 # The provider of the data forwarder. One of "segment", "sqs", or "splunk".  * `segment` - Segment * `sqs` - Amazon SQS * `splunk` - Splunk
  --is-enabled: string@bool-completer # Whether the data forwarder is enabled. (default: true)
  --enroll-new-projects: string@bool-completer # Whether to enroll new projects automatically, after they're created. (default: false)
  --config: record # The configuration for the data forwarder, specific to the provider type.  For a 'sqs' provider, the required keys are queue_url, region, access_key, secret_key. If using a FIFO queue, you must also provide a message_group_id, though s3_bucket is optional.  For a 'segment' provider, the required keys are write_key.  For a 'splunk' provider, the required keys are instance_url, index, source, token.
  --project-ids: list # The IDs of the projects connected to the data forwarder. Missing project IDs will be unenrolled if previously enrolled.
]: any -> record<id: string, organizationId: string, isEnabled: bool, enrollNewProjects: bool, enrolledProjects: table<id: string, slug: string, platform: string>, provider: string, config: record, projectConfigs: table<id: string, isEnabled: bool, dataForwarderId: string, project: record, overrides: record, effectiveConfig: record, dateAdded: string, dateUpdated: string>, dateAdded: string, dateUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/forwarding/")
  let body = {organization_id: $organization_id, provider: $provider, is_enabled: $is_enabled, enroll_new_projects: $enroll_new_projects, config: $config, project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a data forwarder for an organization or update a project-specific override. Updates to the data forwarder's configuration require `org:write` permissions, and the entire configuration to be provided, including the `project_ids` field.  To configure project-specific overrides, specify only the following fields:    - 'project_id': The ID of the project to create/modify the override for.   - 'overrides': Follows the same format as `config` but all provider fields are optional, since only specified fields are overridden.   - 'is_enabled': To enable/disable the forwarder for events on the specific project.  Overrides can be performed with `project:write` permissions on the project being modified.
#
# PUT /api/0/organizations/{organization_id_or_slug}/forwarding/{data_forwarder_id}/
# operationId: Update a Data Forwarder for an Organization
export def "0-organizations-forwarding Update-a-Data-Forwarder-for-an-Organization" [
  organization_id_or_slug: string
  data_forwarder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: int # The ID of the organization related to the data forwarder.
  provider: string@provider-completer-1 # The provider of the data forwarder. One of "segment", "sqs", or "splunk".  * `segment` - Segment * `sqs` - Amazon SQS * `splunk` - Splunk
  --is-enabled: string@bool-completer # Whether the data forwarder is enabled. (default: true)
  --enroll-new-projects: string@bool-completer # Whether to enroll new projects automatically, after they're created. (default: false)
  --config: record # The configuration for the data forwarder, specific to the provider type.  For a 'sqs' provider, the required keys are queue_url, region, access_key, secret_key. If using a FIFO queue, you must also provide a message_group_id, though s3_bucket is optional.  For a 'segment' provider, the required keys are write_key.  For a 'splunk' provider, the required keys are instance_url, index, source, token.
  --project-ids: list # The IDs of the projects connected to the data forwarder. Missing project IDs will be unenrolled if previously enrolled.
]: any -> record<id: string, organizationId: string, isEnabled: bool, enrollNewProjects: bool, enrolledProjects: table<id: string, slug: string, platform: string>, provider: string, config: record, projectConfigs: table<id: string, isEnabled: bool, dataForwarderId: string, project: record, overrides: record, effectiveConfig: record, dateAdded: string, dateUpdated: string>, dateAdded: string, dateUpdated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/forwarding/($data_forwarder_id)/")
  let body = {organization_id: $organization_id, provider: $provider, is_enabled: $is_enabled, enroll_new_projects: $enroll_new_projects, config: $config, project_ids: $project_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a data forwarder for an organization. All project-specific overrides will be deleted as well.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/forwarding/{data_forwarder_id}/
# operationId: Delete a Data Forwarder for an Organization
export def "0-organizations-forwarding Delete-a-Data-Forwarder-for-an-Organization" [
  organization_id_or_slug: string
  data_forwarder_id: int
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/forwarding/($data_forwarder_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all the available Integrations for an Organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/integrations/
# operationId: List an Organization's Available Integrations
export def "0-organizations-integrations List-an-Organizations-Available-Integrations" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --providerKey: string # Specific integration provider to filter by such as `slack`. See our [Integrations Documentation](/product/integrations/) for an updated list of providers.
  --features: list # Integration features to filter by. See our [Integrations Documentation](/product/integrations/) for an updated list of features. Current available ones are: - `alert-rule` - `chat-unfurl` - `codeowners` - `commits` - `data-forwarding` - `deployment` - `enterprise-alert-rule` - `enterprise-incident-management` - `incident-management` - `issue-basic` - `issue-sync` - `mobile` - `serverless` - `session-replay` - `stacktrace-link` - `ticket-rules`     
  --includeConfig: string@bool-completer # Specify `True` to fetch third-party integration configurations. Note that this can add several seconds to the response time.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, name: string, icon: string, domainName: string, accountType: string, scopes: list<string>, status: string, provider: any, configOrganization: any, configData: any, externalId: string, organizationId: int, organizationIntegrationStatus: string, gracePeriodEnd: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "providerKey" $providerKey "scalar") (serialize-qp "features" $features "multi") (serialize-qp "includeConfig" $includeConfig "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/integrations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OrganizationIntegrationBaseEndpoints expect both Integration and OrganizationIntegration DB entries to exist for a given organization and integration_id.
#
# GET /api/0/organizations/{organization_id_or_slug}/integrations/{integration_id}/
# operationId: Retrieve an Integration for an Organization
export def "0-organizations-integrations Retrieve-an-Integration-for-an-Organization" [
  organization_id_or_slug: string
  integration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, icon: string, domainName: string, accountType: string, scopes: list<string>, status: string, provider: any, configOrganization: any, configData: any, externalId: string, organizationId: int, organizationIntegrationStatus: string, gracePeriodEnd: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/integrations/($integration_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# OrganizationIntegrationBaseEndpoints expect both Integration and OrganizationIntegration DB entries to exist for a given organization and integration_id.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/integrations/{integration_id}/
# operationId: Delete an Integration for an Organization
export def "0-organizations-integrations Delete-an-Integration-for-an-Organization" [
  organization_id_or_slug: string
  integration_id: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/integrations/($integration_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of issues for an organization. All parameters are supplied as query string parameters. A default query of `is:unresolved` is applied. To return all results, use an empty query value (i.e. ``?query=`). 
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/
# operationId: List an Organization's Issues
export def "0-organizations-issues List-an-Organizations-Issues" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --groupStatsPeriod: string@groupStatsPeriod-completer # The timeline on which stats for the groups should be presented.
  --shortIdLookup: string@shortIdLookup-completer # If this is set to `1` then the query will be parsed for issue short IDs. These may ignore other filters (e.g. projects), which is why it is an opt-in.
  --qp-query: string # An optional search query for filtering issues. A default query will apply if no view/query is set. For all results use this parameter with an empty string. (default: is:unresolved)
  --viewId: string # The ID of the view to use. If no query is present, the view's query and filters will be applied.
  --qp-sort: string@sort-completer # The sort order of the view. Options include 'Last Seen' (`date`), 'First Seen' (`new`), 'Trends' (`trends`), 'Events' (`freq`), 'Users' (`user`), 'Date Added' (`inbox`), and 'Recommended' (`recommended`). (default: date)
  --limit: int # The maximum number of issues to affect. The maximum is 100. (default: 100)
  --expand: list # Additional data to include in the response.
  --collapse: list # Fields to remove from the response to improve query performance.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, shareId: string, shortId: string, title: string, culprit: string, permalink: string, logger: string, level: string, status: string, statusDetails: record<autoResolved: bool, ignoreCount: int, ignoreUntil: string, ignoreUserCount: int, ignoreUserWindow: int, ignoreWindow: int, actor: record, inNextRelease: bool, inRelease: string, inCommit: string, pendingEvents: int, info: any>, substatus: string, isPublic: bool, platform: string, priority: string, priorityLockedAt: string, seerFixabilityScore: float, seerAutofixLastTriggered: string, seerExplorerAutofixLastTriggered: string, project: record<id: string, name: string, slug: string, platform: string>, type: string, issueType: string, issueCategory: string, metadata: record, numComments: int, assignedTo: record<type: string, id: string, name: string, email: string>, isBookmarked: bool, isSubscribed: bool, subscriptionDetails: record<disabled: bool, reason: string>, hasSeen: bool, annotations: list<record>, isUnhandled: bool, count: string, userCount: int, firstSeen: string, lastSeen: string, stats: record, lifetime: record, filtered: record<count: string, userCount: int, firstSeen: string, lastSeen: string, stats: record>, sessionCount: int, inbox: record<reason: int, reason_details: record, date_added: string>, owners: record<type: string, owner: string, date_added: string>, pluginActions: list<list>, pluginIssues: list<record>, integrationIssues: list<record>, sentryAppIssues: list<record>, latestEventHasAttachments: bool, matchingEventId: string, matchingEventEnvironment: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi") (serialize-qp "project" $project "multi") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "groupStatsPeriod" $groupStatsPeriod "scalar") (serialize-qp "shortIdLookup" $shortIdLookup "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "viewId" $viewId "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "collapse" $collapse "multi") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk mutate various attributes on a maxmimum of 1000 issues.  - For non-status updates, the `id` query parameter is required.  - For status updates, the `id` query parameter may be omitted to update issues that match the filtering.  If any IDs are out of scope, the data won't be mutated but the endpoint will still produce a successful response. For example, if no issues were found matching the criteria, a HTTP 204 is returned.
#
# PUT /api/0/organizations/{organization_id_or_slug}/issues/
# operationId: Bulk Mutate an Organization's Issues
export def "0-organizations-issues Bulk-Mutate-an-Organizations-Issues" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --id: list # The list of issue IDs to mutate. It is optional for status updates, in which an implicit `update all` is assumed.
  --qp-query: string # An optional search query for filtering issues. A default query will apply if no view/query is set. For all results use this parameter with an empty string. (default: is:unresolved)
  --viewId: string # The ID of the view to use. If no query is present, the view's query and filters will be applied.
  --qp-sort: string@sort-completer # The sort order of the view. Options include 'Last Seen' (`date`), 'First Seen' (`new`), 'Trends' (`trends`), 'Events' (`freq`), 'Users' (`user`), 'Date Added' (`inbox`), and 'Recommended' (`recommended`). (default: date)
  --limit: int # The maximum number of issues to affect. The maximum is 100. (default: 100)
  --inbox: string@bool-completer # If true, marks the issue as reviewed by the requestor.
  status: string@status-completer # Limit mutations to only issues with the given status.  * `resolved` * `unresolved` * `ignored` * `resolvedInNextRelease` * `muted`
  statusDetails: any # Additional details about the resolution. Status detail updates that include release data are only allowed for issues within a single project.
  --substatus: string@substatus-completer # The new substatus of the issue.  * `archived_until_escalating` * `archived_until_condition_met` * `archived_forever` * `escalating` * `ongoing` * `regressed` * `new` (nullable)
  --hasSeen: string@bool-completer # If true, marks the issue as seen by the requestor.
  --isBookmarked: string@bool-completer # If true, bookmarks the issue for the requestor.
  --isPublic: string@bool-completer # If true, publishes the issue.
  --isSubscribed: string@bool-completer # If true, subscribes the requestor to the issue.
  --merge: string@bool-completer # If true, merges the issues together.
  --discard: string@bool-completer # If true, discards the issues instead of updating them.
  assignedTo: string # The user or team that should be assigned to the issues. Values take the form of `<user_id>`, `user:<user_id>`, `<username>`, `<user_primary_email>`, or `team:<team_id>`.
  priority: string@priority-completer # The priority that should be set for the issues  * `low` * `medium` * `high`
]: any -> record<assignedTo: record<type: string, id: string, name: string, email: string>, discard: bool, hasSeen: bool, inbox: bool, isBookmarked: bool, isPublic: bool, isSubscribed: bool, merge: record<parent: string, children: list<string>>, priority: string, shareId: string, status: string, statusDetails: record<inNextRelease: bool, inRelease: string, inCommit: record<commit: string, repository: string>, ignoreDuration: int, ignoreCount: int, ignoreWindow: int, ignoreUserCount: int, ignoreUserWindow: int>, subscriptionDetails: record<disabled: bool, reason: string>, substatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi") (serialize-qp "project" $project "multi") (serialize-qp "id" $id "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "viewId" $viewId "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/" $qp)
  let body = {inbox: $inbox, status: $status, statusDetails: $statusDetails, substatus: $substatus, hasSeen: $hasSeen, isBookmarked: $isBookmarked, isPublic: $isPublic, isSubscribed: $isSubscribed, merge: $merge, discard: $discard, assignedTo: $assignedTo, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Permanently remove the given issues. If IDs are provided, queries and filtering will be ignored. If any IDs are out of scope, the data won't be mutated but the endpoint will still produce a successful response. For example, if no issues were found matching the criteria, a HTTP 204 is returned.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/issues/
# operationId: Bulk Remove an Organization's Issues
export def "0-organizations-issues Bulk-Remove-an-Organizations-Issues" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --id: list # The list of issue IDs to be removed. If not provided, it will attempt to remove the first 1000 issues.
  --qp-query: string # An optional search query for filtering issues. A default query will apply if no view/query is set. For all results use this parameter with an empty string. (default: is:unresolved)
  --viewId: string # The ID of the view to use. If no query is present, the view's query and filters will be applied.
  --qp-sort: string@sort-completer # The sort order of the view. Options include 'Last Seen' (`date`), 'First Seen' (`new`), 'Trends' (`trends`), 'Events' (`freq`), 'Users' (`user`), 'Date Added' (`inbox`), and 'Recommended' (`recommended`). (default: date)
  --limit: int # The maximum number of issues to affect. The maximum is 100. (default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi") (serialize-qp "project" $project "multi") (serialize-qp "id" $id "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "viewId" $viewId "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all organization members.  Response includes pending invites that are approved by organization owners or managers but waiting to be accepted by the invitee.
#
# GET /api/0/organizations/{organization_id_or_slug}/members/
# operationId: List an Organization's Members
export def "0-organizations-members List-an-Organizations-Members" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<externalUsers: list<record>, id: string, email: string, name: string, user: record<identities: list, avatar: record, authenticators: list, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list>, orgRole: string, pending: bool, expired: bool, flags: record<idp_provisioned: bool, idp_role_restricted: bool, sso_linked: bool, sso_invalid: bool, member_limit_restricted: bool, partnership_restricted: bool>, dateCreated: string, inviteStatus: string, inviterName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/members/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or invite a member to an organization.
#
# POST /api/0/organizations/{organization_id_or_slug}/members/
# operationId: Add a Member to an Organization
export def "0-organizations-members Add-a-Member-to-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address to send the invitation to. (format: email)
  --orgRole: string@orgRole-completer # The organization-level role of the new member. Roles include:  * `billing` - Can manage payment and compliance details. * `member` - Can view and act on events, as well as view most other data within the organization. * `manager` - Has full management access to all teams and projects. Can also manage         the organization's membership. * `owner` - Has unrestricted access to the organization, its data, and its         settings. Can add, modify, and delete projects and members, as well as         make billing and plan changes. * `admin` - Can edit global integrations, manage projects, and add/remove teams.         They automatically assume the Team Admin role for teams they join.         Note: This role can no longer be assigned in Business and Enterprise plans. Use `TeamRoles` instead.          (default: member)
  --teamRoles: list # The team and team-roles assigned to the member. Team roles can be either:         - `contributor` - Can view and act on issues. Depending on organization settings, they can also add team members.         - `admin` - Has full management access to their team's membership and projects. (nullable)
  --sendInvite: string@bool-completer # Whether or not to send an invite notification through email. Defaults to True. (default: true)
  --reinvite: string@bool-completer # Whether or not to re-invite a user who has already been invited to the organization. Defaults to True.
]: any -> record<externalUsers: table<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string>, id: string, email: string, name: string, user: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>, orgRole: string, pending: bool, expired: bool, flags: record<idp_provisioned: bool, idp_role_restricted: bool, sso_linked: bool, sso_invalid: bool, member_limit_restricted: bool, partnership_restricted: bool>, dateCreated: string, inviteStatus: string, inviterName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/members/")
  let body = {email: $email, orgRole: $orgRole, teamRoles: $teamRoles, sendInvite: $sendInvite, reinvite: $reinvite} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an organization member's details.  Response will be a pending invite if it has been approved by organization owners or managers but is waiting to be accepted by the invitee.
#
# GET /api/0/organizations/{organization_id_or_slug}/members/{member_id}/
# operationId: Retrieve an Organization Member
export def "0-organizations-members Retrieve-an-Organization-Member" [
  organization_id_or_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<externalUsers: table<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string>, role: string, roleName: string, id: string, email: string, name: string, user: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>, orgRole: string, pending: bool, expired: bool, flags: record<idp_provisioned: bool, idp_role_restricted: bool, sso_linked: bool, sso_invalid: bool, member_limit_restricted: bool, partnership_restricted: bool>, dateCreated: string, inviteStatus: string, inviterName: string, teams: list<string>, teamRoles: table<teamSlug: string, role: string>, invite_link: string, isOnlyOwner: bool, orgRoleList: table<id: string, name: string, desc: string, scopes: list, allowed: bool, isAllowed: bool, isRetired: bool, isTeamRolesAllowed: bool, is_global: bool, isGlobal: bool, minimumTeamRole: string>, teamRoleList: table<id: string, name: string, desc: string, scopes: list, allowed: bool, isAllowed: bool, isRetired: bool, isTeamRolesAllowed: bool, isMinimumRoleFor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/members/($member_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a member's [organization-level](https://docs.sentry.io/organization/membership/#organization-level-roles) and [team-level](https://docs.sentry.io/organization/membership/#team-level-roles) roles.  Note that for changing organization-roles, this endpoint is restricted to [user auth tokens](https://docs.sentry.io/account/auth-tokens/#user-auth-tokens). Additionally, both the original and desired organization role must have the same or lower permissions than the role of the organization user making the request  For example, an organization Manager may change someone's role from Member to Manager, but not to Owner.
#
# PUT /api/0/organizations/{organization_id_or_slug}/members/{member_id}/
# operationId: Update an Organization Member's Roles
export def "0-organizations-members Update-an-Organization-Members-Roles" [
  organization_id_or_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --orgRole: string@orgRole-completer # The organization role of the member. The options are:  * `billing` - Can manage payment and compliance details. * `member` - Can view and act on events, as well as view most other data within the organization. * `manager` - Has full management access to all teams and projects. Can also manage         the organization's membership. * `owner` - Has unrestricted access to the organization, its data, and its         settings. Can add, modify, and delete projects and members, as well as         make billing and plan changes. * `admin` - Can edit global integrations, manage projects, and add/remove teams.         They automatically assume the Team Admin role for teams they join.         Note: This role can no longer be assigned in Business and Enterprise plans. Use `TeamRoles` instead.         
  --teamRoles: list #  Configures the team role of the member. The two roles are: - `contributor` - Can view and act on issues. Depending on organization settings, they can also add team members. - `admin` - Has full management access to their team's membership and projects. ```json {     "teamRoles": [         {             "teamSlug": "ancient-gabelers",             "role": "admin"         },         {             "teamSlug": "powerful-abolitionist",             "role": "contributor"         }     ] } ```  (nullable)
]: any -> record<externalUsers: table<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string>, role: string, roleName: string, id: string, email: string, name: string, user: record<identities: list<record>, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, authenticators: list<any>, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list<record>>, orgRole: string, pending: bool, expired: bool, flags: record<idp_provisioned: bool, idp_role_restricted: bool, sso_linked: bool, sso_invalid: bool, member_limit_restricted: bool, partnership_restricted: bool>, dateCreated: string, inviteStatus: string, inviterName: string, teams: list<string>, teamRoles: table<teamSlug: string, role: string>, invite_link: string, isOnlyOwner: bool, orgRoleList: table<id: string, name: string, desc: string, scopes: list, allowed: bool, isAllowed: bool, isRetired: bool, isTeamRolesAllowed: bool, is_global: bool, isGlobal: bool, minimumTeamRole: string>, teamRoleList: table<id: string, name: string, desc: string, scopes: list, allowed: bool, isAllowed: bool, isRetired: bool, isTeamRolesAllowed: bool, isMinimumRoleFor: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/members/($member_id)/")
  let body = {orgRole: $orgRole, teamRoles: $teamRoles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an organization member.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/members/{member_id}/
# operationId: Delete an Organization Member
export def "0-organizations-members Delete-an-Organization-Member" [
  organization_id_or_slug: string
  member_id: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/members/($member_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This request can return various success codes depending on the context of the team: - **`201`**: The member has been successfully added. - **`202`**: The member needs permission to join the team and an access request has been generated. - **`204`**: The member is already on the team.  If the team is provisioned through an identity provider, the member cannot join the team through Sentry.  Note the permission scopes vary depending on the organization setting `"Open Membership"` and the type of authorization token. The following table outlines the accepted scopes. <table style="width: 100%;"> <thead>     <tr>     <th style="width: 33%;"></th>     <th colspan="2" style="text-align: center; font-weight: bold; width: 33%;">Open Membership</th>     </tr> </thead> <tbody>     <tr>     <td style="width: 34%;"></td>     <td style="text-align: center; font-weight: bold; width: 33%;">On</td>     <td style="text-align: center; font-weight: bold; width: 33%;">Off</td>     </tr>     <tr>     <td style="text-align: center; font-weight: bold; vertical-align: middle;"><a     href="https://docs.sentry.io/account/auth-tokens/#internal-integrations">Internal Integration Token</a></td>     <td style="text-align: left; width: 33%;">         <ul style="list-style-type: none; padding-left: 0;">         <li><strong style="color: #9c5f99;">&bull; org:read</strong></li>         </ul>     </td>     <td style="text-align: left; width: 33%;">         <ul style="list-style-type: none; padding-left: 0;">         <li><strong style="color: #9c5f99;">&bull; org:write</strong></li>         <li><strong style="color: #9c5f99;">&bull; team:write</strong></li>         </ul>     </td>     </tr>     <tr>     <td style="text-align: center; font-weight: bold; vertical-align: middle;"><a     href="https://docs.sentry.io/account/auth-tokens/#user-auth-tokens">User Auth Token</a></td>     <td style="text-align: left; width: 33%;">         <ul style="list-style-type: none; padding-left: 0;">         <li><strong style="color: #9c5f99;">&bull; org:read</strong></li>         </ul>     </td>     <td style="text-align: left; width: 33%;">         <ul style="list-style-type: none; padding-left: 0;">         <li><strong style="color: #9c5f99;">&bull; org:read*</strong></li>         <li><strong style="color: #9c5f99;">&bull; org:write</strong></li>         <li><strong style="color: #9c5f99;">&bull; org:read +</strong></li>         <li><strong style="color: #9c5f99;">&nbsp; &nbsp;team:write**</strong></li>         </ul>     </td>     </tr> </tbody> </table>   *Organization members are restricted to this scope. When sending a request, it will always return a 202 and request an invite to the team.   \*\*Team Admins must have both **`org:read`** and **`team:write`** scopes in their user authorization token to add members to their teams.
#
# POST /api/0/organizations/{organization_id_or_slug}/members/{member_id}/teams/{team_id_or_slug}/
# operationId: Add an Organization Member to a Team
export def "0-organizations-members-teams Add-an-Organization-Member-to-a-Team" [
  organization_id_or_slug: string
  member_id: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list<string>, hasAccess: bool, isPending: bool, memberCount: int, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/members/($member_id)/teams/($team_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The relevant organization member must already be a part of the team.  Note that for organization admins, managers, and owners, they are automatically granted a minimum team role of `admin` on all teams they are part of. Read more about [team roles](https://docs.sentry.io/product/teams/roles/).
#
# PUT /api/0/organizations/{organization_id_or_slug}/members/{member_id}/teams/{team_id_or_slug}/
# operationId: Update an Organization Member's Team Role
export def "0-organizations-members-teams Update-an-Organization-Members-Team-Role" [
  organization_id_or_slug: string
  member_id: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --teamRole: string@teamRole-completer # The team-level role to switch to. Valid roles include:  * `contributor` - Contributors can view and act on events, as well as view most other data within the team's projects. * `admin` - Admin privileges on the team. They can create and remove projects, and can manage the team's memberships. (default: contributor)
]: any -> record<isActive: bool, teamRole: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/members/($member_id)/teams/($team_id_or_slug)/")
  let body = {teamRole: $teamRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an organization member from a team.  Note the permission scopes vary depending on the type of authorization token. The following table outlines the accepted scopes. <table style="width: 100%;">     <tr style="width: 50%;">         <td style="width: 50%; text-align: center; font-weight: bold; vertical-align: middle;"><a href="https://docs.sentry.io/api/auth/#auth-tokens">Org Auth Token</a></td>         <td style="width: 50%; text-align: left;">             <ul style="list-style-type: none; padding-left: 0;">                 <li><strong style="color: #9c5f99;">&bull; org:write</strong></li>                 <li><strong style="color: #9c5f99;">&bull; org:admin</strong></li>                 <li><strong style="color: #9c5f99;">&bull; team:admin</strong></li>             </ul>         </td>     </tr>     <tr style="width: 50%;">         <td style="width: 50%; text-align: center; font-weight: bold; vertical-align: middle;"><a href="https://docs.sentry.io/api/auth/#user-authentication-tokens">User Auth Token</a></td>         <td style="width: 50%; text-align: left;">             <ul style="list-style-type: none; padding-left: 0;">                 <li><strong style="color: #9c5f99;">&bull; org:read*</strong></li>                 <li><strong style="color: #9c5f99;">&bull; org:write</strong></li>                 <li><strong style="color: #9c5f99;">&bull; org:admin</strong></li>                 <li><strong style="color: #9c5f99;">&bull; team:admin</strong></li>                 <li><strong style="color: #9c5f99;">&bull; org:read + team:admin**</strong></li>             </ul>         </td>     </tr> </table>   \***`org:read`** can only be used to remove yourself from the teams you are a member of.   \*\*Team Admins must have both **`org:read`** and **`team:admin`** scopes in their user authorization token to delete members from their teams.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/members/{member_id}/teams/{team_id_or_slug}/
# operationId: Delete an Organization Member from a Team
export def "0-organizations-members-teams Delete-an-Organization-Member-from-a-Team" [
  organization_id_or_slug: string
  member_id: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list<string>, hasAccess: bool, isPending: bool, memberCount: int, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/members/($member_id)/teams/($team_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists monitors, including nested monitor environments. May be filtered to a project or environment.
#
# GET /api/0/organizations/{organization_id_or_slug}/monitors/
# operationId: Retrieve Monitors for an Organization
export def "0-organizations-monitors Retrieve-Monitors-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --environment: list # The name of environments to filter by.
  --owner: string # The owner of the monitor, in the format `user:id` or `team:id`. May be specified multiple times.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<alertRule: record<targets: list, environment: string>, id: string, name: string, slug: string, status: string, isMuted: bool, isUpserting: bool, config: record<schedule_type: string, schedule: any, checkin_margin: int, max_runtime: int, timezone: string, failure_issue_threshold: int, recovery_threshold: int, alert_rule_id: int>, dateCreated: string, project: record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list, firstEvent: string, firstTransactionEvent: bool, access: list, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record, color: string, status: string>, environments: record<name: string, status: string, isMuted: bool, dateCreated: string, lastCheckIn: string, nextCheckIn: string, nextCheckInLatest: string, activeIncident: record>, owner: record<type: string, id: string, name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "multi") (serialize-qp "environment" $environment "multi") (serialize-qp "owner" $owner "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/monitors/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new monitor.
#
# POST /api/0/organizations/{organization_id_or_slug}/monitors/
# operationId: Create a Monitor
export def "0-organizations-monitors Create-a-Monitor" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  project: string # The project slug to associate the monitor to.
  name: string # Name of the monitor. Used for notifications. If not set the slug will be derived from your monitor name.
  config: any # The configuration for the monitor.
  --slug: string # Uniquely identifies your monitor within your organization. Changing this slug will require updates to any instrumented check-in calls.
  --status: string@status-completer-1 # Status of the monitor. Disabled monitors will not accept events and will not count towards the monitor quota.  * `active` * `disabled` (default: active)
  --owner: string # The ID of the team or user that owns the monitor. (eg. user:51 or team:6) (nullable)
  --is-muted: string@bool-completer # Disable creation of monitor incidents
]: any -> record<alertRule: record<targets: list<record>, environment: string>, id: string, name: string, slug: string, status: string, isMuted: bool, isUpserting: bool, config: record<schedule_type: string, schedule: any, checkin_margin: int, max_runtime: int, timezone: string, failure_issue_threshold: int, recovery_threshold: int, alert_rule_id: int>, dateCreated: string, project: record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string>, environments: record<name: string, status: string, isMuted: bool, dateCreated: string, lastCheckIn: string, nextCheckIn: string, nextCheckInLatest: string, activeIncident: record<startingTimestamp: string, resolvingTimestamp: string, brokenNotice: record>>, owner: record<type: string, id: string, name: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/monitors/")
  let body = {project: $project, name: $name, config: $config, slug: $slug, status: $status, owner: $owner, is_muted: $is_muted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves details for a monitor.
#
# GET /api/0/organizations/{organization_id_or_slug}/monitors/{monitor_id_or_slug}/
# operationId: Retrieve a Monitor
export def "0-organizations-monitors Retrieve-a-Monitor" [
  organization_id_or_slug: string
  monitor_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
]: nothing -> record<alertRule: record<targets: list<record>, environment: string>, id: string, name: string, slug: string, status: string, isMuted: bool, isUpserting: bool, config: record<schedule_type: string, schedule: any, checkin_margin: int, max_runtime: int, timezone: string, failure_issue_threshold: int, recovery_threshold: int, alert_rule_id: int>, dateCreated: string, project: record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string>, environments: record<name: string, status: string, isMuted: bool, dateCreated: string, lastCheckIn: string, nextCheckIn: string, nextCheckInLatest: string, activeIncident: record<startingTimestamp: string, resolvingTimestamp: string, brokenNotice: record>>, owner: record<type: string, id: string, name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/monitors/($monitor_id_or_slug)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a monitor.
#
# PUT /api/0/organizations/{organization_id_or_slug}/monitors/{monitor_id_or_slug}/
# operationId: Update a Monitor
export def "0-organizations-monitors Update-a-Monitor" [
  organization_id_or_slug: string
  monitor_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  project: string # The project slug to associate the monitor to.
  name: string # Name of the monitor. Used for notifications. If not set the slug will be derived from your monitor name.
  config: any # The configuration for the monitor.
  --slug: string # Uniquely identifies your monitor within your organization. Changing this slug will require updates to any instrumented check-in calls.
  --status: string@status-completer-1 # Status of the monitor. Disabled monitors will not accept events and will not count towards the monitor quota.  * `active` * `disabled` (default: active)
  --owner: string # The ID of the team or user that owns the monitor. (eg. user:51 or team:6) (nullable)
  --is-muted: string@bool-completer # Disable creation of monitor incidents
]: any -> record<alertRule: record<targets: list<record>, environment: string>, id: string, name: string, slug: string, status: string, isMuted: bool, isUpserting: bool, config: record<schedule_type: string, schedule: any, checkin_margin: int, max_runtime: int, timezone: string, failure_issue_threshold: int, recovery_threshold: int, alert_rule_id: int>, dateCreated: string, project: record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string>, environments: record<name: string, status: string, isMuted: bool, dateCreated: string, lastCheckIn: string, nextCheckIn: string, nextCheckInLatest: string, activeIncident: record<startingTimestamp: string, resolvingTimestamp: string, brokenNotice: record>>, owner: record<type: string, id: string, name: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/monitors/($monitor_id_or_slug)/")
  let body = {project: $project, name: $name, config: $config, slug: $slug, status: $status, owner: $owner, is_muted: $is_muted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a monitor or monitor environments.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/monitors/{monitor_id_or_slug}/
# operationId: Delete a Monitor or Monitor Environments
export def "0-organizations-monitors Delete-a-Monitor-or-Monitor-Environments" [
  organization_id_or_slug: string
  monitor_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/monitors/($monitor_id_or_slug)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of check-ins for a monitor
#
# GET /api/0/organizations/{organization_id_or_slug}/monitors/{monitor_id_or_slug}/checkins/
# operationId: Retrieve Check-Ins for a Monitor
export def "0-organizations-monitors-checkins Retrieve-Check-Ins-for-a-Monitor" [
  organization_id_or_slug: string
  monitor_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<groups: list<string>, id: string, environment: string, status: string, duration: int, dateCreated: string, dateAdded: string, dateUpdated: string, dateInProgress: string, dateClock: string, expectedTime: string, monitorConfig: record<schedule_type: string, schedule: any, checkin_margin: int, max_runtime: int, timezone: string, failure_issue_threshold: int, recovery_threshold: int, alert_rule_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/monitors/($monitor_id_or_slug)/checkins/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns all Spike Protection Notification Actions for an organization.  Notification Actions notify a set of members when an action has been triggered through a notification service such as Slack or Sentry. For example, organization owners and managers can receive an email when a spike occurs.  You can use either the `project` or `projectSlug` query parameter to filter for certain projects. Note that if both are present, `projectSlug` takes priority.
#
# GET /api/0/organizations/{organization_id_or_slug}/notifications/actions/
# operationId: List Spike Protection Notifications
export def "0-organizations-notifications-actions List-Spike-Protection-Notifications" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --project-id-or-slug: list # The project slugs to filter by. Use `$all` to include all available projects. For example, the following are valid parameters: - `/?projectSlug=$all` - `/?projectSlug=android&projectSlug=javascript-react`
  --triggerType: string # Type of the trigger that causes the notification. The only supported value right now is: `spike-protection`
]: nothing -> record<id: int, organizationId: int, integrationId: int, sentryAppId: int, projects: list<int>, serviceType: string, triggerType: string, targetType: string, targetIdentifier: string, targetDisplay: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "multi") (serialize-qp "project_id_or_slug" $project_id_or_slug "multi") (serialize-qp "triggerType" $triggerType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/notifications/actions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new Notification Action for Spike Protection.  Notification Actions notify a set of members when an action has been triggered through a notification service such as Slack or Sentry. For example, organization owners and managers can receive an email when a spike occurs.
#
# POST /api/0/organizations/{organization_id_or_slug}/notifications/actions/
# operationId: Create a Spike Protection Notification Action
export def "0-organizations-notifications-actions Create-a-Spike-Protection-Notification-Action" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  trigger_type: string # Type of the trigger that causes the notification. The only supported trigger right now is: `spike-protection`.
  service_type: string # Service that is used for sending the notification. - `email` - `slack` - `sentry_notification` - `pagerduty` - `opsgenie`
  --integration-id: int # ID of the integration used as the notification service. See [List Integrations](https://docs.sentry.io/api/integrations/list-an-organizations-available-integrations/) to retrieve a full list of integrations.  Required if **service_type** is `slack`, `pagerduty` or `opsgenie`.
  --target-identifier: string # ID of the notification target, like a Slack channel ID.  Required if **service_type** is `slack` or `opsgenie`.
  --target-display: string # Name of the notification target, like a Slack channel name.  Required if **service_type** is `slack` or `opsgenie`.
  --projects: list # List of projects slugs that the Notification Action is created for.
]: any -> record<id: int, organizationId: int, integrationId: int, sentryAppId: int, projects: list<int>, serviceType: string, triggerType: string, targetType: string, targetIdentifier: string, targetDisplay: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/notifications/actions/")
  let body = {trigger_type: $trigger_type, service_type: $service_type, integration_id: $integration_id, target_identifier: $target_identifier, target_display: $target_display, projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns a serialized Spike Protection Notification Action object.  Notification Actions notify a set of members when an action has been triggered through a notification service such as Slack or Sentry. For example, organization owners and managers can receive an email when a spike occurs.
#
# GET /api/0/organizations/{organization_id_or_slug}/notifications/actions/{action_id}/
# operationId: Retrieve a Spike Protection Notification Action
export def "0-organizations-notifications-actions Retrieve-a-Spike-Protection-Notification-Action" [
  organization_id_or_slug: string
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, organizationId: int, integrationId: int, sentryAppId: int, projects: list<int>, serviceType: string, triggerType: string, targetType: string, targetIdentifier: string, targetDisplay: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/notifications/actions/($action_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a Spike Protection Notification Action.  Notification Actions notify a set of members when an action has been triggered through a notification service such as Slack or Sentry. For example, organization owners and managers can receive an email when a spike occurs.
#
# PUT /api/0/organizations/{organization_id_or_slug}/notifications/actions/{action_id}/
# operationId: Update a Spike Protection Notification Action
export def "0-organizations-notifications-actions Update-a-Spike-Protection-Notification-Action" [
  organization_id_or_slug: string
  action_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  trigger_type: string # Type of the trigger that causes the notification. The only supported trigger right now is: `spike-protection`.
  service_type: string # Service that is used for sending the notification. - `email` - `slack` - `sentry_notification` - `pagerduty` - `opsgenie`
  --integration-id: int # ID of the integration used as the notification service. See [List Integrations](https://docs.sentry.io/api/integrations/list-an-organizations-available-integrations/) to retrieve a full list of integrations.  Required if **service_type** is `slack`, `pagerduty` or `opsgenie`.
  --target-identifier: string # ID of the notification target, like a Slack channel ID.  Required if **service_type** is `slack` or `opsgenie`.
  --target-display: string # Name of the notification target, like a Slack channel name.  Required if **service_type** is `slack` or `opsgenie`.
  --projects: list # List of projects slugs that the Notification Action is created for.
]: any -> record<id: int, organizationId: int, integrationId: int, sentryAppId: int, projects: list<int>, serviceType: string, triggerType: string, targetType: string, targetIdentifier: string, targetDisplay: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/notifications/actions/($action_id)/")
  let body = {trigger_type: $trigger_type, service_type: $service_type, integration_id: $integration_id, target_identifier: $target_identifier, target_display: $target_display, projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a Spike Protection Notification Action.  Notification Actions notify a set of members when an action has been triggered through a notification service such as Slack or Sentry. For example, organization owners and managers can receive an email when a spike occurs.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/notifications/actions/{action_id}/
# operationId: Delete a Spike Protection Notification Action
export def "0-organizations-notifications-actions Delete-a-Spike-Protection-Notification-Action" [
  organization_id_or_slug: string
  action_id: int
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/notifications/actions/($action_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve install info for a given artifact.  Returns distribution and installation details for a specific preprod artifact, including whether the artifact is installable, the install URL, download count, and iOS-specific code signing information.
#
# GET /api/0/organizations/{organization_id_or_slug}/preprodartifacts/{artifact_id}/install-details/
# operationId: Retrieve install info for a given artifact
export def "0-organizations-preprodartifacts-install-details Retrieve-install-info-for-a-given-artifact" [
  organization_id_or_slug: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<buildId: string, state: string, appInfo: record<appId: string, name: string, version: string, buildNumber: int, artifactType: string, dateAdded: string, dateBuilt: string>, gitInfo: record<headSha: string, baseSha: string, provider: string, headRepoName: string, baseRepoName: string, headRef: string, baseRef: string, prNumber: int>, platform: string, projectId: string, projectSlug: string, buildConfiguration: string, isInstallable: bool, installUrl: string, installUrlExpiresAt: string, downloadCount: int, releaseNotes: string, installGroups: list<string>, isCodeSignatureValid: bool, profileName: string, codesigningType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/preprodartifacts/($artifact_id)/install-details/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve size analysis results for a given artifact.  Returns size metrics including download size, install size, and optional insights. When a base artifact exists (either from commit comparison or via the `baseArtifactId` parameter), comparison data showing size differences is included.  The response `state` field indicates the analysis status: - `PENDING`: Analysis has not started yet. - `PROCESSING`: Analysis is currently running. - `FAILED` / `NOT_RAN`: Analysis did not complete; `errorCode` and `errorMessage` are included. - `COMPLETED`: Analysis finished successfully with full size data.
#
# GET /api/0/organizations/{organization_id_or_slug}/preprodartifacts/{artifact_id}/size-analysis/
# operationId: Retrieve Size Analysis results for a given artifact
export def "0-organizations-preprodartifacts-size-analysis Retrieve-Size-Analysis-results-for-a-given-artifact" [
  organization_id_or_slug: string
  artifact_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --baseArtifactId: string # Optional ID of the base artifact to compare against. If not provided, uses the default base head artifact.
]: nothing -> record<buildId: string, state: string, appInfo: record<appId: string, name: string, version: string, buildNumber: int, artifactType: string, dateAdded: string, dateBuilt: string>, gitInfo: record<headSha: string, baseSha: string, provider: string, headRepoName: string, baseRepoName: string, headRef: string, baseRef: string, prNumber: int>, errorCode: string, errorMessage: string, downloadSize: int, installSize: int, analysisDuration: float, analysisVersion: string, baseBuildId: string, baseAppInfo: record<appId: string, name: string, version: string, buildNumber: int, artifactType: string, dateAdded: string, dateBuilt: string>, insights: record, appComponents: table<componentType: string, name: string, appId: string, path: string, downloadSize: int, installSize: int>, comparisons: table<metricsArtifactType: string, identifier: string, state: string, errorCode: string, errorMessage: string, sizeMetricDiff: record, diffItems: list, insightDiffItems: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "baseArtifactId" $baseArtifactId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/preprodartifacts/($artifact_id)/size-analysis/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve full details for a snapshot, including categorized image lists and comparison status.  When a comparison exists, images are categorized into `changed`, `added`, `removed`, `renamed`, `unchanged`, `errored`, and `skipped` lists with counts. Without a comparison, only the `images` list is populated.  Use `compact_metadata=1` to strip image objects down to `display_name`, `image_file_name`, `group`, and `description` only.  This endpoint requires a bearer token with `project:read` access.
#
# GET /api/0/organizations/{organization_id_or_slug}/preprodartifacts/snapshots/{snapshot_id}/
# operationId: Retrieve Snapshot details
export def "0-organizations-preprodartifacts-snapshots Retrieve-Snapshot-details" [
  organization_id_or_slug: string
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --compact-metadata: string # Set to '1' or 'true' to strip image metadata to display_name, image_file_name, group, and description only.
]: nothing -> record<head_artifact_id: string, base_artifact_id: string, project_id: string, comparison_type: string, state: string, vcs_info: record<head_sha: string, base_sha: string, provider: string, head_repo_name: string, base_repo_name: string, head_ref: string, base_ref: string, pr_number: int>, app_id: string, is_selective: bool, images: table<key: string, display_name: string, group: string, image_file_name: string, width: int, height: int>, image_count: int, added: table<key: string, display_name: string, group: string, image_file_name: string, width: int, height: int>, added_count: int, removed: table<key: string, display_name: string, group: string, image_file_name: string, width: int, height: int>, removed_count: int, renamed: table<base_image: record, head_image: record, diff_image_key: string, diff: float>, renamed_count: int, changed: table<base_image: record, head_image: record, diff_image_key: string, diff: float>, changed_count: int, unchanged: table<key: string, display_name: string, group: string, image_file_name: string, width: int, height: int>, unchanged_count: int, errored: table<base_image: record, head_image: record, diff_image_key: string, diff: float>, errored_count: int, skipped: table<key: string, display_name: string, group: string, image_file_name: string, width: int, height: int>, skipped_count: int, diff_threshold: float, comparison_state: string, approval_status: string, comparison_error_message: string, approvers: table<id: string, name: string, email: string, username: string, avatar_url: string, approved_at: string, source: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "compact_metadata" $compact_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/preprodartifacts/snapshots/($snapshot_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a snapshot and all associated data (images, comparisons, metrics).  This is a permanent, irreversible operation. The snapshot and its images will no longer be accessible after deletion.  This endpoint requires a bearer token with `project:write` access.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/preprodartifacts/snapshots/{snapshot_id}/
# operationId: Delete a Snapshot
export def "0-organizations-preprodartifacts-snapshots Delete-a-Snapshot" [
  organization_id_or_slug: string
  snapshot_id: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/preprodartifacts/snapshots/($snapshot_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download all images in a snapshot as a ZIP archive.  The response is a streaming `application/zip` file. Images that share the same content hash are deduplicated during fetch but written under their original filenames in the archive.  This endpoint requires a bearer token with `project:read` access.
#
# GET /api/0/organizations/{organization_id_or_slug}/preprodartifacts/snapshots/{snapshot_id}/download/
# operationId: Download Snapshot images as ZIP
export def "0-organizations-preprodartifacts-snapshots-download Download-Snapshot-images-as-ZIP" [
  organization_id_or_slug: string
  snapshot_id: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/preprodartifacts/snapshots/($snapshot_id)/download/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve detailed information for a single image within a snapshot.  The `image_identifier` can be either the image filename or its content hash. The response includes head and base image metadata, comparison status, diff image URL, diff percentage, and previous filename for renames.  This endpoint uses a flat response format with nullable fields designed for LLM/MCP consumers.  This endpoint requires a bearer token with `project:read` access.
#
# GET /api/0/organizations/{organization_id_or_slug}/preprodartifacts/snapshots/{snapshot_id}/images/{image_identifier}/
# operationId: Retrieve Snapshot image detail
export def "0-organizations-preprodartifacts-snapshots-images Retrieve-Snapshot-image-detail" [
  organization_id_or_slug: string
  snapshot_id: string
  image_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<image_file_name: string, comparison_status: string, head_image: record<content_hash: string, display_name: string, group: string, image_file_name: string, width: int, height: int, diff_threshold: float, description: string, tags: record, image_url: string>, base_image: record<content_hash: string, display_name: string, group: string, image_file_name: string, width: int, height: int, diff_threshold: float, description: string, tags: record, image_url: string>, diff_image_url: string, diff_percentage: float, previous_image_file_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/preprodartifacts/snapshots/($snapshot_id)/images/($image_identifier)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the most recent base snapshot for a given app.  A base snapshot is one uploaded without a `base_sha` (i.e., a snapshot from a base branch like `main`). Use the optional `branch` and `project` parameters to narrow the search.  The response includes the full image list with download URLs. Use `compact_metadata=1` to reduce image metadata.  This endpoint requires a bearer token with `project:read` access.
#
# GET /api/0/organizations/{organization_id_or_slug}/preprodartifacts/snapshots/latest-base/
# operationId: Retrieve latest base Snapshot
export def "0-organizations-preprodartifacts-snapshots-latest-base Retrieve-latest-base-Snapshot" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-id: string # App identifier to match.
  --branch: string # Git branch name to filter on.
  --project: int # Project ID to scope the lookup.
  --compact-metadata: string # Set to '1' or 'true' to strip image metadata to display_name, image_file_name, group, description, and image_url only.
]: nothing -> record<head_artifact_id: string, project_id: string, project_slug: string, app_id: string, image_count: int, images: table<key: string, display_name: string, group: string, image_file_name: string, width: int, height: int, image_url: string>, diff_threshold: float, date_added: string, vcs_info: record<head_sha: string, base_sha: string, head_ref: string, base_ref: string, head_repo_name: string, pr_number: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_id" $app_id "scalar") (serialize-qp "branch" $branch "scalar") (serialize-qp "project" $project "scalar") (serialize-qp "compact_metadata" $compact_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/preprodartifacts/snapshots/latest-base/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve continuous profiling data for a profiler over a time range.  Exactly one project must be specified via the `project` query parameter.  Requires continuous profiling to be enabled for the organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/profiling/chunks/
# operationId: Retrieve Profile Chunks for an Organization
export def "0-organizations-profiling-chunks Retrieve-Profile-Chunks-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: int # The ID of the project to fetch chunks for. Exactly one project must be specified.
  --profiler-id: string # The continuous-profiler ID to fetch chunks for.
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "scalar") (serialize-qp "profiler_id" $profiler_id "scalar") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/profiling/chunks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an aggregated flamegraph for the organization, built from the requested data source (transactions, profiles, functions, or spans).  Pass `expand=metrics` to include aggregated function metrics in the response.  Requires profiling to be enabled for the organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/profiling/flamegraph/
# operationId: Retrieve a Flamegraph for an Organization
export def "0-organizations-profiling-flamegraph Retrieve-a-Flamegraph-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --environment: list # The name of environments to filter by.
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --dataSource: string@dataSource-completer # Source dataset to build the flamegraph from. Defaults to `functions` when `fingerprint` is set and `transactions` otherwise.
  --fingerprint: int # A UInt32 function fingerprint. Only valid when `dataSource=functions`.
  --qp-query: string # Sentry [search syntax](https://docs.sentry.io/concepts/search/) to filter the candidate profiles.
  --expand: list # Optional expansions. Pass `metrics` to include flamegraph metric aggregates in the response.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "multi") (serialize-qp "environment" $environment "multi") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "dataSource" $dataSource "scalar") (serialize-qp "fingerprint" $fingerprint "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/profiling/flamegraph/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of client keys (DSNs) for all projects in an organization.  This paginated endpoint lists client keys across all projects in an organization. Each key includes the project ID to identify which project it belongs to.  Query Parameters: - team: Filter by team slug or ID to get keys only for that team's projects - status: Filter by 'active' or 'inactive' to get keys with specific status
#
# GET /api/0/organizations/{organization_id_or_slug}/project-keys/
# operationId: List an Organization's Client Keys
export def "0-organizations-project-keys List-an-Organizations-Client-Keys" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --team: string # Filter keys by team slug or ID. If provided, only keys for projects belonging to this team will be returned.
  --status: string@status-completer-2 # Filter keys by status. Options are 'active' or 'inactive'.  * `active` * `inactive`
]: nothing -> table<id: string, name: string, label: string, public: string, secret: string, projectId: int, isActive: bool, rateLimit: record<window: int, count: int>, dsn: record<secret: string, public: string, csp: string, security: string, minidump: string, nel: string, unreal: string, crons: string, cdn: string, playstation: string, integration: string, otlp_traces: string, otlp_logs: string>, browserSdkVersion: string, browserSdk: record<choices: list>, dateCreated: string, dynamicSdkLoaderOptions: record<hasReplay: bool, hasPerformance: bool, hasDebug: bool, hasFeedback: bool, hasLogsAndMetrics: bool>, useCase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/project-keys/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of projects bound to a organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/projects/
# operationId: List an Organization's Projects
export def "0-organizations-projects List-an-Organizations-Projects" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
  --qp-query: string # Filter projects by name or slug.
]: nothing -> table<latestDeploys: record, options: record, stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, team: record<id: string, name: string, slug: string>, teams: list<record>, platforms: list<string>, hasUserReports: bool, environments: list<string>, latestRelease: record<version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/projects/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new project for an organization. A personal team (`team-{username}`) is automatically created for the caller with Team Admin role, and the project is bound to it. If the org has member project creation disabled (`disable_member_project_creation`), `org:write` scope is required.
#
# POST /api/0/organizations/{organization_id_or_slug}/projects/
# operationId: Create a Project for an Organization
export def "0-organizations-projects Create-a-Project-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name for the project.
  --slug: string # Uniquely identifies a project and is used for the interface.         If not provided, it is automatically generated from the name. (nullable)
  --platform: string # The platform for the project. (nullable)
  --default-rules: string@bool-completer #  Defaults to true where the behavior is to alert the user on every new issue. Setting this to false will turn this off and the user must create their own alerts to be notified of new issues.         
]: any -> record<latestDeploys: record, options: record, stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, team: record<id: string, name: string, slug: string>, teams: table<id: string, name: string, slug: string>, platforms: list<string>, hasUserReports: bool, environments: list<string>, latestRelease: record<version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/projects/")
  let body = {name: $name, slug: $slug, platform: $platform, default_rules: $default_rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Monitor for a project
#
# POST /api/0/organizations/{organization_id_or_slug}/projects/{project_id_or_slug}/detectors/
# operationId: Create a Monitor for a Project
export def "0-organizations-projects-detectors Create-a-Monitor-for-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the monitor.
  type: string # The type of monitor - `metric_issue`.
  --workflow-ids: list # The IDs of the alerts to connect this monitor to. Use the 'Fetch Alerts' endpoint to find the IDs.
  --data-sources: list #              The data sources for the monitor to use based on what you want to measure.              **Number of Errors Metric Monitor**             - `eventTypes`: Any of `error` or `default`.             ```json                 [                     {                         "aggregate": "count()",                         "dataset" : "events",                         "environment": "prod",                         "eventTypes": ["default", "error"],                         "query": "is:unresolved",                         "queryType": 0,                         "timeWindow": 3600,                     },                 ],             ```              **Users Experiencing Errors Metric Monitor**             - `eventTypes`: Any of `error` or `default`.             ```json                 [                     {                         "aggregate": "count_unique(tags[sentry:user])",                         "dataset" : "events",                         "environment": "prod",                         "eventTypes": ["default", "error"],                         "query": "is:unresolved",                         "queryType": 0,                         "timeWindow": 3600,                     },                 ],             ```               **Throughput Metric Monitor**             ```json                 [                     {                         "aggregate":"count(span.duration)",                         "dataset":"events_analytics_platform",                         "environment":"prod",                         "eventTypes":["trace_item_span"]                         "query":"",                         "queryType":1,                         "timeWindow":3600,                         "extrapolationMode":"unknown",                     },                 ],             ```              **Duration Metric Monitor**             ```json                 [                     {                         "aggregate":"p95(span.duration)",                         "dataset":"events_analytics_platform",                         "environment":"prod",                         "eventTypes":["trace_item_span"]                         "query":"",                         "queryType":1,                         "timeWindow":3600,                         "extrapolationMode":"unknown",                     },                 ],             ```              **Failure Rate Metric Monitor**             ```json                 [                     {                         "aggregate":"failure_rate()",                         "dataset":"events_analytics_platform",                         "environment":"prod",                         "eventTypes":["trace_item_span"]                         "query":"",                         "queryType":1,                         "timeWindow":3600,                         "extrapolationMode":"unknown",                     },                 ],             ```              **Largest Contentful Paint Metric Monitor**             - `dataset`: If a custom percentile is used, dataset is `transactions`. Otherwise, dataset is `events_analytics_platform`.             - `aggregate`: Valid values are `avg(measurements.lcp)`, `p50(measurements.lcp)`, `p75(measurements.lcp)`, `p95(measurements.lcp)`, `p99(measurements.lcp)`, `p100(measurements.lcp)`, and `percentile(measurements.lcp,x)`, where `x` is your custom percentile.              ```json                 [                     {                         "aggregate":"p95(measurements.lcp)",                         "dataset":"events_analytics_platform",                         "environment":"prod",                         "eventTypes":["trace_item_span"]                         "query":"",                         "queryType":1,                         "timeWindow":3600,                         "extrapolationMode":"unknown",                     },                 ],             ```              **Custom Metric Monitor**             - `dataset`: If a custom percentile is used, dataset is `transactions`. Otherwise, dataset is `events_analytics_platform`.             - `aggregate`: Valid values are:             `avg(x)`, where `x` is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p50(x)`, where `x` is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p75(x)`, where x is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p95(x)`, where x is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p99(x)`, where x is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `p100(x)`, where `x` is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`.             `percentile(x,y)`, where `x` is `transaction.duration`, `measurements.cls`, `measurements.fcp`, `measurements.fid`, `measurements.fp`, `measurements.lcp`, `measurements.ttfb`, or `measurements.ttfb.requesttime`, and `y` is the custom percentile.             `failure_rate()`             `apdex(x)`, where `x` is the value of the Apdex score.             `count()`              ```json             [                 {                     "aggregate": "p75(measurements.ttfb)"                     "dataset": "events_analytics_platform",                     "queryType": 1,                 },             ],
  --config: record #              The issue detection type configuration.               - `detectionType`                 - `static`: Threshold based monitor                 - `percent`: Change based monitor                 - `dynamic`: Dynamic monitor             - `comparisonDelta`: If selecting a **change** detection type, the comparison delta is the time period at which to compare against in minutes.             For example, a value of 3600 compares the metric tracked against data 1 hour ago.                 - `300`: 5 minutes                 - `900`: 15 minutes                 - `3600`: 1 hour                 - `86400`: 1 day                 - `604800`: 1 week                 - `2592000`: 1 month              **Threshold**             ```json             {                 "detectionType": "static",             }             ```             **Change**             ```json             {                 "detectionType": "percent",                 "comparisonDelta": 3600,             }             ```             **Dynamic**             ```json             {                 "detectionType": "dynamic",             }             ```         
  --condition-group: any #              Issue detection configuration for when to create an issue and at what priority level.               - `logicType`: `any`             - `type`: Any of `gt` (greater than), `lte` (less than or equal), or `anomaly_detection` (dynamic)             - `comparison`: Any positive integer. This is threshold that must be crossed for the monitor to create an issue, e.g. "Create a metric issue when there are more than 5 unresolved error events".                 - If creating a **dynamic** monitor, see the options below.                     - `seasonality`: `auto`                     - `sensitivity`: Level of responsiveness. Options are one of `low`, `medium`, or `high`                     - `thresholdType`: If you want to be alerted to anomalies that are moving above, below, or in both directions in relation to your threshold.                         - `0`: Above                         - `1`: Below                         - `2`: Above and below              - `conditionResult`: The issue state change when the threshold is crossed.                 - `75`: High priority                 - `50`: Low priority                 - `0`: Resolved               **Threshold and Change Monitor**             ```json                 "logicType": "any",                 "conditions": [                     {                         "type": "gt",                         "comparison": 10,                         "conditionResult": 75                     },                     {                         "type": "lte",                         "comparison": 10,                         "conditionResult": 0                     }                 ],                 "actions": []             ```              **Threshold Monitor with Medium Priority**             ```json                 "logicType": "any",                 "conditions": [                     {                         type: "gt",                         comparison: 5,                         conditionResult: 75                     },                     {                         type: "gt",                         comparison: 2,                         conditionResult: 50                     },                     {                         type: "lte",                         comparison: 2,                         conditionResult: 0                     }                 ],                 "actions": []             ```              **Dynamic Monitor**             ```json                 "logicType": "any",                 "conditions": [                     {                         "type": "anomaly_detection",                         "comparison": {                             "seasonality": "auto",                             "sensitivity": "medium",                             "thresholdType": 2                         },                         "conditionResult": 75                     }                 ],                 "actions": []             ```         
  --owner: string #              The ID user or team who owns the monitor or alert prefaced by the string 'user' or 'team'.              **User**             ```json                 "user:123456"             ```              **Team**             ```json                 "team:456789"             ```          (nullable)
  --description: string # A description of the monitor. Will be used in the resulting issue. (nullable)
  --enabled: string@bool-completer # Set to False if you want to disable the monitor.
]: any -> record<owner: record<type: string, id: string, name: string, email: string>, createdBy: string, latestGroup: record, description: string, id: string, projectId: string, name: string, type: string, workflowIds: list<string>, dateCreated: string, dateUpdated: string, dataSources: list<record>, conditionGroup: record, config: record, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/projects/($project_id_or_slug)/detectors/")
  let body = {name: $name, type: $type, workflow_ids: $workflow_ids, data_sources: $data_sources, config: $config, condition_group: $condition_group, owner: $owner, description: $description, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of trusted relays bound to an organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/relay_usage/
# operationId: List an Organization's trusted Relays
export def "0-organizations-relay-usage List-an-Organizations-trusted-Relays" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<relayId: string, version: string, publicKey: string, firstSeen: string, lastSeen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/relay_usage/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **`[WARNING]`**: This API is an experimental Alpha feature and is subject to change!  List all derived statuses of releases that fall within the provided start/end datetimes.  Constructs a response key'd off \{`release_version`\}-\{`project_slug`\} that lists thresholds with their status for *specified* projects. Each returned enriched threshold will contain the full serialized `release_threshold` instance as well as it's derived health statuses.
#
# GET /api/0/organizations/{organization_id_or_slug}/release-threshold-statuses/
# operationId: Retrieve Statuses of Release Thresholds (Alpha)
export def "0-organizations-release-threshold-statuses Retrieve-Statuses-of-Release-Thresholds-Alpha" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `end`. (format: date-time)
  --end: string # The inclusive end of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `start`. (format: date-time)
  --environment: list # A list of environment names to filter your results by.
  --projectSlug: list # A list of project slugs to filter your results by.
  --release: list # A list of release versions to filter your results by.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "environment" $environment "multi") (serialize-qp "projectSlug" $projectSlug "multi") (serialize-qp "release" $release "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/release-threshold-statuses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return details on an individual release.
#
# GET /api/0/organizations/{organization_id_or_slug}/releases/{version}/
# operationId: Retrieve an Organization's Release
export def "0-organizations-releases Retrieve-an-Organizations-Release" [
  organization_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project-id: string # The project ID to filter by.
  --health: string@bool-completer # Whether or not to include health data with the release. By default, this is false.
  --adoptionStages: string@bool-completer # Whether or not to include adoption stages with the release. By default, this is false.
  --summaryStatsPeriod: string@summaryStatsPeriod-completer # The period of time used to query summary stats for the release. By default, this is 14d.
  --healthStatsPeriod: string@healthStatsPeriod-completer # The period of time used to query health stats for the release. By default, this is 24h if health is enabled.
  --qp-sort: string@sort-completer-1 # The field used to sort results by. By default, this is `date`.
  --status: string@status-completer-3 # Release statuses that you can filter by.
  --qp-query: string # Filters results by using [query syntax](/product/sentry-basics/search/).  Example: `query=(transaction:foo AND release:abc) OR (transaction:[bar,baz] AND release:def)`
]: nothing -> record<ref: string, url: string, dateReleased: string, dateCreated: string, dateStarted: string, owner: record, lastCommit: record, lastDeploy: record<dateStarted: string, url: string, id: string, environment: string, dateFinished: string, name: string>, firstEvent: string, lastEvent: string, currentProjectMeta: record, userAgent: string, adoptionStages: record, id: int, version: string, newGroups: int, status: string, shortVersion: string, versionInfo: record<description: string, package: string, version: record, buildHash: string>, data: record, commitCount: int, deployCount: int, authors: list<any>, projects: table<healthData: record, dateReleased: string, dateCreated: string, dateStarted: string, id: int, slug: string, name: string, platform: string, platforms: list, hasHealthData: bool, newGroups: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project_id" $project_id "scalar") (serialize-qp "health" $health "scalar") (serialize-qp "adoptionStages" $adoptionStages "scalar") (serialize-qp "summaryStatsPeriod" $summaryStatsPeriod "scalar") (serialize-qp "healthStatsPeriod" $healthStatsPeriod "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a release. This can change some metadata associated with the release (the ref, url, and dates).
#
# PUT /api/0/organizations/{organization_id_or_slug}/releases/{version}/
# operationId: Update an Organization's Release
# --commits item shape: {id: string, repository?: string, message?: string, author_name?: string, author_email?: string, timestamp?: string, patch_set?: list}
# --refs item shape: {commit: string, repository: string, previousCommit?: string}
export def "0-organizations-releases Update-an-Organizations-Release" [
  organization_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ref: string # An optional commit reference. This is useful if a tagged version has been provided. (nullable)
  --body-url: string # A URL that points to the release. For instance, this can be the path to an online interface to the source code, such as a GitHub URL. (nullable, format: uri)
  --dateReleased: string # An optional date that indicates when the release went live.  If not provided the current time is used. (nullable, format: date-time)
  --commits: list # An optional list of commit data to be associated. — item shape: {id: string, repository?: string, message?: string, author_name?: string, author_email?: string, timestamp?: string, patch_set?: list}
  --refs: list # An optional way to indicate the start and end commits for each repository included in a release. Head commits must include parameters ``repository`` and ``commit`` (the HEAD SHA). For GitLab repositories, please use the Group name instead of the slug. They can optionally include ``previousCommit`` (the SHA of the HEAD of the previous release), which should be specified if this is the first time you've sent commit data. — item shape: {commit: string, repository: string, previousCommit?: string}
]: any -> record<ref: string, url: string, dateReleased: string, dateCreated: string, dateStarted: string, owner: record, lastCommit: record, lastDeploy: record<dateStarted: string, url: string, id: string, environment: string, dateFinished: string, name: string>, firstEvent: string, lastEvent: string, currentProjectMeta: record, userAgent: string, adoptionStages: record, id: int, version: string, newGroups: int, status: string, shortVersion: string, versionInfo: record<description: string, package: string, version: record, buildHash: string>, data: record, commitCount: int, deployCount: int, authors: list<any>, projects: table<healthData: record, dateReleased: string, dateCreated: string, dateStarted: string, id: int, slug: string, name: string, platform: string, platforms: list, hasHealthData: bool, newGroups: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/")
  let body = {ref: $ref, url: $body_url, dateReleased: $dateReleased, commits: $commits, refs: $refs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Permanently remove a release and all of its files.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/releases/{version}/
# operationId: Delete an Organization's Release
export def "0-organizations-releases Delete-an-Organizations-Release" [
  organization_id_or_slug: string
  version: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of deploys based on the organization, version, and project.
#
# GET /api/0/organizations/{organization_id_or_slug}/releases/{version}/deploys/
# operationId: List a Release's Deploys
export def "0-organizations-releases-deploys List-a-Releases-Deploys" [
  organization_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, environment: string, dateStarted: string, dateFinished: string, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/deploys/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a deploy for a given release.
#
# POST /api/0/organizations/{organization_id_or_slug}/releases/{version}/deploys/
# operationId: Create a Deploy
export def "0-organizations-releases-deploys Create-a-Deploy" [
  organization_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  environment: string # The environment you're deploying to
  --name: string # The optional name of the deploy (nullable)
  --body-url: string # The optional URL that points to the deploy (nullable, format: uri)
  --dateStarted: string # An optional date that indicates when the deploy started (nullable, format: date-time)
  --dateFinished: string # An optional date that indicates when the deploy ended. If not provided, the current time is used. (nullable, format: date-time)
  --projects: list # The optional list of project slugs to create a deploy within. If not provided, deploys are created for all of the release's projects.
]: any -> record<id: string, environment: string, dateStarted: string, dateFinished: string, name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/deploys/")
  let body = {environment: $environment, name: $name, url: $body_url, dateStarted: $dateStarted, dateFinished: $dateFinished, projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Count of Replays for a Given Issue or Transaction
#
# GET /api/0/organizations/{organization_id_or_slug}/replay-count/
# operationId: getOrganizationReplayCount
export def "0-organizations-replay-count get" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --project-id-or-slug: list # The project slugs to filter by. Use `$all` to include all available projects. For example, the following are valid parameters: - `/?projectSlug=$all` - `/?projectSlug=android&projectSlug=javascript-react`
  --qp-query: string # Filters results by using [query syntax](/product/sentry-basics/search/).  Example: `query=(transaction:foo AND release:abc) OR (transaction:[bar,baz] AND release:def)`
  --data-source: string@data-source-completer # The data source to query replays from. Defaults to 'discover'.
  --returnIds: string@bool-completer # If true, return issue IDs rather than counts.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "project" $project "multi") (serialize-qp "project_id_or_slug" $project_id_or_slug "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "data_source" $data_source "scalar") (serialize-qp "returnIds" $returnIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/replay-count/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an Organization's Selectors
#
# GET /api/0/organizations/{organization_id_or_slug}/replay-selectors/
# operationId: listOrganizationReplaySelectors
export def "0-organizations-replay-selectors listOrganizationReplaySelectors" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The environment to filter by.
  --statsPeriod: string # This defines the range of the time series, relative to now. The range is given in a `<number><unit>` format. For example `1d` for a one day range. Possible units are `m` for minutes, `h` for hours, `d` for days and `w` for weeks.You must either provide a `statsPeriod`, or a `start` and `end`.
  --start: string # This defines the start of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds.Use along with `end` instead of `statsPeriod`. (format: date-time)
  --end: string # This defines the inclusive end of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds.Use along with `start` instead of `statsPeriod`. (format: date-time)
  --project: list # The ID of the projects to filter by.
  --projectSlug: list # A list of project slugs to filter your results by.
  --qp-sort: string # The field to sort the output by.
  --sortBy: string # The field to sort the output by.
  --orderBy: string # The field to sort the output by.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
  --qp-query: string # Filters results by using [query syntax](/product/sentry-basics/search/).  Example: `query=(transaction:foo AND release:abc) OR (transaction:[bar,baz] AND release:def)`
]: nothing -> record<data: table<count_dead_clicks: int, count_rage_clicks: int, dom_element: string, element: record, project_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "project" $project "multi") (serialize-qp "projectSlug" $projectSlug "multi") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/replay-selectors/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an Organization's Replays
#
# GET /api/0/organizations/{organization_id_or_slug}/replays/
# operationId: listOrganizationReplays
export def "0-organizations-replays listOrganizationReplays" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statsPeriod: string #  This defines the range of the time series, relative to now. The range is given in a `<number><unit>` format. For example `1d` for a one day range. Possible units are `m` for minutes, `h` for hours, `d` for days and `w` for weeks. You must either provide a `statsPeriod`, or a `start` and `end`.
  --start: string #  This defines the start of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `end` instead of `statsPeriod`.  (format: date-time)
  --end: string #  This defines the inclusive end of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `start` instead of `statsPeriod`.  (format: date-time)
  --field: list # Specifies a field that should be marshaled in the output. Invalid fields will be rejected.
  --project: list # The ID of the projects to filter by.
  --projectSlug: list # A list of project slugs to filter your results by.
  --environment: string # The environment to filter by.
  --qp-sort: string # The field to sort the output by.
  --sortBy: string # The field to sort the output by.
  --orderBy: string # The field to sort the output by.
  --qp-query: string # A structured query string to filter the output by.
  --per-page: int # Limit the number of rows to return in the result.
  --cursor: string # The cursor parameter is used to paginate results. See [here](https://docs.sentry.io/api/pagination/) for how to use this query parameter
]: nothing -> record<data: table<id: string, project_id: string, trace_ids: list, error_ids: list, environment: string, tags: any, user: record, sdk: record, os: record, browser: record, device: record, ota_updates: record, is_archived: bool, urls: list, clicks: list, count_dead_clicks: int, count_rage_clicks: int, count_errors: int, duration: int, finished_at: string, started_at: string, activity: int, count_urls: int, replay_type: string, count_segments: int, platform: string, releases: list, dist: string, count_warnings: int, count_infos: int, has_viewed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "field" $field "multi") (serialize-qp "project" $project "multi") (serialize-qp "projectSlug" $projectSlug "multi") (serialize-qp "environment" $environment "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/replays/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Replay Instance
#
# GET /api/0/organizations/{organization_id_or_slug}/replays/{replay_id}/
# operationId: getOrganizationReplay
export def "0-organizations-replays get" [
  organization_id_or_slug: string
  replay_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statsPeriod: string #  This defines the range of the time series, relative to now. The range is given in a `<number><unit>` format. For example `1d` for a one day range. Possible units are `m` for minutes, `h` for hours, `d` for days and `w` for weeks. You must either provide a `statsPeriod`, or a `start` and `end`.
  --start: string #  This defines the start of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `end` instead of `statsPeriod`.  (format: date-time)
  --end: string #  This defines the inclusive end of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `start` instead of `statsPeriod`.  (format: date-time)
  --field: list # Specifies a field that should be marshaled in the output. Invalid fields will be rejected.
  --project: list # The ID of the projects to filter by.
  --projectSlug: list # A list of project slugs to filter your results by.
  --environment: string # The environment to filter by.
  --qp-sort: string # The field to sort the output by.
  --sortBy: string # The field to sort the output by.
  --orderBy: string # The field to sort the output by.
  --qp-query: string # A structured query string to filter the output by.
  --per-page: int # Limit the number of rows to return in the result.
  --cursor: string # The cursor parameter is used to paginate results. See [here](https://docs.sentry.io/api/pagination/) for how to use this query parameter
]: nothing -> record<data: record<id: string, project_id: string, trace_ids: list<string>, error_ids: list<string>, environment: string, tags: any, user: record<id: string, username: string, email: string, ip: string, display_name: string, geo: record>, sdk: record<name: string, version: string>, os: record<name: string, version: string>, browser: record<name: string, version: string>, device: record<name: string, brand: string, model: string, family: string>, ota_updates: record<channel: string, runtime_version: string, update_id: string>, is_archived: bool, urls: list<string>, clicks: list<record>, count_dead_clicks: int, count_rage_clicks: int, count_errors: int, duration: int, finished_at: string, started_at: string, activity: int, count_urls: int, replay_type: string, count_segments: int, platform: string, releases: list<string>, dist: string, count_warnings: int, count_infos: int, has_viewed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "field" $field "multi") (serialize-qp "project" $project "multi") (serialize-qp "projectSlug" $projectSlug "multi") (serialize-qp "environment" $environment "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/replays/($replay_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of version control repositories for a given organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/repos/
# operationId: List an Organization's Repositories
export def "0-organizations-repos List-an-Organizations-Repositories" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Filter repositories by name.
  --status: string@status-completer-4 # Filter repositories by status. Defaults to `active`.
  --integration-id: string # Filter repositories by integration ID.
  --expand: list # Optional repository fields to expand, such as `settings`.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<url: string, provider: record, status: string, integrationId: string, externalSlug: string, externalId: string, settings: record<enabledCodeReview: bool, codeReviewTriggers: list>, id: string, name: string, dateCreated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "integration_id" $integration_id "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/repos/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a Repository's Commits
#
# GET /api/0/organizations/{organization_id_or_slug}/repos/{repo_id}/commits/
# operationId: List a Repository's Commits
export def "0-organizations-repos-commits List-a-Repositorys-Commits" [
  organization_id_or_slug: string
  repo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, message: string, dateCreated: string, pullRequest: record<id: string, title: string, message: string, dateCreated: string, repository: record, author: any, externalUrl: string>, suspectCommitType: string, repository: record<url: string, provider: record, status: string, integrationId: string, externalSlug: string, externalId: string, settings: record, id: string, name: string, dateCreated: string>, author: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/repos/($repo_id)/commits/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a paginated list of teams bound to a organization with a SCIM Groups GET Request.  Note that the members field will only contain up to 10,000 members.
#
# GET /api/0/organizations/{organization_id_or_slug}/scim/v2/Groups
# operationId: List an Organization's Paginated Teams
export def "0-organizations-scim-groups List-an-Organizations-Paginated-Teams" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startIndex: int # SCIM 1-offset based index for pagination. (default: 1)
  --count: int # The maximum number of results the query should return, maximum of 100. (default: 100)
  --filter: string # A SCIM filter expression. The only operator currently supported is `eq`.
  --excludedAttributes: list # Fields that should be left off of return values. Right now the only supported field for this query is members.
]: nothing -> record<schemas: list<string>, totalResults: int, startIndex: int, itemsPerPage: int, Resources: table<schemas: list, id: string, displayName: string, meta: record, members: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new team bound to an organization via a SCIM Groups POST Request. The slug will have a normalization of uppercases/spaces to lowercases and dashes.  Note that teams are always created with an empty member set.
#
# POST /api/0/organizations/{organization_id_or_slug}/scim/v2/Groups
# operationId: Provision a New Team
export def "0-organizations-scim-groups Provision-a-New-Team" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string # The slug of the team that is shown in the UI.
]: any -> record<schemas: list<string>, id: string, displayName: string, meta: record<resourceType: string>, members: table<value: string, display: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Groups")
  let body = {displayName: $displayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query an individual team with a SCIM Group GET Request. - Note that the members field will only contain up to 10000 members.
#
# GET /api/0/organizations/{organization_id_or_slug}/scim/v2/Groups/{team_id_or_slug}
# operationId: Query an Individual Team
export def "0-organizations-scim-groups Query-an-Individual-Team" [
  team_id_or_slug: string
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<schemas: list<string>, id: string, displayName: string, meta: record<resourceType: string>, members: table<value: string, display: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Groups/($team_id_or_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team's attributes with a SCIM Group PATCH Request.
#
# PATCH /api/0/organizations/{organization_id_or_slug}/scim/v2/Groups/{team_id_or_slug}
# operationId: Update a Team's Attributes
# --Operations item shape: {op: string, value?: record, path?: string}
export def "0-organizations-scim-groups Update-a-Teams-Attributes" [
  organization_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Operations: list # The list of operations to perform. Valid operations are: * Renaming a team: ```json {     "Operations": [{         "op": "replace",         "value": {             "id": 23,             "displayName": "newName"         }     }] } ``` * Adding a member to a team: ```json {     "Operations": [{         "op": "add",         "path": "members",         "value": [             {                 "value": 23,                 "display": "testexample@example.com"             }         ]     }] } ``` * Removing a member from a team: ```json {     "Operations": [{         "op": "remove",         "path": "members[value eq "23"]"     }] } ``` * Replacing an entire member set of a team: ```json {     "Operations": [{         "op": "replace",         "path": "members",         "value": [             {                 "value": 23,                 "display": "testexample2@sentry.io"             },             {                 "value": 24,                 "display": "testexample3@sentry.io"             }         ]     }] } ``` — item shape: {op: string, value?: record, path?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Groups/($team_id_or_slug)")
  let body = {Operations: $Operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a team with a SCIM Group DELETE Request.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/scim/v2/Groups/{team_id_or_slug}
# operationId: Delete an Individual Team
export def "0-organizations-scim-groups Delete-an-Individual-Team" [
  organization_id_or_slug: string
  team_id_or_slug: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Groups/($team_id_or_slug)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a paginated list of members bound to a organization with a SCIM Users GET Request.
#
# GET /api/0/organizations/{organization_id_or_slug}/scim/v2/Users
# operationId: List an Organization's SCIM Members
export def "0-organizations-scim-users List-an-Organizations-SCIM-Members" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startIndex: int # SCIM 1-offset based index for pagination. (default: 1)
  --count: int # The maximum number of results the query should return, maximum of 100. (default: 100)
  --filter: string # A SCIM filter expression. The only operator currently supported is `eq`.
  --excludedAttributes: list # Fields that should be left off of return values. Right now the only supported field for this query is members.
]: nothing -> record<schemas: list<string>, totalResults: int, startIndex: int, itemsPerPage: int, Resources: table<active: bool, schemas: list, id: string, userName: string, name: record, emails: list, meta: record, sentryOrgRole: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "excludedAttributes" $excludedAttributes "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new Organization Member via a SCIM Users POST Request.  Note that this API does not support setting secondary emails.
#
# POST /api/0/organizations/{organization_id_or_slug}/scim/v2/Users
# operationId: Provision a New Organization Member
export def "0-organizations-scim-users Provision-a-New-Organization-Member" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userName: string # The SAML field used for email. (format: email)
  --sentryOrgRole: string@sentryOrgRole-completer # The organization role of the member. If unspecified, this will be                     set to the organization's default role. The options are:  * `billing` - Can manage payment and compliance details. * `member` - Can view and act on events, as well as view most other data within the organization. * `manager` - Has full management access to all teams and projects. Can also manage         the organization's membership. * `admin` - Can edit global integrations, manage projects, and add/remove teams.         They automatically assume the Team Admin role for teams they join.         Note: This role can no longer be assigned in Business and Enterprise plans. Use `TeamRoles` instead.         
]: any -> record<active: bool, schemas: list<string>, id: string, userName: string, name: record<givenName: string, familyName: string>, emails: table<primary: bool, value: string, type: string>, meta: record<resourceType: string>, sentryOrgRole: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Users")
  let body = {userName: $userName, sentryOrgRole: $sentryOrgRole} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query an individual organization member with a SCIM User GET Request. - The `name` object will contain fields `firstName` and `lastName` with the values of `N/A`. Sentry's SCIM API does not currently support these fields but returns them for compatibility purposes.
#
# GET /api/0/organizations/{organization_id_or_slug}/scim/v2/Users/{member_id}
# operationId: Query an Individual Organization Member
export def "0-organizations-scim-users Query-an-Individual-Organization-Member" [
  organization_id_or_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, schemas: list<string>, id: string, userName: string, name: record<givenName: string, familyName: string>, emails: table<primary: bool, value: string, type: string>, meta: record<resourceType: string>, sentryOrgRole: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Users/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization member's attributes with a SCIM PATCH Request.
#
# PATCH /api/0/organizations/{organization_id_or_slug}/scim/v2/Users/{member_id}
# operationId: Update an Organization Member's Attributes
# --Operations item shape: {op: string, value: any, path?: string}
export def "0-organizations-scim-users Update-an-Organization-Members-Attributes" [
  organization_id_or_slug: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Operations: list # A list of operations to perform. Currently, the only valid operation is setting a member's `active` attribute to false, after which the member will be permanently deleted. ```json {     "Operations": [{         "op": "replace",         "path": "active",         "value": False     }] } ``` — item shape: {op: string, value: any, path?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Users/($member_id)")
  let body = {Operations: $Operations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an organization member with a SCIM User DELETE Request.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/scim/v2/Users/{member_id}
# operationId: Delete an Organization Member via SCIM
export def "0-organizations-scim-users Delete-an-Organization-Member-via-SCIM" [
  organization_id_or_slug: string
  member_id: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/scim/v2/Users/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the custom integrations for an organization
#
# GET /api/0/organizations/{organization_id_or_slug}/sentry-apps/
# operationId: Retrieve the custom integrations created by an organization
export def "0-organizations-sentry-apps Retrieve-the-custom-integrations-created-by-an-organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<allowedOrigins: list<string>, avatars: list<record>, events: list<string>, featureData: list<string>, isAlertable: bool, metadata: string, name: string, schema: string, scopes: list<string>, slug: string, status: string, uuid: string, verifyInstall: bool, isDisabled: bool, author: string, overview: string, popularity: int, redirectUrl: string, webhookUrl: string, clientSecret: string, datePublished: string, clientId: string, owner: record<id: int, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/sentry-apps/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a time series of release health session statistics for projects bound to an organization.  The interval and date range are subject to certain restrictions and rounding rules.  The date range is rounded to align with the interval, and is rounded to at least one hour. The interval can at most be one day and at least one hour currently. It has to cleanly divide one day, for rounding reasons.  Because of technical limitations, this endpoint returns at most 10000 data points. For example, if you select a 90 day window grouped by releases, you will see at most `floor(10k / (90 + 1)) = 109` releases. To get more results, reduce the `statsPeriod`.
#
# GET /api/0/organizations/{organization_id_or_slug}/sessions/
# operationId: Retrieve Release Health Session Statistics
export def "0-organizations-sessions Retrieve-Release-Health-Session-Statistics" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: list # The list of fields to query.  The available fields are - `sum(session)` - `count_unique(user)` - `avg`, `p50`, `p75`, `p90`, `p95`, `p99`, `max` applied to `session.duration`. For example, `p99(session.duration)`. Session duration is [no longer being recorded](https://github.com/getsentry/sentry/discussions/42716) as of on Jan 12, 2023. Returned data may be incomplete. - `crash_rate`, `crash_free_rate` applied to `user` or `session`. For example, `crash_free_rate(user)`
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --environment: list # The name of environments to filter by.
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --per-page: int # The number of groups to return per request.
  --interval: string # Resolution of the time series, given in the same format as `statsPeriod`.  The default and         the minimum interval is `1h`.
  --groupBy: list # The list of properties to group by.  The available groupBy conditions are `project`,         `release`, `environment` and `session.status`.
  --orderBy: string # An optional field to order by, which must be one of the fields provided in `field`. Use `-`         for descending order, for example, `-sum(session)`
  --includeTotals: int # Specify `0` to exclude totals from the response. The default is `1`
  --includeSeries: int # Specify `0` to exclude series from the response. The default is `1`
  --qp-query: string # Filters results by using [query syntax](/product/sentry-basics/search/).  Example: `query=(transaction:foo AND release:abc) OR (transaction:[bar,baz] AND release:def)`
]: nothing -> record<start: string, end: string, intervals: list<string>, groups: table<by: record, series: record, totals: record>, query: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "field" $field "multi") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "environment" $environment "multi") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "project" $project "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "groupBy" $groupBy "multi") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeTotals" $includeTotals "scalar") (serialize-qp "includeSeries" $includeSeries "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/sessions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve a short ID to the project slug and group details.
#
# GET /api/0/organizations/{organization_id_or_slug}/shortids/{issue_id}/
# operationId: Resolve a Short ID
export def "0-organizations-shortids Resolve-a-Short-ID" [
  organization_id_or_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --collapse: list # Fields to remove from the response to improve query performance.
]: nothing -> record<organizationSlug: string, projectSlug: string, groupId: string, group: record<isUnhandled: bool, count: string, userCount: int, firstSeen: string, lastSeen: string, id: string, shareId: string, shortId: string, title: string, culprit: string, permalink: string, logger: string, level: string, status: string, statusDetails: record<autoResolved: bool, ignoreCount: int, ignoreUntil: string, ignoreUserCount: int, ignoreUserWindow: int, ignoreWindow: int, actor: record, inNextRelease: bool, inRelease: string, inCommit: string, pendingEvents: int, info: any>, substatus: string, isPublic: bool, platform: string, priority: string, priorityLockedAt: string, seerFixabilityScore: float, seerAutofixLastTriggered: string, seerExplorerAutofixLastTriggered: string, project: record<id: string, name: string, slug: string, platform: string>, type: string, issueType: string, issueCategory: string, metadata: record, numComments: int, assignedTo: record<type: string, id: string, name: string, email: string>, isBookmarked: bool, isSubscribed: bool, subscriptionDetails: record<disabled: bool, reason: string>, hasSeen: bool, annotations: list<record>>, shortId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "collapse" $collapse "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/shortids/($issue_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query summarized event counts by project for your Organization. Also see https://docs.sentry.io/api/organizations/retrieve-event-counts-for-an-organization-v2/ for reference.
#
# GET /api/0/organizations/{organization_id_or_slug}/stats-summary/
# operationId: Retrieve an Organization's Events Count by Project
export def "0-organizations-stats-summary Retrieve-an-Organizations-Events-Count-by-Project" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: string@field-completer # the `sum(quantity)` field is bytes for attachments, and all others the 'event' count for those types of events.  `sum(times_seen)` sums the number of times an event has been seen. For 'normal' event types, this will be equal to `sum(quantity)` for now. For sessions, quantity will sum the total number of events seen in a session, while `times_seen` will be the unique number of sessions. and for attachments, `times_seen` will be the total number of attachments, while quantity will be the total sum of attachment bytes.  * `sum(quantity)` * `sum(times_seen)`
  --statsPeriod: string # This defines the range of the time series, relative to now. The range is given in a `<number><unit>` format. For example `1d` for a one day range. Possible units are `m` for minutes, `h` for hours, `d` for days and `w` for weeks. You must either provide a `statsPeriod`, or a `start` and `end`.
  --interval: string # This is the resolution of the time series, given in the same format as `statsPeriod`. The default resolution is `1h` and the minimum resolution is currently restricted to `1h` as well. Intervals larger than `1d` are not supported, and the interval has to cleanly divide one day.
  --start: string # This defines the start of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `end` instead of `statsPeriod`. (format: date-time)
  --end: string # This defines the inclusive end of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `start` instead of `statsPeriod`. (format: date-time)
  --project: list # The ID of the projects to filter by.
  --category: string@category-completer # If filtering by attachments, you cannot filter by any other category due to quantity values becoming nonsensical (combining bytes and event counts).  If filtering by `error`, it will automatically add `default` and `security` as we currently roll those two categories into `error` for displaying.  * `error` * `transaction` * `attachment` * `replays` * `profiles`
  --outcome: string@outcome-completer # See https://docs.sentry.io/product/stats/ for more information on outcome statuses.  * `accepted` * `filtered` * `rate_limited` * `invalid` * `abuse` * `client_discard` * `cardinality_limited`
  --reason: string # The reason field will contain why an event was filtered/dropped.
  --download: string@bool-completer # Download the API response in as a csv file
]: nothing -> record<start: string, end: string, projects: table<id: string, slug: string, stats: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "field" $field "scalar") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "project" $project "multi") (serialize-qp "category" $category "scalar") (serialize-qp "outcome" $outcome "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "download" $download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/stats-summary/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Query event counts for your Organization. Select a field, define a date range, and group or filter by columns.
#
# GET /api/0/organizations/{organization_id_or_slug}/stats_v2/
# operationId: Retrieve Event Counts for an Organization (v2)
export def "0-organizations-stats-v2 Retrieve-Event-Counts-for-an-Organization-v2" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --groupBy: list # can pass multiple groupBy parameters to group by multiple, e.g. `groupBy=project&groupBy=outcome` to group by multiple dimensions. Note that grouping by project can cause missing rows if the number of projects / interval is large. If you have a large number of projects, we recommend filtering and querying by them individually.Also note that grouping by projects does not currently support timeseries interval responses and will instead be a sum of the projectover the entire period specified.
  --field: string@field-completer # the `sum(quantity)` field is bytes for attachments, and all others the 'event' count for those types of events.  `sum(times_seen)` sums the number of times an event has been seen. For 'normal' event types, this will be equal to `sum(quantity)` for now. For sessions, quantity will sum the total number of events seen in a session, while `times_seen` will be the unique number of sessions. and for attachments, `times_seen` will be the total number of attachments, while quantity will be the total sum of attachment bytes.  * `sum(quantity)` * `sum(times_seen)`
  --statsPeriod: string # This defines the range of the time series, relative to now. The range is given in a `<number><unit>` format. For example `1d` for a one day range. Possible units are `m` for minutes, `h` for hours, `d` for days and `w` for weeks. You must either provide a `statsPeriod`, or a `start` and `end`.
  --interval: string # This is the resolution of the time series, given in the same format as `statsPeriod`. The default resolution is `1h` and the minimum resolution is currently restricted to `1h` as well. Intervals larger than `1d` are not supported, and the interval has to cleanly divide one day.
  --start: string # This defines the start of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `end` instead of `statsPeriod`. (format: date-time)
  --end: string # This defines the inclusive end of the time series range as an explicit datetime, either in UTC ISO8601 or epoch seconds. Use along with `start` instead of `statsPeriod`. (format: date-time)
  --project: list # The ID of the projects to filter by.  Use `-1` to include all accessible projects.
  --category: string@category-completer-1 # Filter by data category. Each category represents a different type of data:  - `error`: Error events (includes `default` and `security` categories) - `transaction`: Transaction events - `attachment`: File attachments (note: cannot be combined with other categories since quantity represents bytes) - `replay`: Session replay events - `profile`: Performance profiles - `profile_duration`: Profile duration data (note: cannot be combined with other categories since quantity represents milliseconds) - `profile_duration_ui`: Profile duration (UI) data (note: cannot be combined with other categories since quantity represents milliseconds) - `profile_chunk`: Profile chunk data - `profile_chunk_ui`: Profile chunk (UI) data - `monitor`: Cron monitor events  * `error` * `transaction` * `attachment` * `replay` * `profile` * `profile_duration` * `profile_duration_ui` * `profile_chunk` * `profile_chunk_ui` * `monitor`
  --outcome: string@outcome-completer # See https://docs.sentry.io/product/stats/ for more information on outcome statuses.  * `accepted` * `filtered` * `rate_limited` * `invalid` * `abuse` * `client_discard` * `cardinality_limited`
  --reason: string # The reason field will contain why an event was filtered/dropped.
]: nothing -> record<start: string, end: string, intervals: list<string>, groups: table<by: record, totals: record, series: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "groupBy" $groupBy "multi") (serialize-qp "field" $field "scalar") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "project" $project "multi") (serialize-qp "category" $category "scalar") (serialize-qp "outcome" $outcome "scalar") (serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/stats_v2/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of tag keys for the given organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/tags/
# operationId: List an Organization's Tags
export def "0-organizations-tags List-an-Organizations-Tags" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --environment: list # The name of environments to filter by.
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --dataset: string@dataset-completer-1 # The dataset to query. Defaults to `discover`.
  --use-cache: string@use-cache-completer # Set to `"1"` to enable caching for the tag key query.
  --useFlagsBackend: string@useFlagsBackend-completer # Set to `"1"` to query feature flags instead of tags.
]: nothing -> table<uniqueValues: int, totalValues: int, topValues: list<record>, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "project" $project "multi") (serialize-qp "environment" $environment "multi") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "dataset" $dataset "scalar") (serialize-qp "use_cache" $use_cache "scalar") (serialize-qp "useFlagsBackend" $useFlagsBackend "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/tags/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of teams bound to a organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/teams/
# operationId: List an Organization's Teams
export def "0-organizations-teams List-an-Organizations-Teams" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --detailed: string #  Specify `"0"` to return team details that do not include projects.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
  --qp-query: string # Filter teams by name or slug.
]: nothing -> table<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list<string>, hasAccess: bool, isPending: bool, memberCount: int, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, externalTeams: list<record>, organization: record<features: list, extraOptions: record, access: list, onboardingTasks: list, id: string, slug: string, status: record, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record, links: record, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool>, projects: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/teams/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new team bound to an organization. Requires at least one of the `name` or `slug` body params to be set.
#
# POST /api/0/organizations/{organization_id_or_slug}/teams/
# operationId: Create a New Team
@deprecated --flag name
export def "0-organizations-teams Create-a-New-Team" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --slug: string # Uniquely identifies a team and is used for the interface. If not         provided, it is automatically generated from the name. (nullable)
  --name: string # **`[DEPRECATED]`** The name for the team. If not provided, it is         automatically generated from the slug (DEPRECATED, nullable)
]: any -> record<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list<string>, hasAccess: bool, isPending: bool, memberCount: int, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, externalTeams: table<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string>, organization: record<features: list<string>, extraOptions: record, access: list<string>, onboardingTasks: list<record>, id: string, slug: string, status: record<id: string, name: string>, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, links: record<organizationUrl: string, regionUrl: string>, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool>, projects: table<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list, firstEvent: string, firstTransactionEvent: bool, access: list, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record, color: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/teams/")
  let body = {slug: $slug, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List the attribute keys available on a given trace item dataset (spans, logs, trace metrics, etc.), with optional substring and structured filtering.
#
# GET /api/0/organizations/{organization_id_or_slug}/trace-items/attributes/
# operationId: List Trace Item Attributes
@deprecated --flag itemType
export def "0-organizations-trace-items-attributes List-Trace-Item-Attributes" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --dataset: string@dataset-completer-2 # The trace item dataset to list attributes for. One of `itemType` or `dataset` is required.
  --itemType: string@itemType-completer # Deprecated alias of `dataset`. Use `dataset` instead. (DEPRECATED)
  --attributeType: list # Filter to attributes of one or more types. Defaults to all types.
  --substringMatch: string # Restrict results to attribute names containing this substring (case-sensitive).
  --qp-query: string # Sentry [search syntax](https://docs.sentry.io/concepts/search/) to filter trace items before computing attributes.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<key: string, name: string, secondaryAliases: list<string>, attributeSource: record<source_type: string, is_transformed_alias: bool>, attributeType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "dataset" $dataset "scalar") (serialize-qp "itemType" $itemType "scalar") (serialize-qp "attributeType" $attributeType "multi") (serialize-qp "substringMatch" $substringMatch "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/trace-items/attributes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve aggregate metadata for a single trace, including counts of spans, errors, performance issues, logs, and metrics, along with per-span-operation and per-transaction child-count breakdowns.
#
# GET /api/0/organizations/{organization_id_or_slug}/trace-meta/{trace_id}/
# operationId: Retrieve Trace Metadata
export def "0-organizations-trace-meta Retrieve-Trace-Metadata" [
  organization_id_or_slug: string
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --include-uptime: string@include-uptime-completer # Set to `1` to include uptime check counts in the response. Defaults to `0` (disabled).
]: nothing -> record<uptimeCount: int, errorsCount: int, logsCount: float, metricsCount: float, performanceIssuesCount: int, spansCount: float, transactionChildCountMap: list<record>, spansCountMap: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "include_uptime" $include_uptime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/trace-meta/($trace_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the spans, errors, and (optionally) uptime checks that make up a single trace.  The response is a list of top-level events; each item may have nested `children`, `errors`, and `occurrences` arrays representing related items. Top-level entries are spans by default and may also be uptime checks when `include_uptime=1` is passed.
#
# GET /api/0/organizations/{organization_id_or_slug}/trace/{trace_id}/
# operationId: Retrieve a Trace
export def "0-organizations-trace Retrieve-a-Trace" [
  organization_id_or_slug: string
  trace_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --referrer: string # Internal referrer identifier used for query tracing. Most clients can omit this.
  --errorId: string # A 32-character hexadecimal event ID to bias the trace results toward including.
  --additional-attributes: list # Additional span attributes to include on each event. Repeat to request multiple.
  --include-uptime: string@include-uptime-completer # Set to `1` to include uptime check results in the trace. Defaults to `0`.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "referrer" $referrer "scalar") (serialize-qp "errorId" $errorId "scalar") (serialize-qp "additional_attributes" $additional_attributes "multi") (serialize-qp "include_uptime" $include_uptime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/trace/($trace_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of teams the user has access to in the specified organization. Note that this endpoint is restricted to [user auth tokens](https://docs.sentry.io/account/auth-tokens/#user-auth-tokens).
#
# GET /api/0/organizations/{organization_id_or_slug}/user-teams/
# operationId: List a User's Teams for an Organization
export def "0-organizations-user-teams List-a-Users-Teams-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list<string>, hasAccess: bool, isPending: bool, memberCount: int, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, externalTeams: list<record>, organization: record<features: list, extraOptions: record, access: list, onboardingTasks: list, id: string, slug: string, status: record, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record, links: record, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool>, projects: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/user-teams/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of alerts for a given organization
#
# GET /api/0/organizations/{organization_id_or_slug}/workflows/
# operationId: Fetch Alerts
export def "0-organizations-workflows Fetch-Alerts" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sortBy: string # The field to sort results by. If not specified, the results are sorted by id.  Available fields are: - `name` - `id` - `dateCreated` - `dateUpdated` - `connectedDetectors` - `actions` - `priorityDetector`  Prefix with `-` to sort in descending order.     
  --qp-query: string # An optional search query for filtering alerts.
  --id: list # The ID of the alert you'd like to query.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
]: nothing -> table<id: string, name: string, organizationId: string, createdBy: string, dateCreated: string, dateUpdated: string, triggers: record<id: string, organizationId: string, logicType: string, conditions: any, actions: any>, actionFilters: list<record>, environment: string, config: record, detectorIds: list<string>, enabled: bool, lastTriggered: string, owner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "id" $id "multi") (serialize-qp "project" $project "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/workflows/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an alert for an organization
#
# POST /api/0/organizations/{organization_id_or_slug}/workflows/
# operationId: Create an Alert for an Organization
export def "0-organizations-workflows Create-an-Alert-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the alert
  --id: string # The ID of the existing alert
  --enabled: string@bool-completer # Whether the alert is enabled or disabled (default: true)
  --detector-ids: list # The IDs of the monitors to connect this alert to. Use 'Fetch an Organization's Monitors' to find the IDs.
  --config: record #          Typically the frequency at which the alert will fire, in minutes.          - `0`: 0 minutes         - `5`: 5 minutes         - `10`: 10 minutes         - `30`: 30 minutes         - `60`: 1 hour         - `180`: 3 hours         - `720`: 12 hours         - `1440`: 24 hours          ```json             {                 "frequency":3600             }         ```         
  --environment: string # The name of the environment for the alert to evaluate in (nullable)
  --triggers: any # The conditions on which the alert will trigger. See available options below.         ```json             "triggers": {                 "organizationId": "1",                 "logicType": "any-short",                 "conditions": [                     {                         "type": "first_seen_event",                         "comparison": true,                         "conditionResult": true                     },                     {                         "type": "issue_resolved_trigger",                         "comparison": true,                         "conditionResult": true                     },                     {                         "type": "reappeared_event",                         "comparison": true,                         "conditionResult": true                     },                     {                         "type": "regression_event",                         "comparison": true,                         "conditionResult": true                     }                 ],                 "actions": []             }         ```         
  --action-filters: list # The filters to run before the action will fire and the action(s) to fire.          `logicType` can be one of `any-short`, `all`, or `none`.          Below is a basic example. See below for all other options.          ```json             "actionFilters": [                 {                     "logicType": "any",                     "conditions": [                         {                             "type": "level",                             "comparison": {                                 "level": 50,                                 "match": "eq"                             },                             "conditionResult": true                         }                     ],                     "actions": [                         {                             "id": "123",                             "type": "email",                             "integrationId": null,                             "data": {},                             "config": {                                 "targetType": "user",                                 "targetDisplay": null,                                 "targetIdentifier": "56789"                             },                             "status": "active"                         }                     ]                 }             ]         ```          ## Conditions          **Issue Age**         - `time`: One of `minute`, `hour`, `day`, or `week`.         - `value`: A positive integer.         - `comparisonType`: One of `older` or `newer`.         ```json             {                 "type": "age_comparison",                 "comparison": {                     "time": "minute",                     "value": 10,                     "comparisonType": "older"                 },                 "conditionResult": true             }          ```          **Issue Assignment**         - `targetType`: Who the issue is assigned to             - `Unassigned`: Unassigned             - `Member`: Assigned to a user             - `Team`: Assigned to a team         - `targetIdentifier`: The ID of the user or team from the `targetType`. Enter "" if `targetType` is `Unassigned`.         ```json             {                 "type": "assigned_to",                 "comparison": {                     "targetType": "Member",                     "targetIdentifier": 123456                 },                 "conditionResult": true             }         ```          **Issue Category**         - `value`: The issue category to filter to.             - `1`: Error issues             - `6`: Feedback issues             - `10`: Outage issues             - `11`: Metric issues             - `12`: DB Query issues             - `13`: HTTP Client issues             - `14`: Front end issues             - `15`: Mobile issues         ```json             {                 "type": "issue_category",                 "comparison": {                     "value": 1                 },                 "conditionResult": true             }         ```          **Issue Frequency**         - `value`: A positive integer representing how many times the issue has to happen before the alert will fire.         ```json             {                 "type": "issue_occurrences",                 "comparison": {                     "value": 10                 },                 "conditionResult": true             }         ```          **De-escalation**         ```json             {                 "type": "issue_priority_deescalating",                 "comparison": true,                 "conditionResult": true             }         ```          **Issue Priority**         - `comparison`: The priority the issue must be for the alert to fire.             - `75`: High priority             - `50`: Medium priority             - `25`: Low priority         ```json             {                 "type": "issue_priority_greater_or_equal",                 "comparison": 75,                 "conditionResult": true             }         ```          **Number of Users Affected**         - `value`: A positive integer representing the number of users that must be affected before the alert will fire.         - `filters`: A list of additional sub-filters to evaluate before the alert will fire.         - `interval`: The time period in which to evaluate the value. e.g. Number of users affected by an issue is more than `value` in `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         ```json             {                 "type": "event_unique_user_frequency_count",                 "comparison": {                     "value": 100,                     "filters": [{"key": "foo", "match": "eq", "value": "bar"}],                     "interval": "1h"                 },                 "conditionResult": true             }         ```          **Number of Events**         - `value`: A positive integer representing the number of events in an issue that must come in before the alert will fire         - `interval`: The time period in which to evaluate the value. e.g. Number of events in an issue is more than `value` in `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         ```json             {                 "type": "event_frequency_count",                 "comparison": {                     "value": 100,                     "interval": "1h"                 },                 "conditionResult": true             }         ```          **Percent of Events**         - `value`: A positive integer representing the number of events in an issue that must come in before the alert will fire         - `interval`: The time period in which to evaluate the value. e.g. Number of events in an issue is `comparisonInterval` percent higher `value` compared to `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         - `comparisonInterval`: The time period to compare against. See `interval` for options.         ```json             {                 "type": "event_frequency_percent",                 "comparison": {                     "value": 100,                     "interval": "1h",                     "comparisonInterval": "1w"                 },                 "conditionResult": true             }          ```          **Percentage of Sessions Affected Count**         - `value`: A positive integer representing the number of events in an issue that must come in before the alert will fire         - `interval`: The time period in which to evaluate the value. e.g. Percentage of sessions affected by an issue is more than `value` in `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         ```json             {                 "type": "percent_sessions_count",                 "comparison": {                     "value": 10,                     "interval": "1h"                 },                 "conditionResult": true             }         ```          **Percentage of Sessions Affected Percent**         - `value`: A positive integer representing the number of events in an issue that must come in before the alert will fire         - `interval`: The time period in which to evaluate the value. e.g. Percentage of sessions affected by an issue is `comparisonInterval` percent higher `value` compared to `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         - `comparisonInterval`: The time period to compare against. See `interval` for options.         ```json             {                 "type": "percent_sessions_percent",                 "comparison": {                     "value": 10,                     "interval": "1h"                 },                 "conditionResult": true             }         ```          **Event Attribute**         The event's `attribute` value `match` `value`          - `attribute`: The event attribute to match on. Valid values are: `message`, `platform`, `environment`, `type`, `error.handled`, `error.unhandled`, `error.main_thread`, `exception.type`, `exception.value`, `user.id`, `user.email`, `user.username`, `user.ip_address`, `http.method`, `http.url`, `http.status_code`, `sdk.name`, `stacktrace.code`, `stacktrace.module`, `stacktrace.filename`, `stacktrace.abs_path`, `stacktrace.package`, `unreal.crash_type`, `app.in_foreground`.         - `match`: The comparison operator             - `co`: Contains             - `nc`: Does not contain             - `eq`: Equals             - `ne`: Does not equal             - `sw`: Starts with             - `ew`: Ends with             - `is`: Is set             - `ns`: Is not set         - `value`: A string. Not required when match is `is` or `ns`.          ```json             {                 "type": "event_attribute",                 "comparison": {                     "match": "co",                     "value": "bar",                     "attribute": "message"                 },                 "conditionResult": true             }         ```          **Tagged Event**         The event's tags `key` match `value`         - `key`: The tag value         - `match`: The comparison operator             - `co`: Contains             - `nc`: Does not contain             - `eq`: Equals             - `ne`: Does not equal             - `sw`: Starts with             - `ew`: Ends with             - `is`: Is set             - `ns`: Is not set         - `value`: A string. Not required when match is `is` or `ns`.          ```json             {                 "type": "tagged_event",                 "comparison": {                     "key": "level",                     "match": "eq",                     "value": "error"                 },                 "conditionResult": true             }         ```          **Latest Release**         The event is from the latest release          ```json             {                 "type": "latest_release",                 "comparison": true,                 "conditionResult": true             }         ```          **Release Age**         ```json             {                 "type": "latest_adopted_release",                 "comparison": {                     "environment": "12345",                     "ageComparison": "older",                     "releaseAgeType": "oldest"                 },                 "conditionResult": true             }         ```          **Event Level**         The event's level is `match` `level`         - `match`: The comparison operator             - `eq`: Equal             - `gte`: Greater than or equal             - `lte`: Less than or equal         - `level`: The event level             - `50`: Fatal             - `40`: Error             - `30`: Warning             - `20`: Info             - `10`: Debug             - `0`: Sample          ```json             {                 "type": "level",                 "comparison": {                     "level": 50,                     "match": "eq"                 },                 "conditionResult": true             }         ```          ## Actions         A list of actions that take place when all required conditions and filters for the alert are met. See below for a list of possible actions.           **Notify on Preferred Channel**         - `data`: A dictionary with the fallthrough type option when choosing to notify Suggested Assignees. Leave empty if notifying a user or team.             - `fallthroughType`                 - `ActiveMembers`                 - `AllMembers`                 - `NoOne`         - `config`: A dictionary with the configuration options for notification.             - `targetType`: The type of recipient to notify                 - `user`: User                 - `team`: Team                 - `issue_owners`: Suggested Assignees             - `targetDisplay`: null             - `targetIdentifier`: The id of the user or team to notify. Leave null for Suggested Assignees.          ```json             {                 "type":"email",                 "integrationId":null,                 "data":{},                 "config":{                     "targetType":"user",                     "targetDisplay":null,                     "targetIdentifier":"232692"                 },                 "status":"active"             },             {                 "type":"email",                 "integrationId":null,                 "data":{                     "fallthroughType":"ActiveMembers"                 },                 "config":{                     "targetType":"issue_owners",                     "targetDisplay":null,                     "targetIdentifier":""}                 ,                 "status":"active"             }         ```         **Notify on Slack**         - `targetDisplay`: The name of the channel to notify in.         `integrationId`: The stringified ID of the integration.          ```json             {                 "type":"slack",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"",                     "targetDisplay":"notify-errors"                 },                 "integrationId":"1",                 "data":{},                 "status":"active"             }         ```          **Notify on PagerDuty**         - `targetDisplay`: The name of the service to create the ticket in.         - `integrationId`: The stringified ID of the integration.         - `data["priority"]`: The severity level for the notification.          ```json             {                 "type":"pagerduty",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"123456",                     "targetDisplay":"Error Service"                     },                 "integrationId":"2345",                 "data":{                     "priority":"default"                 },                 "status":"active"             }         ```          **Notify on Discord**         - `targetDisplay`: The name of the service to create the ticket in.         - `integrationId`: The stringified ID of the integration.         - `data["tags"]`: Comma separated list of tags to add to the notification.          ```json             {                 "type":"discord",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"12345",                     "targetDisplay":"",                     },                 "integrationId":"1234",                 "data":{                     "tags":"transaction,environment"                 },                 "status":"active"             }         ```          **Notify on MSTeams**         - `targetIdentifier` - The integration ID associated with the Microsoft Teams team.         - `targetDisplay` - The name of the channel to send the notification to.         - `integrationId`: The stringified ID of the integration.         ```json             {                 "type":"msteams",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"19:a4b3kghaghgkjah357y6847@thread.skype",                     "targetDisplay":"notify-errors"                 },                 "integrationId":"1",                 "data":{},                 "status":"active"             }         ```          **Notify on OpsGenie**         - `targetDisplay`: The name of the Opsgenie team.         - `targetIdentifier`: The ID of the Opsgenie team to send the notification to.         - `integrationId`: The stringified ID of the integration.         - `data["priority"]`: The priority level for the notification.          ```json             {                 "type":"opsgenie",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"123456-Error-Service",                     "targetDisplay":"Error Service"                     },                 "integrationId":"2345",                 "data":{                     "priority":"P3"                 },                 "status":"active"             }         ```          **Notify on Azure DevOps**         - `integrationId`: The stringified ID of the integration.         - `data` - A list of any fields you want to include in the ticket as objects.          ```json             {                 "type":"vsts",                 "config":{                     "targetType":"specific",                     "targetIdentifier":",                     "targetDisplay":""                     },                 "integrationId":"2345",                 "data":{...},                 "status":"active"             }         ```          **Create a Jira ticket**         - `integrationId`: The stringified ID of the integration.         - `data` - A list of any fields you want to include in the ticket as objects.          ```json             {                 "type":"jira",                 "config":{                     "targetType":"specific",                     "targetIdentifier":",                     "targetDisplay":""                     },                 "integrationId":"2345",                 "data":{...},                 "status":"active"             }         ```          **Create a Jira Server ticket**         - `integrationId`: The stringified ID of the integration.         - `data` - A list of any fields you want to include in the ticket as objects.          ```json             {                 "type":"jira_server",                 "config":{                     "targetType":"specific",                     "targetIdentifier":",                     "targetDisplay":""                     },                 "integrationId":"2345",                 "data":{...},                 "status":"active"             }         ```          **Create a GitHub issue**         - `integrationId`: The stringified ID of the integration.         - `data` - A list of any fields you want to include in the ticket as objects.          ```json             {                 "type":"github",                 "config":{                     "targetType":"specific",                     "targetIdentifier":",                     "targetDisplay":""                     },                 "integrationId":"2345",                 "data":{                   "additional_fields": {                       "assignee": "",                       "integration": "2345",                       "labels": [],                       "repo": "example-repo",                   },                   "dynamic_form_fields": [                       {                         "choices": [["YourOrg/example-repo", "example-repo"]],                         "default": "YourOrg/example-repo",                         "label": "GitHub Repository",                         "name": "repo",                         "required": true                         "type": "select",                         "updatesForm": true,                         "url": "/extensions/github/search/example-repo/1234567/",                       },                   ],                 },                 "status":"active"             }         ```         
  --owner: string #              The ID user or team who owns the monitor or alert prefaced by the string 'user' or 'team'.              **User**             ```json                 "user:123456"             ```              **Team**             ```json                 "team:456789"             ```          (nullable)
]: any -> record<id: string, name: string, organizationId: string, createdBy: string, dateCreated: string, dateUpdated: string, triggers: record<id: string, organizationId: string, logicType: string, conditions: any, actions: any>, actionFilters: table<id: string, organizationId: string, logicType: string, conditions: any, actions: any>, environment: string, config: record, detectorIds: list<string>, enabled: bool, lastTriggered: string, owner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/workflows/")
  let body = {name: $name, id: $id, enabled: $enabled, detector_ids: $detector_ids, config: $config, environment: $environment, triggers: $triggers, action_filters: $action_filters, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk enable or disable alerts for a given Organization
#
# PUT /api/0/organizations/{organization_id_or_slug}/workflows/
# operationId: Mutate an Organization's Alerts
export def "0-organizations-workflows Mutate-an-Organizations-Alerts" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # An optional search query for filtering alerts.
  --id: list # The ID of the alert you'd like to query.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
  --enabled: string@bool-completer # Whether to enable or disable the alerts
]: any -> table<id: string, name: string, organizationId: string, createdBy: string, dateCreated: string, dateUpdated: string, triggers: record<id: string, organizationId: string, logicType: string, conditions: any, actions: any>, actionFilters: list<record>, environment: string, config: record, detectorIds: list<string>, enabled: bool, lastTriggered: string, owner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "id" $id "multi") (serialize-qp "project" $project "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/workflows/" $qp)
  let body = {enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete alerts for a given organization
#
# DELETE /api/0/organizations/{organization_id_or_slug}/workflows/
# operationId: Bulk Delete Alerts
export def "0-organizations-workflows Bulk-Delete-Alerts" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # An optional search query for filtering alerts.
  --id: list # The ID of the alert you'd like to query.
  --project: list # The IDs of projects to filter by. `-1` means all available projects. For example, the following are valid parameters: - `/?project=1234&project=56789` - `/?project=-1`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "id" $id "multi") (serialize-qp "project" $project "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/workflows/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns an alert.
#
# GET /api/0/organizations/{organization_id_or_slug}/workflows/{workflow_id}/
# operationId: Fetch an Alert
export def "0-organizations-workflows Fetch-an-Alert" [
  organization_id_or_slug: string
  workflow_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, organizationId: string, createdBy: string, dateCreated: string, dateUpdated: string, triggers: record<id: string, organizationId: string, logicType: string, conditions: any, actions: any>, actionFilters: table<id: string, organizationId: string, logicType: string, conditions: any, actions: any>, environment: string, config: record, detectorIds: list<string>, enabled: bool, lastTriggered: string, owner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/workflows/($workflow_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an alert.
#
# PUT /api/0/organizations/{organization_id_or_slug}/workflows/{workflow_id}/
# operationId: Update an Alert by ID
export def "0-organizations-workflows Update-an-Alert-by-ID" [
  organization_id_or_slug: string
  workflow_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the alert
  --id: string # The ID of the existing alert
  --enabled: string@bool-completer # Whether the alert is enabled or disabled (default: true)
  --detector-ids: list # The IDs of the monitors to connect this alert to. Use 'Fetch an Organization's Monitors' to find the IDs.
  --config: record #          Typically the frequency at which the alert will fire, in minutes.          - `0`: 0 minutes         - `5`: 5 minutes         - `10`: 10 minutes         - `30`: 30 minutes         - `60`: 1 hour         - `180`: 3 hours         - `720`: 12 hours         - `1440`: 24 hours          ```json             {                 "frequency":3600             }         ```         
  --environment: string # The name of the environment for the alert to evaluate in (nullable)
  --triggers: any # The conditions on which the alert will trigger. See available options below.         ```json             "triggers": {                 "organizationId": "1",                 "logicType": "any-short",                 "conditions": [                     {                         "type": "first_seen_event",                         "comparison": true,                         "conditionResult": true                     },                     {                         "type": "issue_resolved_trigger",                         "comparison": true,                         "conditionResult": true                     },                     {                         "type": "reappeared_event",                         "comparison": true,                         "conditionResult": true                     },                     {                         "type": "regression_event",                         "comparison": true,                         "conditionResult": true                     }                 ],                 "actions": []             }         ```         
  --action-filters: list # The filters to run before the action will fire and the action(s) to fire.          `logicType` can be one of `any-short`, `all`, or `none`.          Below is a basic example. See below for all other options.          ```json             "actionFilters": [                 {                     "logicType": "any",                     "conditions": [                         {                             "type": "level",                             "comparison": {                                 "level": 50,                                 "match": "eq"                             },                             "conditionResult": true                         }                     ],                     "actions": [                         {                             "id": "123",                             "type": "email",                             "integrationId": null,                             "data": {},                             "config": {                                 "targetType": "user",                                 "targetDisplay": null,                                 "targetIdentifier": "56789"                             },                             "status": "active"                         }                     ]                 }             ]         ```          ## Conditions          **Issue Age**         - `time`: One of `minute`, `hour`, `day`, or `week`.         - `value`: A positive integer.         - `comparisonType`: One of `older` or `newer`.         ```json             {                 "type": "age_comparison",                 "comparison": {                     "time": "minute",                     "value": 10,                     "comparisonType": "older"                 },                 "conditionResult": true             }          ```          **Issue Assignment**         - `targetType`: Who the issue is assigned to             - `Unassigned`: Unassigned             - `Member`: Assigned to a user             - `Team`: Assigned to a team         - `targetIdentifier`: The ID of the user or team from the `targetType`. Enter "" if `targetType` is `Unassigned`.         ```json             {                 "type": "assigned_to",                 "comparison": {                     "targetType": "Member",                     "targetIdentifier": 123456                 },                 "conditionResult": true             }         ```          **Issue Category**         - `value`: The issue category to filter to.             - `1`: Error issues             - `6`: Feedback issues             - `10`: Outage issues             - `11`: Metric issues             - `12`: DB Query issues             - `13`: HTTP Client issues             - `14`: Front end issues             - `15`: Mobile issues         ```json             {                 "type": "issue_category",                 "comparison": {                     "value": 1                 },                 "conditionResult": true             }         ```          **Issue Frequency**         - `value`: A positive integer representing how many times the issue has to happen before the alert will fire.         ```json             {                 "type": "issue_occurrences",                 "comparison": {                     "value": 10                 },                 "conditionResult": true             }         ```          **De-escalation**         ```json             {                 "type": "issue_priority_deescalating",                 "comparison": true,                 "conditionResult": true             }         ```          **Issue Priority**         - `comparison`: The priority the issue must be for the alert to fire.             - `75`: High priority             - `50`: Medium priority             - `25`: Low priority         ```json             {                 "type": "issue_priority_greater_or_equal",                 "comparison": 75,                 "conditionResult": true             }         ```          **Number of Users Affected**         - `value`: A positive integer representing the number of users that must be affected before the alert will fire.         - `filters`: A list of additional sub-filters to evaluate before the alert will fire.         - `interval`: The time period in which to evaluate the value. e.g. Number of users affected by an issue is more than `value` in `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         ```json             {                 "type": "event_unique_user_frequency_count",                 "comparison": {                     "value": 100,                     "filters": [{"key": "foo", "match": "eq", "value": "bar"}],                     "interval": "1h"                 },                 "conditionResult": true             }         ```          **Number of Events**         - `value`: A positive integer representing the number of events in an issue that must come in before the alert will fire         - `interval`: The time period in which to evaluate the value. e.g. Number of events in an issue is more than `value` in `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         ```json             {                 "type": "event_frequency_count",                 "comparison": {                     "value": 100,                     "interval": "1h"                 },                 "conditionResult": true             }         ```          **Percent of Events**         - `value`: A positive integer representing the number of events in an issue that must come in before the alert will fire         - `interval`: The time period in which to evaluate the value. e.g. Number of events in an issue is `comparisonInterval` percent higher `value` compared to `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         - `comparisonInterval`: The time period to compare against. See `interval` for options.         ```json             {                 "type": "event_frequency_percent",                 "comparison": {                     "value": 100,                     "interval": "1h",                     "comparisonInterval": "1w"                 },                 "conditionResult": true             }          ```          **Percentage of Sessions Affected Count**         - `value`: A positive integer representing the number of events in an issue that must come in before the alert will fire         - `interval`: The time period in which to evaluate the value. e.g. Percentage of sessions affected by an issue is more than `value` in `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         ```json             {                 "type": "percent_sessions_count",                 "comparison": {                     "value": 10,                     "interval": "1h"                 },                 "conditionResult": true             }         ```          **Percentage of Sessions Affected Percent**         - `value`: A positive integer representing the number of events in an issue that must come in before the alert will fire         - `interval`: The time period in which to evaluate the value. e.g. Percentage of sessions affected by an issue is `comparisonInterval` percent higher `value` compared to `interval`.             - `1min`: 1 minute             - `5min`: 5 minutes             - `15min`: 15 minutes             - `1hr`: 1 hour             - `1d`: 1 day             - `1w`: 1 week             - `30d`: 30 days         - `comparisonInterval`: The time period to compare against. See `interval` for options.         ```json             {                 "type": "percent_sessions_percent",                 "comparison": {                     "value": 10,                     "interval": "1h"                 },                 "conditionResult": true             }         ```          **Event Attribute**         The event's `attribute` value `match` `value`          - `attribute`: The event attribute to match on. Valid values are: `message`, `platform`, `environment`, `type`, `error.handled`, `error.unhandled`, `error.main_thread`, `exception.type`, `exception.value`, `user.id`, `user.email`, `user.username`, `user.ip_address`, `http.method`, `http.url`, `http.status_code`, `sdk.name`, `stacktrace.code`, `stacktrace.module`, `stacktrace.filename`, `stacktrace.abs_path`, `stacktrace.package`, `unreal.crash_type`, `app.in_foreground`.         - `match`: The comparison operator             - `co`: Contains             - `nc`: Does not contain             - `eq`: Equals             - `ne`: Does not equal             - `sw`: Starts with             - `ew`: Ends with             - `is`: Is set             - `ns`: Is not set         - `value`: A string. Not required when match is `is` or `ns`.          ```json             {                 "type": "event_attribute",                 "comparison": {                     "match": "co",                     "value": "bar",                     "attribute": "message"                 },                 "conditionResult": true             }         ```          **Tagged Event**         The event's tags `key` match `value`         - `key`: The tag value         - `match`: The comparison operator             - `co`: Contains             - `nc`: Does not contain             - `eq`: Equals             - `ne`: Does not equal             - `sw`: Starts with             - `ew`: Ends with             - `is`: Is set             - `ns`: Is not set         - `value`: A string. Not required when match is `is` or `ns`.          ```json             {                 "type": "tagged_event",                 "comparison": {                     "key": "level",                     "match": "eq",                     "value": "error"                 },                 "conditionResult": true             }         ```          **Latest Release**         The event is from the latest release          ```json             {                 "type": "latest_release",                 "comparison": true,                 "conditionResult": true             }         ```          **Release Age**         ```json             {                 "type": "latest_adopted_release",                 "comparison": {                     "environment": "12345",                     "ageComparison": "older",                     "releaseAgeType": "oldest"                 },                 "conditionResult": true             }         ```          **Event Level**         The event's level is `match` `level`         - `match`: The comparison operator             - `eq`: Equal             - `gte`: Greater than or equal             - `lte`: Less than or equal         - `level`: The event level             - `50`: Fatal             - `40`: Error             - `30`: Warning             - `20`: Info             - `10`: Debug             - `0`: Sample          ```json             {                 "type": "level",                 "comparison": {                     "level": 50,                     "match": "eq"                 },                 "conditionResult": true             }         ```          ## Actions         A list of actions that take place when all required conditions and filters for the alert are met. See below for a list of possible actions.           **Notify on Preferred Channel**         - `data`: A dictionary with the fallthrough type option when choosing to notify Suggested Assignees. Leave empty if notifying a user or team.             - `fallthroughType`                 - `ActiveMembers`                 - `AllMembers`                 - `NoOne`         - `config`: A dictionary with the configuration options for notification.             - `targetType`: The type of recipient to notify                 - `user`: User                 - `team`: Team                 - `issue_owners`: Suggested Assignees             - `targetDisplay`: null             - `targetIdentifier`: The id of the user or team to notify. Leave null for Suggested Assignees.          ```json             {                 "type":"email",                 "integrationId":null,                 "data":{},                 "config":{                     "targetType":"user",                     "targetDisplay":null,                     "targetIdentifier":"232692"                 },                 "status":"active"             },             {                 "type":"email",                 "integrationId":null,                 "data":{                     "fallthroughType":"ActiveMembers"                 },                 "config":{                     "targetType":"issue_owners",                     "targetDisplay":null,                     "targetIdentifier":""}                 ,                 "status":"active"             }         ```         **Notify on Slack**         - `targetDisplay`: The name of the channel to notify in.         `integrationId`: The stringified ID of the integration.          ```json             {                 "type":"slack",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"",                     "targetDisplay":"notify-errors"                 },                 "integrationId":"1",                 "data":{},                 "status":"active"             }         ```          **Notify on PagerDuty**         - `targetDisplay`: The name of the service to create the ticket in.         - `integrationId`: The stringified ID of the integration.         - `data["priority"]`: The severity level for the notification.          ```json             {                 "type":"pagerduty",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"123456",                     "targetDisplay":"Error Service"                     },                 "integrationId":"2345",                 "data":{                     "priority":"default"                 },                 "status":"active"             }         ```          **Notify on Discord**         - `targetDisplay`: The name of the service to create the ticket in.         - `integrationId`: The stringified ID of the integration.         - `data["tags"]`: Comma separated list of tags to add to the notification.          ```json             {                 "type":"discord",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"12345",                     "targetDisplay":"",                     },                 "integrationId":"1234",                 "data":{                     "tags":"transaction,environment"                 },                 "status":"active"             }         ```          **Notify on MSTeams**         - `targetIdentifier` - The integration ID associated with the Microsoft Teams team.         - `targetDisplay` - The name of the channel to send the notification to.         - `integrationId`: The stringified ID of the integration.         ```json             {                 "type":"msteams",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"19:a4b3kghaghgkjah357y6847@thread.skype",                     "targetDisplay":"notify-errors"                 },                 "integrationId":"1",                 "data":{},                 "status":"active"             }         ```          **Notify on OpsGenie**         - `targetDisplay`: The name of the Opsgenie team.         - `targetIdentifier`: The ID of the Opsgenie team to send the notification to.         - `integrationId`: The stringified ID of the integration.         - `data["priority"]`: The priority level for the notification.          ```json             {                 "type":"opsgenie",                 "config":{                     "targetType":"specific",                     "targetIdentifier":"123456-Error-Service",                     "targetDisplay":"Error Service"                     },                 "integrationId":"2345",                 "data":{                     "priority":"P3"                 },                 "status":"active"             }         ```          **Notify on Azure DevOps**         - `integrationId`: The stringified ID of the integration.         - `data` - A list of any fields you want to include in the ticket as objects.          ```json             {                 "type":"vsts",                 "config":{                     "targetType":"specific",                     "targetIdentifier":",                     "targetDisplay":""                     },                 "integrationId":"2345",                 "data":{...},                 "status":"active"             }         ```          **Create a Jira ticket**         - `integrationId`: The stringified ID of the integration.         - `data` - A list of any fields you want to include in the ticket as objects.          ```json             {                 "type":"jira",                 "config":{                     "targetType":"specific",                     "targetIdentifier":",                     "targetDisplay":""                     },                 "integrationId":"2345",                 "data":{...},                 "status":"active"             }         ```          **Create a Jira Server ticket**         - `integrationId`: The stringified ID of the integration.         - `data` - A list of any fields you want to include in the ticket as objects.          ```json             {                 "type":"jira_server",                 "config":{                     "targetType":"specific",                     "targetIdentifier":",                     "targetDisplay":""                     },                 "integrationId":"2345",                 "data":{...},                 "status":"active"             }         ```          **Create a GitHub issue**         - `integrationId`: The stringified ID of the integration.         - `data` - A list of any fields you want to include in the ticket as objects.          ```json             {                 "type":"github",                 "config":{                     "targetType":"specific",                     "targetIdentifier":",                     "targetDisplay":""                     },                 "integrationId":"2345",                 "data":{                   "additional_fields": {                       "assignee": "",                       "integration": "2345",                       "labels": [],                       "repo": "example-repo",                   },                   "dynamic_form_fields": [                       {                         "choices": [["YourOrg/example-repo", "example-repo"]],                         "default": "YourOrg/example-repo",                         "label": "GitHub Repository",                         "name": "repo",                         "required": true                         "type": "select",                         "updatesForm": true,                         "url": "/extensions/github/search/example-repo/1234567/",                       },                   ],                 },                 "status":"active"             }         ```         
  --owner: string #              The ID user or team who owns the monitor or alert prefaced by the string 'user' or 'team'.              **User**             ```json                 "user:123456"             ```              **Team**             ```json                 "team:456789"             ```          (nullable)
]: any -> record<id: string, name: string, organizationId: string, createdBy: string, dateCreated: string, dateUpdated: string, triggers: record<id: string, organizationId: string, logicType: string, conditions: any, actions: any>, actionFilters: table<id: string, organizationId: string, logicType: string, conditions: any, actions: any>, environment: string, config: record, detectorIds: list<string>, enabled: bool, lastTriggered: string, owner: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/workflows/($workflow_id)/")
  let body = {name: $name, id: $id, enabled: $enabled, detector_ids: $detector_ids, config: $config, environment: $environment, triggers: $triggers, action_filters: $action_filters, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an alert.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/workflows/{workflow_id}/
# operationId: Delete an Alert
export def "0-organizations-workflows Delete-an-Alert" [
  organization_id_or_slug: string
  workflow_id: int
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/workflows/($workflow_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return details on an individual project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/
# operationId: Retrieve a Project
export def "0-projects Retrieve-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string, team: record<id: string, name: string, slug: string>, teams: table<id: string, name: string, slug: string>, latestRelease: record<version: string>, options: record, digestsMinDelay: int, digestsMaxDelay: int, subjectPrefix: string, allowedDomains: list<string>, resolveAge: int, dataScrubber: bool, dataScrubberDefaults: bool, safeFields: list<string>, storeCrashReports: int, sensitiveFields: list<string>, subjectTemplate: string, securityToken: string, securityTokenHeader: string, verifySSL: bool, scrubIPAddresses: bool, scrapeJavaScript: bool, highlightTags: list<string>, highlightContext: record, highlightPreset: record<tags: list<string>, context: record>, groupingConfig: string, derivedGroupingEnhancements: string, groupingEnhancements: string, secondaryGroupingExpiry: int, secondaryGroupingConfig: string, fingerprintingRules: string, organization: record<features: list<string>, extraOptions: record, access: list<string>, onboardingTasks: list<record>, id: string, slug: string, status: record<id: string, name: string>, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, links: record<organizationUrl: string, regionUrl: string>, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool>, plugins: table<id: string, name: string, slug: string, shortName: string, type: string, canDisable: bool, isTestable: bool, hasConfiguration: bool, metadata: record, contexts: list, status: string, assets: list, doc: string, firstPartyAlternative: any, deprecationDate: any, altIsSentryApp: any, enabled: bool, version: string, author: record, isDeprecated: bool, isHidden: bool, description: string, features: list, featureDescriptions: list, resourceLinks: list>, platforms: list<string>, processingIssues: int, defaultEnvironment: string, relayPiiConfig: string, builtinSymbolSources: list<string>, dynamicSamplingBiases: list<record>, symbolSources: string, isDynamicallySampled: bool, tempestFetchScreenshots: bool, autofixAutomationTuning: string, seerScannerAutomation: bool, seerNightshiftTweaks: any, scmSourceContextEnabled: bool, debugFilesRole: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update various attributes and configurable settings for the given project.  Note that solely having the **`project:read`** scope restricts updatable settings to `isBookmarked`, `autofixAutomationTuning`, `seerScannerAutomation`, `preprodSizeStatusChecksEnabled`, `preprodSizeStatusChecksRules`, `preprodSizeEnabledQuery`, `preprodDistributionEnabledQuery`, `preprodSizeEnabledByCustomer`, `preprodDistributionEnabledByCustomer`, and `preprodDistributionPrCommentsEnabledByCustomer`.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/
# operationId: Update a Project
export def "0-projects Update-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isBookmarked: string@bool-completer # Enables starring the project within the projects tab. Can be updated with **`project:read`** permission.
  --name: string # The name for the project
  --slug: string # Uniquely identifies a project and is used for the interface.
  --platform: string # The platform for the project (nullable)
  --subjectPrefix: string # Custom prefix for emails from this project.
  --subjectTemplate: string # The email subject to use (excluding the prefix) for individual alerts. Here are the list of variables you can use: - `$title` - `$shortID` - `$projectID` - `$orgID` - `${tag:key}` - such as `${tag:environment}` or `${tag:release}`.
  --resolveAge: int # Automatically resolve an issue if it hasn't been seen for this many hours. Set to `0` to disable auto-resolve. (nullable)
  --highlightContext: record # A JSON mapping of context types to lists of strings for their keys. E.g. `{'user': ['id', 'email']}`
  --highlightTags: list # A list of strings with tag keys to highlight on this project's issues. E.g. `['release', 'environment']`
  --scmSourceContextEnabled: string@bool-completer # Enable on-demand source context fetching from SCM integrations for stack traces.
]: any -> record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string, team: record<id: string, name: string, slug: string>, teams: table<id: string, name: string, slug: string>, latestRelease: record<version: string>, options: record, digestsMinDelay: int, digestsMaxDelay: int, subjectPrefix: string, allowedDomains: list<string>, resolveAge: int, dataScrubber: bool, dataScrubberDefaults: bool, safeFields: list<string>, storeCrashReports: int, sensitiveFields: list<string>, subjectTemplate: string, securityToken: string, securityTokenHeader: string, verifySSL: bool, scrubIPAddresses: bool, scrapeJavaScript: bool, highlightTags: list<string>, highlightContext: record, highlightPreset: record<tags: list<string>, context: record>, groupingConfig: string, derivedGroupingEnhancements: string, groupingEnhancements: string, secondaryGroupingExpiry: int, secondaryGroupingConfig: string, fingerprintingRules: string, organization: record<features: list<string>, extraOptions: record, access: list<string>, onboardingTasks: list<record>, id: string, slug: string, status: record<id: string, name: string>, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, links: record<organizationUrl: string, regionUrl: string>, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool>, plugins: table<id: string, name: string, slug: string, shortName: string, type: string, canDisable: bool, isTestable: bool, hasConfiguration: bool, metadata: record, contexts: list, status: string, assets: list, doc: string, firstPartyAlternative: any, deprecationDate: any, altIsSentryApp: any, enabled: bool, version: string, author: record, isDeprecated: bool, isHidden: bool, description: string, features: list, featureDescriptions: list, resourceLinks: list>, platforms: list<string>, processingIssues: int, defaultEnvironment: string, relayPiiConfig: string, builtinSymbolSources: list<string>, dynamicSamplingBiases: list<record>, symbolSources: string, isDynamicallySampled: bool, tempestFetchScreenshots: bool, autofixAutomationTuning: string, seerScannerAutomation: bool, seerNightshiftTweaks: any, scmSourceContextEnabled: bool, debugFilesRole: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/")
  let body = {isBookmarked: $isBookmarked, name: $name, slug: $slug, platform: $platform, subjectPrefix: $subjectPrefix, subjectTemplate: $subjectTemplate, resolveAge: $resolveAge, highlightContext: $highlightContext, highlightTags: $highlightTags, scmSourceContextEnabled: $scmSourceContextEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedules a project for deletion.  Deletion happens asynchronously and therefore is not immediate. However once deletion has begun the state of a project changes and will be hidden from most public views.
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/
# operationId: Delete a Project
export def "0-projects Delete-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
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
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists a project's environments.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/environments/
# operationId: List a Project's Environments
export def "0-projects-environments List-a-Projects-Environments" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --visibility: string@visibility-completer # The visibility of the environments to filter by. Defaults to `visible`.
]: nothing -> table<id: string, name: string, isHidden: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "visibility" $visibility "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/environments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk update the visibility for a project's environments.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/environments/
# operationId: Bulk Update Project Environments
export def "0-projects-environments Bulk-Update-Project-Environments" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  environmentNames: list # List of environment names to update. Maximum 1000.
  --isHidden: string@bool-completer # Specify `true` to hide or `false` to show the specified environments.
]: any -> table<id: string, name: string, isHidden: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/environments/")
  let body = {environmentNames: $environmentNames, isHidden: $isHidden} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return details on a project environment.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/environments/{environment}/
# operationId: Retrieve a Project Environment
export def "0-projects-environments Retrieve-a-Project-Environment" [
  organization_id_or_slug: string
  project_id_or_slug: string
  environment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, isHidden: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/environments/($environment)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the visibility for a project environment.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/environments/{environment}/
# operationId: Update a Project Environment
export def "0-projects-environments Update-a-Project-Environment" [
  organization_id_or_slug: string
  project_id_or_slug: string
  environment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isHidden: string@bool-completer # Specify `true` to make the environment visible or `false` to make the environment hidden.
]: any -> record<id: string, name: string, isHidden: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/environments/($environment)/")
  let body = {isHidden: $isHidden} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of events bound to a project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/events/
# operationId: List a Project's Error Events
export def "0-projects-events List-a-Projects-Error-Events" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --full: string@bool-completer # Specify true to include the full event body, including the stacktrace, in the event payload. (default: false)
  --sample: string@bool-completer # Return events in pseudo-random order. This is deterministic so an identical query will always return the same events in the same order. (default: false)
]: nothing -> table<id: string, event_type: string, groupID: string, eventID: string, projectID: string, message: string, title: string, location: string, culprit: string, user: record<id: string, email: string, username: string, ip_address: string, name: string, geo: record, data: record>, tags: list<record>, platform: string, dateCreated: string, crashFile: string, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "full" $full "scalar") (serialize-qp "sample" $sample "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/events/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return details on an individual event.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/events/{event_id}/
# operationId: Retrieve an Event for a Project
export def "0-projects-events Retrieve-an-Event-for-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
]: nothing -> record<id: string, groupID: string, eventID: string, projectID: string, message: string, title: string, location: string, user: record<id: string, email: string, username: string, ip_address: string, name: string, geo: record, data: record>, tags: table<query: string, key: string, value: string>, platform: string, dateReceived: string, contexts: record, size: int, entries: list<any>, dist: string, sdk: record, context: record, packages: record, type: string, metadata: any, errors: list<any>, occurrence: any, _meta: record, crashFile: string, culprit: string, dateCreated: string, fingerprints: list<string>, groupingConfig: any, startTimestamp: string, endTimestamp: string, measurements: any, breakdowns: any, release: record<id: int, commitCount: int, data: record, dateCreated: string, dateReleased: string, deployCount: int, ref: string, lastCommit: record, lastDeploy: record<dateStarted: string, url: string, id: string, environment: string, dateFinished: string, name: string>, status: string, url: string, userAgent: string, version: string, versionInfo: record<description: string, package: string, version: record, buildHash: string>>, userReport: record<id: string, eventID: string, name: string, email: string, comments: string, dateCreated: string, user: record<id: string, username: string, email: string, name: string, ipAddress: string, avatarUrl: string>, event: record<id: string, eventID: string>>, sdkUpdates: list<record>, resolvedWith: list<string>, nextEventID: string, previousEventID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/events/($event_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of attachments uploaded for a given event.  Requires the `event-attachments` organization feature.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/events/{event_id}/attachments/
# operationId: List an Event's Attachments
export def "0-projects-events-attachments List-an-Events-Attachments" [
  organization_id_or_slug: string
  project_id_or_slug: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Filter the attachments by name (substring match) or by attachment kind. Use `is:screenshot` to restrict the results to screenshot attachments.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, event_id: string, type: string, name: string, mimetype: string, dateCreated: string, size: int, headers: record, sha1: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/events/($event_id)/attachments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve metadata for a single attachment on an event.  Requires the `event-attachments` organization feature.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/events/{event_id}/attachments/{attachment_id}/
# operationId: Retrieve an Event Attachment
export def "0-projects-events-attachments Retrieve-an-Event-Attachment" [
  organization_id_or_slug: string
  project_id_or_slug: string
  event_id: string
  attachment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, event_id: string, type: string, name: string, mimetype: string, dateCreated: string, size: int, headers: record, sha1: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/events/($event_id)/attachments/($attachment_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of source map errors for a given event.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/events/{event_id}/source-map-debug/
# operationId: Get Debug Information Related to Source Maps for a Given Event
export def "0-projects-events-source-map-debug Get-Debug-Information-Related-to-Source-Maps-for-a-Given-Event" [
  organization_id_or_slug: string
  project_id_or_slug: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dist: string, release: string, exceptions: table<frames: list>, has_debug_ids: bool, min_debug_id_sdk_version: string, sdk_version: string, project_has_some_artifact_bundle: bool, release_has_some_artifact: bool, has_uploaded_some_artifact_with_a_debug_id: bool, sdk_debug_id_support: string, has_scraping_data: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/events/($event_id)/source-map-debug/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of debug information files for a given project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/files/dsyms/
# operationId: List a Project's Debug Information Files
export def "0-projects-files-dsyms List-a-Projects-Debug-Information-Files" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Substring filter matched against object name, debug ID, code ID, CPU name, and file headers.
  --debug-id: string # Filter results to debug information files matching the given debug ID.
  --code-id: string # Filter results to debug information files matching the given code ID.
  --file-formats: list # Restrict results to one or more file formats.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, uuid: string, debugId: string, codeId: string, cpuName: string, objectName: string, symbolType: string, headers: record, size: int, sha1: string, dateCreated: string, data: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "debug_id" $debug_id "scalar") (serialize-qp "code_id" $code_id "scalar") (serialize-qp "file_formats" $file_formats "multi") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/files/dsyms/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of filters for a given project. `active` will be either a boolean or a list for the legacy browser filters.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/filters/
# operationId: List a Project's Data Filters
export def "0-projects-filters List-a-Projects-Data-Filters" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, active: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/filters/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update various inbound data filters for a project.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/filters/{filter_id}/
# operationId: Update an Inbound Data Filter
export def "0-projects-filters Update-an-Inbound-Data-Filter" [
  organization_id_or_slug: string
  project_id_or_slug: string
  filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Toggle the browser-extensions, localhost, filtered-transaction, or web-crawlers filter on or off.
  --subfilters: list #  Specifies which legacy browser filters should be active. Anything excluded from the list will be disabled. The options are: - `ie` - Internet Explorer Version 11 and lower - `edge` - Edge Version 110 and lower - `safari` - Safari Version 15 and lower - `firefox` - Firefox Version 110 and lower - `chrome` - Chrome Version 110 and lower - `opera` - Opera Version 99 and lower - `android` - Android Version 3 and lower - `opera_mini` - Opera Mini Version 34 and lower  Deprecated options: - `ie_pre_9` - Internet Explorer Version 8 and lower - `ie9` - Internet Explorer Version 9 - `ie10` - Internet Explorer Version 10 - `ie11` - Internet Explorer Version 11 - `safari_pre_6` - Safari Version 5 and lower - `opera_pre_15` - Opera Version 14 and lower - `opera_mini_pre_8` - Opera Mini Version 8 and lower - `android_pre_4` - Android Version 3 and lower - `edge_pre_79` - Edge Version 18 and lower (non Chromium based)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/filters/($filter_id)/")
  let body = {active: $active, subfilters: $subfilters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of client keys bound to a project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/keys/
# operationId: List a Project's Client Keys
export def "0-projects-keys List-a-Projects-Client-Keys" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --status: string #  Filter client keys by `active` or `inactive`. Defaults to returning all keys if not specified.
]: nothing -> table<id: string, name: string, label: string, public: string, secret: string, projectId: int, isActive: bool, rateLimit: record<window: int, count: int>, dsn: record<secret: string, public: string, csp: string, security: string, minidump: string, nel: string, unreal: string, crons: string, cdn: string, playstation: string, integration: string, otlp_traces: string, otlp_logs: string>, browserSdkVersion: string, browserSdk: record<choices: list>, dateCreated: string, dynamicSdkLoaderOptions: record<hasReplay: bool, hasPerformance: bool, hasDebug: bool, hasFeedback: bool, hasLogsAndMetrics: bool>, useCase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/keys/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new client key bound to a project.  The key's secret and public key are generated by the server.
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/keys/
# operationId: Create a New Client Key
# --rateLimit shape: {count?: int, window?: int}
export def "0-projects-keys Create-a-New-Client-Key" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The optional name of the key. If not provided it will be automatically generated. (nullable)
  --rateLimit: record # Applies a rate limit to cap the number of errors accepted during a given time window. To disable entirely set `rateLimit` to null. ```json {     "rateLimit": {         "window": 7200, // time in seconds         "count": 1000 // error cap     } } ``` — shape: {count?: int, window?: int}
  --useCase: string@useCase-completer # * `user` * `profiling` * `tempest` * `demo` (default: user)
]: any -> record<id: string, name: string, label: string, public: string, secret: string, projectId: int, isActive: bool, rateLimit: record<window: int, count: int>, dsn: record<secret: string, public: string, csp: string, security: string, minidump: string, nel: string, unreal: string, crons: string, cdn: string, playstation: string, integration: string, otlp_traces: string, otlp_logs: string>, browserSdkVersion: string, browserSdk: record<choices: list<list>>, dateCreated: string, dynamicSdkLoaderOptions: record<hasReplay: bool, hasPerformance: bool, hasDebug: bool, hasFeedback: bool, hasLogsAndMetrics: bool>, useCase: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/keys/")
  let body = {name: $name, rateLimit: $rateLimit, useCase: $useCase} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a client key bound to a project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/keys/{key_id}/
# operationId: Retrieve a Client Key
export def "0-projects-keys Retrieve-a-Client-Key" [
  organization_id_or_slug: string
  project_id_or_slug: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, label: string, public: string, secret: string, projectId: int, isActive: bool, rateLimit: record<window: int, count: int>, dsn: record<secret: string, public: string, csp: string, security: string, minidump: string, nel: string, unreal: string, crons: string, cdn: string, playstation: string, integration: string, otlp_traces: string, otlp_logs: string>, browserSdkVersion: string, browserSdk: record<choices: list<list>>, dateCreated: string, dynamicSdkLoaderOptions: record<hasReplay: bool, hasPerformance: bool, hasDebug: bool, hasFeedback: bool, hasLogsAndMetrics: bool>, useCase: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/keys/($key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update various settings for a client key.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/keys/{key_id}/
# operationId: Update a Client Key
# --rateLimit shape: {count?: int, window?: int}
# --dynamicSdkLoaderOptions shape: {hasReplay?: bool, hasPerformance?: bool, hasDebug?: bool, hasFeedback?: bool, hasLogsAndMetrics?: bool}
export def "0-projects-keys Update-a-Client-Key" [
  organization_id_or_slug: string
  project_id_or_slug: string
  key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name for the client key
  --isActive: string@bool-completer # Activate or deactivate the client key.
  --rateLimit: record # Applies a rate limit to cap the number of errors accepted during a given time window. To disable entirely set `rateLimit` to null. ```json {     "rateLimit": {         "window": 7200, // time in seconds         "count": 1000 // error cap     } } ``` — shape: {count?: int, window?: int}
  --browserSdkVersion: string@browserSdkVersion-completer # The Sentry Javascript SDK version to use. The currently supported options are:  * `latest` - Most recent version * `7.x` - Version 7 releases
  --dynamicSdkLoaderOptions: record # Configures multiple options for the Javascript Loader Script. - `Performance Monitoring` - `Debug Bundles & Logging` - `Session Replay` - Note that the loader will load the ES6 bundle instead of the ES5 bundle. - `User Feedback` - Note that the loader will load the ES6 bundle instead of the ES5 bundle. - `Logs and Metrics` - Note that the loader will load the ES6 bundle instead of the ES5 bundle. Requires SDK >= 10.0.0. ```json {     "dynamicSdkLoaderOptions": {         "hasReplay": true,         "hasPerformance": true,         "hasDebug": true,         "hasFeedback": true,         "hasLogsAndMetrics": true     } } ``` — shape: {hasReplay?: bool, hasPerformance?: bool, hasDebug?: bool, hasFeedback?: bool, hasLogsAndMetrics?: bool}
]: any -> record<id: string, name: string, label: string, public: string, secret: string, projectId: int, isActive: bool, rateLimit: record<window: int, count: int>, dsn: record<secret: string, public: string, csp: string, security: string, minidump: string, nel: string, unreal: string, crons: string, cdn: string, playstation: string, integration: string, otlp_traces: string, otlp_logs: string>, browserSdkVersion: string, browserSdk: record<choices: list<list>>, dateCreated: string, dynamicSdkLoaderOptions: record<hasReplay: bool, hasPerformance: bool, hasDebug: bool, hasFeedback: bool, hasLogsAndMetrics: bool>, useCase: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/keys/($key_id)/")
  let body = {name: $name, isActive: $isActive, rateLimit: $rateLimit, browserSdkVersion: $browserSdkVersion, dynamicSdkLoaderOptions: $dynamicSdkLoaderOptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a client key for a given project.
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/keys/{key_id}/
# operationId: Delete a Client Key
export def "0-projects-keys Delete-a-Client-Key" [
  organization_id_or_slug: string
  project_id_or_slug: string
  key_id: string
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
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/keys/($key_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of active organization members that belong to any team assigned to the project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/members/
# operationId: List a Project's Organization Members
export def "0-projects-members List-a-Projects-Organization-Members" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<externalUsers: list<record>, id: string, email: string, name: string, user: record<identities: list, avatar: record, authenticators: list, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list>, orgRole: string, pending: bool, expired: bool, flags: record<idp_provisioned: bool, idp_role_restricted: bool, sso_linked: bool, sso_invalid: bool, member_limit_restricted: bool, partnership_restricted: bool>, dateCreated: string, inviteStatus: string, inviterName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/members/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves details for a monitor.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/monitors/{monitor_id_or_slug}/
# operationId: Retrieve a Monitor for a Project
export def "0-projects-monitors Retrieve-a-Monitor-for-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  monitor_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<alertRule: record<targets: list<record>, environment: string>, id: string, name: string, slug: string, status: string, isMuted: bool, isUpserting: bool, config: record<schedule_type: string, schedule: any, checkin_margin: int, max_runtime: int, timezone: string, failure_issue_threshold: int, recovery_threshold: int, alert_rule_id: int>, dateCreated: string, project: record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string>, environments: record<name: string, status: string, isMuted: bool, dateCreated: string, lastCheckIn: string, nextCheckIn: string, nextCheckInLatest: string, activeIncident: record<startingTimestamp: string, resolvingTimestamp: string, brokenNotice: record>>, owner: record<type: string, id: string, name: string, email: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/monitors/($monitor_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a monitor.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/monitors/{monitor_id_or_slug}/
# operationId: Update a Monitor for a Project
export def "0-projects-monitors Update-a-Monitor-for-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  monitor_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  project: string # The project slug to associate the monitor to.
  name: string # Name of the monitor. Used for notifications. If not set the slug will be derived from your monitor name.
  config: any # The configuration for the monitor.
  --slug: string # Uniquely identifies your monitor within your organization. Changing this slug will require updates to any instrumented check-in calls.
  --status: string@status-completer-1 # Status of the monitor. Disabled monitors will not accept events and will not count towards the monitor quota.  * `active` * `disabled` (default: active)
  --owner: string # The ID of the team or user that owns the monitor. (eg. user:51 or team:6) (nullable)
  --is-muted: string@bool-completer # Disable creation of monitor incidents
]: any -> record<alertRule: record<targets: list<record>, environment: string>, id: string, name: string, slug: string, status: string, isMuted: bool, isUpserting: bool, config: record<schedule_type: string, schedule: any, checkin_margin: int, max_runtime: int, timezone: string, failure_issue_threshold: int, recovery_threshold: int, alert_rule_id: int>, dateCreated: string, project: record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string>, environments: record<name: string, status: string, isMuted: bool, dateCreated: string, lastCheckIn: string, nextCheckIn: string, nextCheckInLatest: string, activeIncident: record<startingTimestamp: string, resolvingTimestamp: string, brokenNotice: record>>, owner: record<type: string, id: string, name: string, email: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/monitors/($monitor_id_or_slug)/")
  let body = {project: $project, name: $name, config: $config, slug: $slug, status: $status, owner: $owner, is_muted: $is_muted} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a monitor or monitor environments.
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/monitors/{monitor_id_or_slug}/
# operationId: Delete a Monitor or Monitor Environments for a Project
export def "0-projects-monitors Delete-a-Monitor-or-Monitor-Environments-for-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  monitor_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/monitors/($monitor_id_or_slug)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of check-ins for a monitor
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/monitors/{monitor_id_or_slug}/checkins/
# operationId: Retrieve Check-Ins for a Monitor by Project
export def "0-projects-monitors-checkins Retrieve-Check-Ins-for-a-Monitor-by-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  monitor_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<groups: list<string>, id: string, environment: string, status: string, duration: int, dateCreated: string, dateAdded: string, dateUpdated: string, dateInProgress: string, dateClock: string, expectedTime: string, monitorConfig: record<schedule_type: string, schedule: any, checkin_margin: int, max_runtime: int, timezone: string, failure_issue_threshold: int, recovery_threshold: int, alert_rule_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/monitors/($monitor_id_or_slug)/checkins/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns details on a project's ownership configuration.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/ownership/
# operationId: Retrieve Ownership Configuration for a Project
export def "0-projects-ownership Retrieve-Ownership-Configuration-for-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<schema: record<_version: int, rules: list<record>>, raw: string, fallthrough: bool, dateCreated: string, lastUpdated: string, isActive: bool, autoAssignment: string, codeownersAutoSync: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/ownership/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates ownership configurations for a project. Note that only the attributes submitted are modified.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/ownership/
# operationId: Update Ownership Configuration for a Project
export def "0-projects-ownership Update-Ownership-Configuration-for-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-raw: string # Raw input for ownership configuration. See the [Ownership Rules Documentation](/product/issues/ownership-rules/) to learn more.
  --fallthrough: string@bool-completer # A boolean determining who to assign ownership to when an ownership rule has no match. If set to `True`, all project members are made owners. Otherwise, no owners are set.
  --autoAssignment: string # Auto-assignment settings. The available options are: - Auto Assign to Issue Owner - Auto Assign to Suspect Commits - Turn off Auto-Assignment
  --codeownersAutoSync: string@bool-completer # Set to `True` to sync issue owners with CODEOWNERS updates in a release. (default: true)
]: any -> record<schema: record<_version: int, rules: list<record>>, raw: string, fallthrough: bool, dateCreated: string, lastUpdated: string, isActive: bool, autoAssignment: string, codeownersAutoSync: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/ownership/")
  let body = {raw: $body_raw, fallthrough: $fallthrough, autoAssignment: $autoAssignment, codeownersAutoSync: $codeownersAutoSync} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the current Size Analysis status check rules configured for a project.  Use this endpoint after receiving a `size_analysis.completed` webhook when you want external CI to evaluate the same Size Analysis status check thresholds that Sentry uses. The endpoint returns the current project configuration, not a historical snapshot from when the webhook was emitted.  The response includes whether status check enforcement is enabled and the normalized rule list Sentry uses when evaluating Size Analysis thresholds.  This endpoint requires a bearer token with `project:read` access. Project distribution tokens are not supported.  Response notes:  - `enabled: false` means status-check enforcement is disabled for the project. - `rules: []` means there are no configured thresholds to evaluate. - `value` is returned as a string. For `absolute` and `absolute_diff`   measurements it is a byte value; for `relative_diff` it is a percentage. - `filterQuery` is the original configured filter string. - `filters` is the machine-readable version of `filterQuery`. - `filters: []` means the rule has no filters and applies to all builds. - `filters: null` means the saved filter query could not be parsed; Sentry's   status check trigger treats that rule as non-matching.  Rule evaluation semantics:  - Threshold comparisons are strict: a rule triggers only when the computed value   is greater than the configured threshold, not greater than or equal to it. - `absolute_diff` and `relative_diff` require a matching base metric/build. - `relative_diff` does not trigger when the base size is zero. - `artifactType` identifies the artifact scope the rule evaluates.   `main_artifact`, `watch_artifact`, `android_dynamic_feature_artifact`,   and `app_clip_artifact` target their matching artifact metric.   `all_artifacts` evaluates all available artifact metrics. - Rule filters support the keys `app_id`, `git_head_ref`,   `build_configuration_name`, and `platform_name`. - Filter objects are combined with AND. Multiple `conditions` inside one   filter object are combined with OR. - Each condition uses `values`; single-value operators still return a   one-item array. - Values in `filters` are decoded literal values for exact/simple operators,   not query syntax. For example, `app_id:\*com` in `filterQuery` becomes   `values: ["*com"]` with `operator: "equals"`. - The same key can appear in more than one filter object when positive and   negative conditions both exist; those filter objects are still combined with   AND. - Supported filter operators are `equals`, `notEquals`, `in`, `notIn`,   `contains`, `notContains`, `startsWith`, `notStartsWith`, `endsWith`,   `notEndsWith`, `matches`, and `notMatches`. - `matches` and `notMatches` values use Sentry wildcard pattern syntax, not   regular expressions. `*` matches zero or more characters, escaped `\*`   matches a literal asterisk, and a pattern without `*` is an exact match. - `in` and `notIn` are evaluated as one condition against all values, matching   Sentry's status check trigger behavior. - A rule applies only when the build metadata matches all filters. If a   referenced metadata key is missing, the filter does not match, even for   negated operators.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/preprod/size-analysis/status-check-rules/
# operationId: Retrieve Size Analysis status check rules for a project
export def "0-projects-preprod-size-analysis-status-check-rules Retrieve-Size-Analysis-status-check-rules-for-a-project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, rules: table<id: string, metric: string, measurement: string, value: string, filterQuery: string, filters: list, artifactType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/preprod/size-analysis/status-check-rules/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the current Snapshot status check rules configured for a project.  Use this endpoint when external CI needs to evaluate the same Snapshot change-type rules that Sentry uses. The endpoint returns the current project configuration, not a historical snapshot from when a build was processed.  The response includes whether status check enforcement is enabled and the Snapshot change types that fail the status check.  This endpoint requires a bearer token with `project:read` access. Project distribution tokens are not supported.  Response notes:  - `enabled: false` means status-check enforcement is disabled for the project. - `rules` contains one boolean per Snapshot change type. - `failOnAdded`, `failOnRemoved`, `failOnChanged`, and `failOnRenamed`   indicate which unapproved change types fail the status check.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/preprod/snapshots/status-check-rules/
# operationId: Retrieve Snapshot status check rules for a project
export def "0-projects-preprod-snapshots-status-check-rules Retrieve-Snapshot-status-check-rules-for-a-project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, rules: record<failOnAdded: bool, failOnRemoved: bool, failOnChanged: bool, failOnRenamed: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/preprod/snapshots/status-check-rules/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the latest installable build for a project.  Returns the latest installable build matching filter criteria. When buildVersion is provided, also returns the current build and whether an update is available.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/preprodartifacts/build-distribution/latest/
# operationId: Get the latest installable build for a project
export def "0-projects-preprodartifacts-build-distribution-latest Get-the-latest-installable-build-for-a-project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --appId: string # App identifier (exact match).
  --platform: string # Platform: "apple" or "android".
  --buildVersion: string # Current build version. When provided, enables check-for-updates mode.
  --buildNumber: int # Current build number. Either this or mainBinaryIdentifier must be provided when buildVersion is set.
  --mainBinaryIdentifier: string # UUID of the main binary (e.g. Mach-O UUID for Apple builds). Either this or buildNumber must be provided when buildVersion is set.
  --buildConfiguration: string # Filter by build configuration name (exact match).
  --codesigningType: string # Filter by code signing type.
  --installGroups: list # Filter by install group name (repeatable for multiple groups).
]: nothing -> record<latestArtifact: record<buildId: string, state: string, appInfo: record<appId: string, name: string, version: string, buildNumber: int, artifactType: string, dateAdded: string, dateBuilt: string>, gitInfo: record<headSha: string, baseSha: string, provider: string, headRepoName: string, baseRepoName: string, headRef: string, baseRef: string, prNumber: int>, platform: string, projectId: string, projectSlug: string, buildConfiguration: string, isInstallable: bool, installUrl: string, installUrlExpiresAt: string, downloadCount: int, releaseNotes: string, installGroups: list<string>, isCodeSignatureValid: bool, profileName: string, codesigningType: string>, currentArtifact: record<buildId: string, state: string, appInfo: record<appId: string, name: string, version: string, buildNumber: int, artifactType: string, dateAdded: string, dateBuilt: string>, gitInfo: record<headSha: string, baseSha: string, provider: string, headRepoName: string, baseRepoName: string, headRef: string, baseRef: string, prNumber: int>, platform: string, projectId: string, projectSlug: string, buildConfiguration: string, isInstallable: bool, installUrl: string, installUrlExpiresAt: string, downloadCount: int, releaseNotes: string, installGroups: list<string>, isCodeSignatureValid: bool, profileName: string, codesigningType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $appId "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "buildVersion" $buildVersion "scalar") (serialize-qp "buildNumber" $buildNumber "scalar") (serialize-qp "mainBinaryIdentifier" $mainBinaryIdentifier "scalar") (serialize-qp "buildConfiguration" $buildConfiguration "scalar") (serialize-qp "codesigningType" $codesigningType "scalar") (serialize-qp "installGroups" $installGroups "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/preprodartifacts/build-distribution/latest/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a new snapshot with image metadata.  The request body is a JSON object containing `app_id` (required), `images` (required, a mapping of filenames to image metadata objects), and optional VCS fields (`head_sha`, `base_sha`, `provider`, `head_repo_name`, `head_ref`, `base_repo_name`, `base_ref`, `pr_number`).  When VCS info with a `base_sha` is provided and a matching base snapshot exists, a comparison is automatically triggered.  This endpoint requires a bearer token with `project:write` access.
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/preprodartifacts/snapshots/
# operationId: Upload a Snapshot
export def "0-projects-preprodartifacts-snapshots Upload-a-Snapshot" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<artifactId: string, snapshotMetricsId: string, imageCount: int, snapshotUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/preprodartifacts/snapshots/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a single profile by its ID.  The response includes the profile's metadata, its sampled stack data, and the associated release, when one is found.  Requires profiling to be enabled for the organization.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/profiling/profiles/{profile_id}/
# operationId: Retrieve a Profile
export def "0-projects-profiling-profiles Retrieve-a-Profile" [
  organization_id_or_slug: string
  project_id_or_slug: string
  profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/profiling/profiles/($profile_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of releases for a given project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/releases/
# operationId: List a Project's Releases
export def "0-projects-releases List-a-Projects-Releases" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
  --qp-query: string # Case-insensitive substring match against the release version.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<ref: string, url: string, dateReleased: string, dateCreated: string, dateStarted: string, owner: record, lastCommit: record, lastDeploy: record<dateStarted: string, url: string, id: string, environment: string, dateFinished: string, name: string>, firstEvent: string, lastEvent: string, currentProjectMeta: record, userAgent: string, adoptionStages: record, id: int, version: string, newGroups: int, status: string, shortVersion: string, versionInfo: record<description: string, package: string, version: record, buildHash: string>, data: record, commitCount: int, deployCount: int, authors: list<any>, projects: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/releases/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Replay Instance
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/replays/{replay_id}/
# operationId: deleteProjectReplay
export def "0-projects-replays delete" [
  organization_id_or_slug: string
  project_id_or_slug: string
  replay_id: string
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
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/replays/($replay_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Clicked Nodes
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/replays/{replay_id}/clicks/
# operationId: listProjectReplayClicks
export def "0-projects-replays-clicks listProjectReplayClicks" [
  organization_id_or_slug: string
  project_id_or_slug: string
  replay_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --environment: list # The name of environments to filter by.
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
  --qp-query: string # Filters results by using [query syntax](/product/sentry-basics/search/).  Example: `query=(transaction:foo AND release:abc) OR (transaction:[bar,baz] AND release:def)`
]: nothing -> record<data: table<node_id: int, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "environment" $environment "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/replays/($replay_id)/clicks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Recording Segments
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/replays/{replay_id}/recording-segments/
# operationId: listProjectReplayRecordingSegments
export def "0-projects-replays-recording-segments listProjectReplayRecordingSegments" [
  organization_id_or_slug: string
  project_id_or_slug: string
  replay_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
  --per-page: int # Limit the number of rows to return in the result. Default and maximum allowed is 100.
]: nothing -> list<list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/replays/($replay_id)/recording-segments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a Recording Segment
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/replays/{replay_id}/recording-segments/{segment_id}/
# operationId: getProjectReplayRecordingSegment
export def "0-projects-replays-recording-segments get" [
  organization_id_or_slug: string
  project_id_or_slug: string
  replay_id: string
  segment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<replayId: string, segmentId: int, projectId: string, dateAdded: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/replays/($replay_id)/recording-segments/($segment_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Users Who Have Viewed a Replay
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/replays/{replay_id}/viewed-by/
# operationId: listProjectReplayViewedBy
export def "0-projects-replays-viewed-by listProjectReplayViewedBy" [
  organization_id_or_slug: string
  project_id_or_slug: string
  replay_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<viewed_by: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/replays/($replay_id)/viewed-by/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Replay Batch-Deletion Jobs
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/replays/jobs/delete/
# operationId: listProjectReplayDeletionJobs
export def "0-projects-replays-jobs-delete listProjectReplayDeletionJobs" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: int, dateCreated: string, dateUpdated: string, rangeStart: string, rangeEnd: string, environments: list, status: string, query: string, countDeleted: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/replays/jobs/delete/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Replay Batch Deletion Job
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/replays/jobs/delete/
# operationId: createProjectReplayDeletionJob
# --data shape: {rangeStart: string, rangeEnd: string, environments: list, query: string}
export def "0-projects-replays-jobs-delete createProjectReplayDeletionJob" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {rangeStart: string, rangeEnd: string, environments: list, query: string}
]: any -> record<data: record<id: int, dateCreated: string, dateUpdated: string, rangeStart: string, rangeEnd: string, environments: list<string>, status: string, query: string, countDeleted: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/replays/jobs/delete/")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Replay Batch-Deletion Job
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/replays/jobs/delete/{job_id}/
# operationId: getProjectReplayDeletionJob
export def "0-projects-replays-jobs-delete get" [
  organization_id_or_slug: string
  project_id_or_slug: string
  job_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, dateCreated: string, dateUpdated: string, rangeStart: string, rangeEnd: string, environments: list<string>, status: string, query: string, countDeleted: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/replays/jobs/delete/($job_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link a repository to a project. The repository must already exist in the organization (connected via a VCS integration). Idempotent: returns 200 if the link already exists, 201 if created.
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/repo/
# operationId: Link a Repository to a Project
export def "0-projects-repo Link-a-Repository-to-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  repositoryId: int # The ID of the repository to link.
]: any -> record<id: string, projectId: string, repositoryId: string, source: string, created: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/repo/")
  let body = {repositoryId: $repositoryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a set of points representing a normalized timestamp and the number of events seen in the period.  Query ranges are limited to Sentry's configured time-series resolutions. This endpoint may change in the future without notice.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/stats/
# operationId: Retrieve Event Counts for a Project
export def "0-projects-stats Retrieve-Event-Counts-for-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --stat: string@stat-completer # The name of the stat to query. Defaults to `received`.
  --since: float # A UNIX timestamp (in seconds) that sets the start of the query range. (format: double)
  --until: float # A UNIX timestamp (in seconds) that sets the end of the query range. (format: double)
  --resolution: string@resolution-completer # An explicit time series resolution.
]: nothing -> list<list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stat" $stat "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "resolution" $resolution "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/stats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List custom symbol sources configured for a project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/symbol-sources/
# operationId: Retrieve a Project's Symbol Sources
export def "0-projects-symbol-sources Retrieve-a-Projects-Symbol-Sources" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID of the source to look up. If this is not provided, all sources are returned.
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/symbol-sources/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a custom symbol source to a project.
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/symbol-sources/
# operationId: Add a Symbol Source to a Project
# --layout shape: {type: "native"|"symstore"|"symstore_index2"|"ssqp"|"unified"|"debuginfod"|"slashsymbols", casing: "lowercase"|"uppercase"|"default"}
# --filters shape: {filetypes?: list, path_patterns?: list, requires_checksum?: bool}
export def "0-projects-symbol-sources Add-a-Symbol-Source-to-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string@type-completer # The type of the source.  * `http` - SymbolServer (HTTP) * `gcs` - Google Cloud Storage * `s3` - Amazon S3
  name: string # The human-readable name of the source.
  --id: string # The internal ID of the source. Must be distinct from all other source IDs and cannot start with '`sentry:`'. If this is not provided, a new UUID will be generated.
  --layout: record # Layout settings for the source. This is required for HTTP, GCS, and S3 sources.  **`type`** ***(string)*** - The layout of the folder structure. The options are: - `native` - Platform-Specific (SymStore / GDB / LLVM) - `symstore` - Microsoft SymStore - `symstore_index2` - Microsoft SymStore (with index2.txt) - `ssqp` - Microsoft SSQP - `unified` - Unified Symbol Server Layout - `debuginfod` - debuginfod  **`casing`** ***(string)*** - The layout of the folder structure. The options are: - `default` - Default (mixed case) - `uppercase` - Uppercase - `lowercase` - Lowercase  ```json {     "layout": {         "type": "native"         "casing": "default"     } } ``` — shape: {type: "native"|"symstore"|"symstore_index2"|"ssqp"|"unified"|"debuginfod"|"slashsymbols", casing: "lowercase"|"uppercase"|"default"}
  --filters: record # Filter settings for the source. This is optional for all sources.  **`filetypes`** ***(list)*** - A list of file types that can be found on this source. If this is left empty, all file types will be enabled. The options are: - `pe` - Windows executable files - `pdb` - Windows debug files - `portablepdb` - .NET portable debug files - `mach_code` - MacOS executable files - `mach_debug` - MacOS debug files - `elf_code` - ELF executable files - `elf_debug` - ELF debug files - `wasm_code` - WASM executable files - `wasm_debug` - WASM debug files - `breakpad` - Breakpad symbol files - `sourcebundle` - Source code bundles - `uuidmap` - Apple UUID mapping files - `bcsymbolmap` - Apple bitcode symbol maps - `il2cpp` - Unity IL2CPP mapping files - `proguard` - ProGuard mapping files  **`path_patterns`** ***(list)*** - A list of glob patterns to check against the debug and code file paths of debug files. Only files that match one of these patterns will be requested from the source. If this is left empty, no path-based filtering takes place.  **`requires_checksum`** ***(boolean)*** - Whether this source requires a debug checksum to be sent with each request. Defaults to `false`.  ```json {     "filters": {         "filetypes": ["pe", "pdb", "portablepdb"],         "path_patterns": ["*ffmpeg*"]     } } ``` — shape: {filetypes?: list, path_patterns?: list, requires_checksum?: bool}
  --body-url: string # The source's URL. Optional for HTTP sources, invalid for all others.
  --username: string # The user name for accessing the source. Optional for HTTP sources, invalid for all others.
  --password: string # The password for accessing the source. Optional for HTTP sources, invalid for all others.
  --bucket: string # The GCS or S3 bucket where the source resides. Required for GCS and S3 source, invalid for HTTP sources.
  --region: string@region-completer # The source's [S3 region](https://docs.aws.amazon.com/general/latest/gr/s3.html). Required for S3 sources, invalid for all others.  * `us-east-2` - US East (Ohio) * `us-east-1` - US East (N. Virginia) * `us-west-1` - US West (N. California) * `us-west-2` - US West (Oregon) * `ap-east-1` - Asia Pacific (Hong Kong) * `ap-south-1` - Asia Pacific (Mumbai) * `ap-northeast-2` - Asia Pacific (Seoul) * `ap-southeast-1` - Asia Pacific (Singapore) * `ap-southeast-2` - Asia Pacific (Sydney) * `ap-northeast-1` - Asia Pacific (Tokyo) * `ca-central-1` - Canada (Central) * `cn-north-1` - China (Beijing) * `cn-northwest-1` - China (Ningxia) * `eu-central-1` - EU (Frankfurt) * `eu-west-1` - EU (Ireland) * `eu-west-2` - EU (London) * `eu-west-3` - EU (Paris) * `eu-north-1` - EU (Stockholm) * `sa-east-1` - South America (São Paulo) * `us-gov-east-1` - AWS GovCloud (US-East) * `us-gov-west-1` - AWS GovCloud (US)
  --access-key: string # The [AWS Access Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys).Required for S3 sources, invalid for all others.
  --secret-key: string # The [AWS Secret Access Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys).Required for S3 sources, invalid for all others.
  --prefix: string # The GCS or [S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-prefixes.html) prefix. Optional for GCS and S3 sourcse, invalid for HTTP.
  --client-email: string # The GCS email address for authentication. Required for GCS sources, invalid for all others.
  --private-key: string # The GCS private key. Required for GCS sources if not using impersonated tokens. Invalid for all others.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/symbol-sources/")
  let body = {type: $type, name: $name, id: $id, layout: $layout, filters: $filters, url: $body_url, username: $username, password: $password, bucket: $bucket, region: $region, access_key: $access_key, secret_key: $secret_key, prefix: $prefix, client_email: $client_email, private_key: $private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a custom symbol source in a project.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/symbol-sources/
# operationId: Update a Project's Symbol Source
# --layout shape: {type: "native"|"symstore"|"symstore_index2"|"ssqp"|"unified"|"debuginfod"|"slashsymbols", casing: "lowercase"|"uppercase"|"default"}
# --filters shape: {filetypes?: list, path_patterns?: list, requires_checksum?: bool}
export def "0-projects-symbol-sources Update-a-Projects-Symbol-Source" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID of the source to update.
  type: string@type-completer # The type of the source.  * `http` - SymbolServer (HTTP) * `gcs` - Google Cloud Storage * `s3` - Amazon S3
  name: string # The human-readable name of the source.
  --id: string # The internal ID of the source. Must be distinct from all other source IDs and cannot start with '`sentry:`'. If this is not provided, a new UUID will be generated.
  --layout: record # Layout settings for the source. This is required for HTTP, GCS, and S3 sources.  **`type`** ***(string)*** - The layout of the folder structure. The options are: - `native` - Platform-Specific (SymStore / GDB / LLVM) - `symstore` - Microsoft SymStore - `symstore_index2` - Microsoft SymStore (with index2.txt) - `ssqp` - Microsoft SSQP - `unified` - Unified Symbol Server Layout - `debuginfod` - debuginfod  **`casing`** ***(string)*** - The layout of the folder structure. The options are: - `default` - Default (mixed case) - `uppercase` - Uppercase - `lowercase` - Lowercase  ```json {     "layout": {         "type": "native"         "casing": "default"     } } ``` — shape: {type: "native"|"symstore"|"symstore_index2"|"ssqp"|"unified"|"debuginfod"|"slashsymbols", casing: "lowercase"|"uppercase"|"default"}
  --filters: record # Filter settings for the source. This is optional for all sources.  **`filetypes`** ***(list)*** - A list of file types that can be found on this source. If this is left empty, all file types will be enabled. The options are: - `pe` - Windows executable files - `pdb` - Windows debug files - `portablepdb` - .NET portable debug files - `mach_code` - MacOS executable files - `mach_debug` - MacOS debug files - `elf_code` - ELF executable files - `elf_debug` - ELF debug files - `wasm_code` - WASM executable files - `wasm_debug` - WASM debug files - `breakpad` - Breakpad symbol files - `sourcebundle` - Source code bundles - `uuidmap` - Apple UUID mapping files - `bcsymbolmap` - Apple bitcode symbol maps - `il2cpp` - Unity IL2CPP mapping files - `proguard` - ProGuard mapping files  **`path_patterns`** ***(list)*** - A list of glob patterns to check against the debug and code file paths of debug files. Only files that match one of these patterns will be requested from the source. If this is left empty, no path-based filtering takes place.  **`requires_checksum`** ***(boolean)*** - Whether this source requires a debug checksum to be sent with each request. Defaults to `false`.  ```json {     "filters": {         "filetypes": ["pe", "pdb", "portablepdb"],         "path_patterns": ["*ffmpeg*"]     } } ``` — shape: {filetypes?: list, path_patterns?: list, requires_checksum?: bool}
  --body-url: string # The source's URL. Optional for HTTP sources, invalid for all others.
  --username: string # The user name for accessing the source. Optional for HTTP sources, invalid for all others.
  --password: string # The password for accessing the source. Optional for HTTP sources, invalid for all others.
  --bucket: string # The GCS or S3 bucket where the source resides. Required for GCS and S3 source, invalid for HTTP sources.
  --region: string@region-completer # The source's [S3 region](https://docs.aws.amazon.com/general/latest/gr/s3.html). Required for S3 sources, invalid for all others.  * `us-east-2` - US East (Ohio) * `us-east-1` - US East (N. Virginia) * `us-west-1` - US West (N. California) * `us-west-2` - US West (Oregon) * `ap-east-1` - Asia Pacific (Hong Kong) * `ap-south-1` - Asia Pacific (Mumbai) * `ap-northeast-2` - Asia Pacific (Seoul) * `ap-southeast-1` - Asia Pacific (Singapore) * `ap-southeast-2` - Asia Pacific (Sydney) * `ap-northeast-1` - Asia Pacific (Tokyo) * `ca-central-1` - Canada (Central) * `cn-north-1` - China (Beijing) * `cn-northwest-1` - China (Ningxia) * `eu-central-1` - EU (Frankfurt) * `eu-west-1` - EU (Ireland) * `eu-west-2` - EU (London) * `eu-west-3` - EU (Paris) * `eu-north-1` - EU (Stockholm) * `sa-east-1` - South America (São Paulo) * `us-gov-east-1` - AWS GovCloud (US-East) * `us-gov-west-1` - AWS GovCloud (US)
  --access-key: string # The [AWS Access Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys).Required for S3 sources, invalid for all others.
  --secret-key: string # The [AWS Secret Access Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/security-creds.html#access-keys-and-secret-access-keys).Required for S3 sources, invalid for all others.
  --prefix: string # The GCS or [S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-prefixes.html) prefix. Optional for GCS and S3 sourcse, invalid for HTTP.
  --client-email: string # The GCS email address for authentication. Required for GCS sources, invalid for all others.
  --private-key: string # The GCS private key. Required for GCS sources if not using impersonated tokens. Invalid for all others.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/symbol-sources/" $qp)
  let body = {type: $type, name: $name, id: $id, layout: $layout, filters: $filters, url: $body_url, username: $username, password: $password, bucket: $bucket, region: $region, access_key: $access_key, secret_key: $secret_key, prefix: $prefix, client_email: $client_email, private_key: $private_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom symbol source from a project.
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/symbol-sources/
# operationId: Delete a Symbol Source from a Project
export def "0-projects-symbol-sources Delete-a-Symbol-Source-from-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID of the source to delete.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/symbol-sources/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of teams that have access to this project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/teams/
# operationId: List a Project's Teams
export def "0-projects-teams List-a-Projects-Teams" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list<string>, hasAccess: bool, isPending: bool, memberCount: int, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/teams/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Give a team access to a project.
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/teams/{team_id_or_slug}/
# operationId: Add a Team to a Project
export def "0-projects-teams Add-a-Team-to-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string, team: record<id: string, name: string, slug: string>, teams: table<id: string, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/teams/($team_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke a team's access to a project.  Note that Team Admins can only revoke access to teams they are admins of.
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/teams/{team_id_or_slug}/
# operationId: Delete a Team from a Project
export def "0-projects-teams Delete-a-Team-from-a-Project" [
  organization_id_or_slug: string
  project_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, color: string, status: string, team: record<id: string, name: string, slug: string>, teams: table<id: string, name: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/teams/($team_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of users seen within this project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/users/
# operationId: List a Project's Users
export def "0-projects-users List-a-Projects-Users" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # Limit results to users matching the given query. Prefixes should be used to suggest the field to match on: `id`, `email`, `username`, `ip`. For example, `query=email:foo@example.com`.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, tagValue: string, identifier: string, username: string, email: string, name: string, ipAddress: string, avatarUrl: string, hash: string, dateCreated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/users/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of actively used LLM model names from Seer.  Returns the list of AI models that are currently used in production in Seer. This endpoint does not require authentication and can be used to discover which models Seer uses.  Requests to this endpoint should use the region-specific domain eg. `us.sentry.io` or `de.sentry.io`
#
# GET /api/0/seer/models/
# operationId: List Seer AI Models
export def "0-seer-models List-Seer-AI-Models" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<models: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{region}.sentry.io")
  let full_url = (build-url $base "/api/0/seer/models/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a custom integration.
#
# GET /api/0/sentry-apps/{sentry_app_id_or_slug}/
# operationId: Retrieve a custom integration by ID or slug.
export def "0-sentry-apps Retrieve-a-custom-integration-by-ID-or-slug" [
  sentry_app_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<allowedOrigins: list<string>, avatars: table<avatarType: string, avatarUuid: string, avatarUrl: string, color: bool, photoType: string>, events: list<string>, featureData: list<string>, isAlertable: bool, metadata: string, name: string, schema: string, scopes: list<string>, slug: string, status: string, uuid: string, verifyInstall: bool, isDisabled: bool, author: string, overview: string, popularity: int, redirectUrl: string, webhookUrl: string, clientSecret: string, datePublished: string, clientId: string, owner: record<id: int, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/sentry-apps/($sentry_app_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing custom integration.
#
# PUT /api/0/sentry-apps/{sentry_app_id_or_slug}/
# operationId: Update an existing custom integration.
export def "0-sentry-apps Update-an-existing-custom-integration" [
  sentry_app_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name of the custom integration.
  --scopes: list # The custom integration's permission scopes for API access. (nullable)
  --author: string # The custom integration's author. (nullable)
  --events: list # Webhook events the custom integration is subscribed to. (nullable)
  --schema: record # The UI components schema, used to render the custom integration's configuration UI elements. See our [schema docs](https://docs.sentry.io/organization/integrations/integration-platform/ui-components/) for more information. (nullable)
  --webhookUrl: string # The webhook destination URL. (nullable, format: uri)
  --redirectUrl: string # The post-installation redirect URL. (nullable, format: uri)
  --isInternal: string@bool-completer # Whether or not the integration is internal only. False means the integration is public. (default: false)
  --isAlertable: string@bool-completer # Marks whether or not the custom integration can be used in an alert rule. (default: false)
  --overview: string # The custom integration's description. (nullable)
  --verifyInstall: string@bool-completer # Whether or not an installation of the custom integration should be verified. (default: true)
  --allowedOrigins: list # The list of allowed origins for CORS.
]: any -> record<allowedOrigins: list<string>, avatars: table<avatarType: string, avatarUuid: string, avatarUrl: string, color: bool, photoType: string>, events: list<string>, featureData: list<string>, isAlertable: bool, metadata: string, name: string, schema: string, scopes: list<string>, slug: string, status: string, uuid: string, verifyInstall: bool, isDisabled: bool, author: string, overview: string, popularity: int, redirectUrl: string, webhookUrl: string, clientSecret: string, datePublished: string, clientId: string, owner: record<id: int, slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/sentry-apps/($sentry_app_id_or_slug)/")
  let body = {name: $name, scopes: $scopes, author: $author, events: $events, schema: $schema, webhookUrl: $webhookUrl, redirectUrl: $redirectUrl, isInternal: $isInternal, isAlertable: $isAlertable, overview: $overview, verifyInstall: $verifyInstall, allowedOrigins: $allowedOrigins} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom integration.
#
# DELETE /api/0/sentry-apps/{sentry_app_id_or_slug}/
# operationId: Delete a custom integration.
export def "0-sentry-apps Delete-a-custom-integration" [
  sentry_app_id_or_slug: string
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
  let full_url = (build-url $base $"/api/0/sentry-apps/($sentry_app_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return details on an individual team.
#
# GET /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/
# operationId: Retrieve a Team
export def "0-teams Retrieve-a-Team" [
  organization_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: string #  List of strings to opt in to additional data. Supports `projects`, `externalTeams`.
  --collapse: string #  List of strings to opt out of certain pieces of data. Supports `organization`.
]: nothing -> record<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list<string>, hasAccess: bool, isPending: bool, memberCount: int, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, externalTeams: table<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string>, organization: record<features: list<string>, extraOptions: record, access: list<string>, onboardingTasks: list<record>, id: string, slug: string, status: record<id: string, name: string>, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, links: record<organizationUrl: string, regionUrl: string>, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool>, projects: table<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list, firstEvent: string, firstTransactionEvent: bool, access: list, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record, color: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "collapse" $collapse "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update various attributes and configurable settings for the given team.
#
# PUT /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/
# operationId: Update a Team
export def "0-teams Update-a-Team" [
  organization_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  slug: string # Uniquely identifies a team. This is must be available.
]: any -> record<id: string, slug: string, name: string, dateCreated: string, isMember: bool, teamRole: string, flags: record, access: list<string>, hasAccess: bool, isPending: bool, memberCount: int, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, externalTeams: table<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string>, organization: record<features: list<string>, extraOptions: record, access: list<string>, onboardingTasks: list<record>, id: string, slug: string, status: record<id: string, name: string>, name: string, dateCreated: string, isEarlyAdopter: bool, require2FA: bool, avatar: record<avatarType: string, avatarUuid: string, avatarUrl: string>, links: record<organizationUrl: string, regionUrl: string>, hasAuthProvider: bool, allowMemberInvite: bool, allowMemberProjectCreation: bool, allowSuperuserAccess: bool>, projects: table<stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list, firstEvent: string, firstTransactionEvent: bool, access: list, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, isInternal: bool, isPublic: bool, avatar: record, color: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/")
  let body = {slug: $slug} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Schedules a team for deletion.  **Note:** Deletion happens asynchronously and therefore is not immediate. Teams will have their slug released while waiting for deletion.
#
# DELETE /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/
# operationId: Delete a Team
export def "0-teams Delete-a-Team" [
  organization_id_or_slug: string
  team_id_or_slug: string
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
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link a team from an external provider to a Sentry team.
#
# POST /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/external-teams/
# operationId: Create an External Team
export def "0-teams-external-teams Create-an-External-Team" [
  organization_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_name: string # The associated name for the provider.
  provider: string@provider-completer # The provider of the external actor.  * `github` * `github_enterprise` * `jira_server` * `slack` * `slack_staging` * `perforce` * `gitlab` * `msteams` * `custom_scm`
  integration_id: int # The Integration ID.
  --external-id: string # The associated user ID for provider. (nullable)
]: any -> record<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/external-teams/")
  let body = {external_name: $external_name, provider: $provider, integration_id: $integration_id, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a team in an external provider that is currently linked to a Sentry team.
#
# PUT /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/external-teams/{external_team_id}/
# operationId: Update an External Team
export def "0-teams-external-teams Update-an-External-Team" [
  organization_id_or_slug: string
  team_id_or_slug: string
  external_team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_name: string # The associated name for the provider.
  provider: string@provider-completer # The provider of the external actor.  * `github` * `github_enterprise` * `jira_server` * `slack` * `slack_staging` * `perforce` * `gitlab` * `msteams` * `custom_scm`
  integration_id: int # The Integration ID.
  --external-id: string # The associated user ID for provider. (nullable)
]: any -> record<externalId: string, userId: string, teamId: string, id: string, provider: string, externalName: string, integrationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/external-teams/($external_team_id)/")
  let body = {external_name: $external_name, provider: $provider, integration_id: $integration_id, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete the link between a team from an external provider and a Sentry team.
#
# DELETE /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/external-teams/{external_team_id}/
# operationId: Delete an External Team
export def "0-teams-external-teams Delete-an-External-Team" [
  organization_id_or_slug: string
  team_id_or_slug: string
  external_team_id: int
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
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/external-teams/($external_team_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all members on a team.  The response will not include members with pending invites.
#
# GET /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/members/
# operationId: List a Team's Members
export def "0-teams-members List-a-Teams-Members" [
  organization_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<externalUsers: list<record>, role: string, roleName: string, id: string, email: string, name: string, user: record<identities: list, avatar: record, authenticators: list, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list>, orgRole: string, pending: bool, expired: bool, flags: record<idp_provisioned: bool, idp_role_restricted: bool, sso_linked: bool, sso_invalid: bool, member_limit_restricted: bool, partnership_restricted: bool>, dateCreated: string, inviteStatus: string, inviterName: string, teamRole: string, teamSlug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/members/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of projects bound to a team.
#
# GET /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/projects/
# operationId: List a Team's Projects
export def "0-teams-projects List-a-Teams-Projects" [
  organization_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<latestDeploys: record, options: record, stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, team: record<id: string, name: string, slug: string>, teams: list<record>, platforms: list<string>, hasUserReports: bool, environments: list<string>, latestRelease: record<version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/projects/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new project bound to a team.          Note: If your organization has disabled member project creation, the `org:write` or `team:admin` scope is required.         
#
# POST /api/0/teams/{organization_id_or_slug}/{team_id_or_slug}/projects/
# operationId: Create a New Project
export def "0-teams-projects Create-a-New-Project" [
  organization_id_or_slug: string
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The name for the project.
  --slug: string # Uniquely identifies a project and is used for the interface.         If not provided, it is automatically generated from the name. (nullable)
  --platform: string # The platform for the project. (nullable)
  --default-rules: string@bool-completer #  Defaults to true where the behavior is to alert the user on every new issue. Setting this to false will turn this off and the user must create their own alerts to be notified of new issues.         
]: any -> record<latestDeploys: record, options: record, stats: any, transactionStats: any, sessionStats: any, id: string, slug: string, name: string, platform: string, dateCreated: string, isBookmarked: bool, isMember: bool, features: list<string>, firstEvent: string, firstTransactionEvent: bool, access: list<string>, hasAccess: bool, hasFeedbacks: bool, hasFlags: bool, hasMinifiedStackTrace: bool, hasMonitors: bool, hasNewFeedbacks: bool, hasProfiles: bool, hasReplays: bool, hasSessions: bool, hasInsightsHttp: bool, hasInsightsDb: bool, hasInsightsAssets: bool, hasInsightsAppStart: bool, hasInsightsScreenLoad: bool, hasInsightsVitals: bool, hasInsightsCaches: bool, hasInsightsQueues: bool, hasInsightsAgentMonitoring: bool, hasInsightsMCP: bool, hasLogs: bool, hasTraceMetrics: bool, team: record<id: string, name: string, slug: string>, teams: table<id: string, name: string, slug: string>, platforms: list<string>, hasUserReports: bool, environments: list<string>, latestRelease: record<version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/teams/($organization_id_or_slug)/($team_id_or_slug)/projects/")
  let body = {name: $name, slug: $slug, platform: $platform, default_rules: $default_rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of values associated with this key.  The `query` parameter can be used to to perform a "contains" match on values.   When [paginated](/api/pagination) can return at most 1000 values.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/tags/{key}/values/
# operationId: List a Tag's Values
export def "0-projects-tags-values List-a-Tags-Values" [
  organization_id_or_slug: string
  project_id_or_slug: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/tags/($key)/values/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of user feedback items within this project.  *This list does not include submissions from the [User Feedback Widget](https://docs.sentry.io/product/user-feedback/#user-feedback-widget). This is because it is based on an older format called User Reports - read more [here](https://develop.sentry.dev/application/feedback-architecture/#user-reports). To return a list of user feedback items from the widget, please use the [issue API](https://docs.sentry.io/api/events/list-a-projects-issues/) with the filter `issue.category:feedback`.*
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/user-feedback/
# operationId: List a Project's User Feedback
export def "0-projects-user-feedback List-a-Projects-User-Feedback" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<comments: string, dateCreated: string, email: string, event: record<eventID: string, id: string>, eventID: string, id: string, issue: record, name: string, user: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/user-feedback/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# *This endpoint is DEPRECATED. We document it here for older SDKs and users who are still migrating to the [User Feedback Widget](https://docs.sentry.io/product/user-feedback/#user-feedback-widget) or [API](https://docs.sentry.io/platforms/javascript/user-feedback/#user-feedback-api)(multi-platform). If you are a new user, do not use this endpoint - unless you don't have a JS frontend, and your platform's SDK does not offer a feedback API.*  Feedback must be received by the server no more than 30 minutes after the event was saved.  Additionally, within 5 minutes of submitting feedback it may also be overwritten. This is useful in situations where you may need to retry sending a request due to network failures.  If feedback is rejected due to a mutability threshold, a 409 status code will be returned.  Note: Feedback may be submitted with DSN authentication (see auth documentation).
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/user-feedback/
# operationId: Submit User Feedback
export def "0-projects-user-feedback Submit-User-Feedback" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  event_id: string # The event ID. This can be retrieved from the [beforeSend callback](https://docs.sentry.io/platforms/javascript/configuration/filtering/#using-beforesend).
  name: string # User's name.
  email: string # User's email address.
  comments: string # Comments supplied by user.
]: any -> record<comments: string, dateCreated: string, email: string, event: record<eventID: string, id: string>, eventID: string, id: string, issue: record, name: string, user: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/user-feedback/")
  let body = {event_id: $event_id, name: $name, email: $email, comments: $comments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of service hooks bound to a project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/hooks/
# operationId: List a Project's Service Hooks
export def "0-projects-hooks List-a-Projects-Service-Hooks" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<dateCreated: string, events: list<string>, id: string, secret: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/hooks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register a new service hook on a project.  Events include:  - event.alert: An alert is generated for an event (via rules). - event.created: A new event has been processed.  This endpoint requires the 'servicehooks' feature to be enabled for your project.
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/hooks/
# operationId: Register a New Service Hook
export def "0-projects-hooks Register-a-New-Service-Hook" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The URL for the webhook.
  events: list # The events to subscribe to.
]: any -> record<dateCreated: string, events: list<string>, id: string, secret: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/hooks/")
  let body = {url: $body_url, events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a service hook bound to a project.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/hooks/{hook_id}/
# operationId: Retrieve a Service Hook
export def "0-projects-hooks Retrieve-a-Service-Hook" [
  organization_id_or_slug: string
  project_id_or_slug: string
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dateCreated: string, events: list<string>, id: string, secret: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/hooks/($hook_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a service hook.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/hooks/{hook_id}/
# operationId: Update a Service Hook
export def "0-projects-hooks Update-a-Service-Hook" [
  organization_id_or_slug: string
  project_id_or_slug: string
  hook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The URL for the webhook.
  events: list # The events to subscribe to.
]: any -> record<dateCreated: string, events: list<string>, id: string, secret: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/hooks/($hook_id)/")
  let body = {url: $body_url, events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a service hook.
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/hooks/{hook_id}/
# operationId: Remove a Service Hook
export def "0-projects-hooks Remove-a-Service-Hook" [
  organization_id_or_slug: string
  project_id_or_slug: string
  hook_id: string
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
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/hooks/($hook_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# **Deprecated**: This endpoint has been replaced with the [Organization Issues endpoint](/api/events/list-an-organizations-issues/) which supports filtering on project and additional functionality.  Return a list of issues (groups) bound to a project.  All parameters are supplied as query string parameters.    A default query of ``is:unresolved`` is applied. To return results with other statuses send an new query value (i.e. ``?query=`` for all results).  The ``statsPeriod`` parameter can be used to select the timeline stats which should be present. Possible values are: ``""`` (disable),``"24h"`` (default), ``"14d"``  User feedback items from the [User Feedback Widget](https://docs.sentry.io/product/user-feedback/#user-feedback-widget) are built off the issue platform, so to return a list of user feedback items for a specific project, filter for `issue.category:feedback`.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/issues/
# operationId: List a Project's Issues
export def "0-projects-issues List-a-Projects-Issues" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --statsPeriod: string # An optional stat period (can be one of `"24h"`, `"14d"`, and `""`), defaults to "24h" if not provided.
  --shortIdLookup: string@bool-completer # If this is set to true then short IDs are looked up by this function as well. This can cause the return value of the function to return an event issue of a different project which is why this is an opt-in. Set to 1 to enable.
  --qp-query: string # An optional Sentry structured search query. If not provided an implied `"is:unresolved"` is assumed.
  --hashes: string # A list of hashes of groups to return. Is not compatible with 'query' parameter. The maximum number of hashes that can be sent is 100. If more are sent, only the first 100 will be used.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<annotations: list<string>, assignedTo: record, count: string, culprit: string, firstSeen: string, hasSeen: bool, id: string, isBookmarked: bool, isPublic: bool, isSubscribed: bool, lastSeen: string, level: string, logger: string, metadata: any, numComments: int, permalink: string, project: record<id: string, name: string, slug: string>, shareId: string, shortId: string, stats: record<24h: list>, status: string, statusDetails: record, subscriptionDetails: record, title: string, type: string, userCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "shortIdLookup" $shortIdLookup "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "hashes" $hashes "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/issues/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk mutate various attributes on issues.  The list of issues to modify is given through the `id` query parameter.  It is repeated for each issue that should be modified.  - For non-status updates, the `id` query parameter is required. - For status updates, the `id` query parameter may be omitted for a batch "update all" query. - An optional `status` query parameter may be used to restrict mutations to only events with the given status.  The following attributes can be modified and are supplied as JSON object in the body:  If any IDs are out of scope this operation will succeed without any data mutation.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/issues/
# operationId: Bulk Mutate a List of Issues
# --statusDetails shape: {inRelease?: string, inNextRelease?: bool, inCommit?: string, ignoreDuration?: int, ignoreCount?: int, ignoreWindow?: int, ignoreUserCount?: int, ignoreUserWindow?: int}
export def "0-projects-issues Bulk-Mutate-a-List-of-Issues" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # A list of IDs of the issues to be mutated. This parameter shall be repeated for each issue. It is optional only if a status is mutated in which case an implicit update all is assumed.
  --status: string # Optionally limits the query to issues of the specified status. Valid values are `"resolved"`, `"reprocessing"`, `"unresolved"`, and `"ignored"`.
  --status: string # The new status for the issues. Valid values are `"resolved"`, `"resolvedInNextRelease"`, `"unresolved"`, and `"ignored"`.
  --statusDetails: record # Additional details about the resolution. Valid values are `"inRelease"`, `"inNextRelease"`, `"inCommit"`, `"ignoreDuration"`, `"ignoreCount"`, `"ignoreWindow"`, `"ignoreUserCount"`, and `"ignoreUserWindow"`. — shape: {inRelease?: string, inNextRelease?: bool, inCommit?: string, ignoreDuration?: int, ignoreCount?: int, ignoreWindow?: int, ignoreUserCount?: int, ignoreUserWindow?: int}
  --ignoreDuration: int # The number of minutes to ignore this issue.
  --isPublic: string@bool-completer # Sets the issue to public or private.
  --merge: string@bool-completer # Allows to merge or unmerge different issues.
  --assignedTo: string # The actor ID (or username) of the user or team that should be assigned to this issue.
  --hasSeen: string@bool-completer # In case this API call is invoked with a user context this allows changing of the flag that indicates if the user has seen the event.
  --isBookmarked: string@bool-completer # In case this API call is invoked with a user context this allows changing of the bookmark flag.
]: any -> record<isPublic: bool, status: string, statusDetails: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/issues/" $qp)
  let body = {status: $status, statusDetails: $statusDetails, ignoreDuration: $ignoreDuration, isPublic: $isPublic, merge: $merge, assignedTo: $assignedTo, hasSeen: $hasSeen, isBookmarked: $isBookmarked} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Permanently remove the given issues. The list of issues to modify is given through the `id` query parameter.  It is repeated for each issue that should be removed.  Only queries by 'id' are accepted.  If any IDs are out of scope this operation will succeed without any data mutation.
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/issues/
# operationId: Bulk Remove a List of Issues
export def "0-projects-issues Bulk-Remove-a-List-of-Issues" [
  organization_id_or_slug: string
  project_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # A list of IDs of the issues to be removed. This parameter shall be repeated for each issue, e.g. `?id=1&id=2&id=3`. If this parameter is not provided, it will attempt to remove the first 1000 issues.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/issues/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of values associated with this key for an issue. Returns at most 1000 values when paginated.
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/tags/{key}/values/
# operationId: List a Tag's Values for an Issue
export def "0-organizations-issues-tags-values List-a-Tags-Values-for-an-Issue" [
  issue_id: string
  organization_id_or_slug: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer-2 # Sort order of the resulting tag values. Prefix with '-' for descending order. Default is '-id'.
  --environment: list # The name of environments to filter by.
]: nothing -> table<query: string, key: string, name: string, value: string, count: int, lastSeen: string, firstSeen: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "environment" $environment "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/tags/($key)/values/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of releases for a given organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/releases/
# operationId: List an Organization's Releases
export def "0-organizations-releases List-an-Organizations-Releases" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # This parameter can be used to create a "starts with" filter for the version.
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: int, authors: list<record>, commitCount: int, data: record, dateCreated: string, dateReleased: string, deployCount: int, firstEvent: string, lastCommit: record, lastDeploy: record, lastEvent: string, newGroups: int, owner: record, projects: list<record>, ref: string, shortVersion: string, version: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new release for the given organization.  Releases are used by Sentry to improve its error reporting abilities by correlating first seen events with the release that might have introduced the problem. Releases are also necessary for source maps and other debug features that require manual upload for functioning well.
#
# POST /api/0/organizations/{organization_id_or_slug}/releases/
# operationId: Create a New Release for an Organization
# --commits item shape: {patch_set?: list, repository?: string, author_name?: string, author_email?: string, timestamp?: string, message?: string, id?: string}
# --refs item shape: {repository?: string, commit?: string, previousCommit?: string}
export def "0-organizations-releases Create-a-New-Release-for-an-Organization" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  version: string # A version identifier for this release. Can be a version number, a commit hash, etc.
  projects: list # A list of project slugs that are involved in this release.
  --ref: string # An optional commit reference. This is useful if a tagged version has been provided.
  --body-url: string # A URL that points to the release. This can be the path to an online interface to the source code for instance
  --dateReleased: string # An optional date that indicates when the release went live. If not provided the current time is assumed. (format: date-time)
  --commits: list # An optional list of commit data to be associated with the release. Commits must include parameters `id` (the SHA of the commit), and can optionally include `repository`, `message`, `patch_set`, `author_name`, `author_email`, and `timestamp`. — item shape: {patch_set?: list, repository?: string, author_name?: string, author_email?: string, timestamp?: string, message?: string, id?: string}
  --refs: list # An optional way to indicate the start and end commits for each repository included in a release. Head commits must include parameters `repository` and `commit` (the HEAD sha). They can optionally include `previousCommit` (the sha of the HEAD of the previous release), which should be specified if this is the first time you've sent commit data. `commit` may contain a range in the form of `previousCommit..commit`. — item shape: {repository?: string, commit?: string, previousCommit?: string}
]: any -> record<id: int, authors: list<record>, commitCount: int, data: record, dateCreated: string, dateReleased: string, deployCount: int, firstEvent: string, lastCommit: record, lastDeploy: record, lastEvent: string, newGroups: int, owner: record, projects: table<name: string, slug: string>, ref: string, shortVersion: string, version: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/")
  let body = {version: $version, projects: $projects, ref: $ref, url: $body_url, dateReleased: $dateReleased, commits: $commits, refs: $refs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of files for a given release.
#
# GET /api/0/organizations/{organization_id_or_slug}/releases/{version}/files/
# operationId: List an Organization's Release Files
export def "0-organizations-releases-files List-an-Organizations-Release-Files" [
  organization_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<sha1: string, dist: string, name: string, dateCreated: string, headers: record<Content_Type: string>, id: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/files/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a new file for the given release.  Unlike other API requests, files must be uploaded using the traditional multipart/form-data content-type.  Requests to this endpoint should use the region-specific domain eg. `us.sentry.io` or `de.sentry.io`.  The optional 'name' attribute should reflect the absolute path that this file will be referenced as. For example, in the case of JavaScript you might specify the full web URI.
#
# POST /api/0/organizations/{organization_id_or_slug}/releases/{version}/files/
# operationId: Upload a New Organization Release File
export def "0-organizations-releases-files Upload-a-New-Organization-Release-File" [
  organization_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The multipart encoded file. (format: binary)
  --name: string # The name (full path) of the file.
  --dist: string # The name of the dist.
  --header: string # This parameter can be supplied multiple times to attach headers to the file. Each header is a string in the format `key:value`. For instance it can be used to define a content type.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{region}.sentry.io")
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/files/")
  let body = {file: $file, name: $name, dist: $dist, header: $header} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Return a list of files for a given release.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/releases/{version}/files/
# operationId: List a Project's Release Files
export def "0-projects-releases-files List-a-Projects-Release-Files" [
  organization_id_or_slug: string
  project_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<sha1: string, dist: string, name: string, dateCreated: string, headers: record<Content_Type: string>, id: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/releases/($version)/files/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload a new file for the given release.  Unlike other API requests, files must be uploaded using the traditional multipart/form-data content-type.  Requests to this endpoint should use the region-specific domain eg. `us.sentry.io` or `de.sentry.io`  The optional 'name' attribute should reflect the absolute path that this file will be referenced as. For example, in the case of JavaScript you might specify the full web URI.
#
# POST /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/releases/{version}/files/
# operationId: Upload a New Project Release File
export def "0-projects-releases-files Upload-a-New-Project-Release-File" [
  organization_id_or_slug: string
  project_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The multipart encoded file. (format: binary)
  --name: string # The name (full path) of the file.
  --dist: string # The name of the dist.
  --header: string # This parameter can be supplied multiple times to attach headers to the file. Each header is a string in the format `key:value`. For instance it can be used to define a content type.
]: any -> record<sha1: string, dist: string, name: string, dateCreated: string, headers: record<Content_Type: string>, id: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://{region}.sentry.io")
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/releases/($version)/files/")
  let body = {file: $file, name: $name, dist: $dist, header: $header} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve a file for a given release.
#
# GET /api/0/organizations/{organization_id_or_slug}/releases/{version}/files/{file_id}/
# operationId: Retrieve an Organization Release's File
export def "0-organizations-releases-files Retrieve-an-Organization-Releases-File" [
  organization_id_or_slug: string
  version: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --download: string@bool-completer # If this is set to true, then the response payload will be the raw file contents. Otherwise, the response will be the file metadata as JSON.
]: nothing -> record<sha1: string, dist: string, name: string, dateCreated: string, headers: record<Content_Type: string>, id: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/files/($file_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an organization release file.
#
# PUT /api/0/organizations/{organization_id_or_slug}/releases/{version}/files/{file_id}/
# operationId: Update an Organization Release File
export def "0-organizations-releases-files Update-an-Organization-Release-File" [
  organization_id_or_slug: string
  version: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The new name (full path) of the file.
  --dist: string # The new name of the dist.
]: any -> record<sha1: string, dist: string, name: string, dateCreated: string, headers: record<Content_Type: string>, id: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/files/($file_id)/")
  let body = {name: $name, dist: $dist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a file for a given release.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/releases/{version}/files/{file_id}/
# operationId: Delete an Organization Release's File
export def "0-organizations-releases-files Delete-an-Organization-Releases-File" [
  organization_id_or_slug: string
  version: string
  file_id: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/files/($file_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a file for a given release.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/releases/{version}/files/{file_id}/
# operationId: Retrieve a Project Release's File
export def "0-projects-releases-files Retrieve-a-Project-Releases-File" [
  organization_id_or_slug: string
  project_id_or_slug: string
  version: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --download: string@bool-completer # If this is set to true, then the response payload will be the raw file contents. Otherwise, the response will be the file metadata as JSON.
]: nothing -> record<sha1: string, dist: string, name: string, dateCreated: string, headers: record<Content_Type: string>, id: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "download" $download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/releases/($version)/files/($file_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a project release file.
#
# PUT /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/releases/{version}/files/{file_id}/
# operationId: Update a Project Release File
export def "0-projects-releases-files Update-a-Project-Release-File" [
  organization_id_or_slug: string
  project_id_or_slug: string
  version: string
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The new name (full path) of the file.
  --dist: string # The new name of the dist.
]: any -> record<sha1: string, dist: string, name: string, dateCreated: string, headers: record<Content_Type: string>, id: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/releases/($version)/files/($file_id)/")
  let body = {name: $name, dist: $dist} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a file for a given release.
#
# DELETE /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/releases/{version}/files/{file_id}/
# operationId: Delete a Project Release's File
export def "0-projects-releases-files Delete-a-Project-Releases-File" [
  organization_id_or_slug: string
  project_id_or_slug: string
  version: string
  file_id: string
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
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/releases/($version)/files/($file_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an organization release's commits.
#
# GET /api/0/organizations/{organization_id_or_slug}/releases/{version}/commits/
# operationId: List an Organization Release's Commits
export def "0-organizations-releases-commits List-an-Organization-Releases-Commits" [
  organization_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<dateCreated: string, id: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/commits/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List a project release's commits.
#
# GET /api/0/projects/{organization_id_or_slug}/{project_id_or_slug}/releases/{version}/commits/
# operationId: List a Project Release's Commits
export def "0-projects-releases-commits List-a-Project-Releases-Commits" [
  organization_id_or_slug: string
  project_id_or_slug: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<dateCreated: string, id: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/projects/($organization_id_or_slug)/($project_id_or_slug)/releases/($version)/commits/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve files changed in a release's commits
#
# GET /api/0/organizations/{organization_id_or_slug}/releases/{version}/commitfiles/
# operationId: Retrieve Files Changed in a Release's Commits
export def "0-organizations-releases-commitfiles Retrieve-Files-Changed-in-a-Releases-Commits" [
  organization_id_or_slug: string
  version: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/releases/($version)/commitfiles/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of integration platform installations for a given organization.
#
# GET /api/0/organizations/{organization_id_or_slug}/sentry-app-installations/
# operationId: List an Organization's Integration Platform Installations
export def "0-organizations-sentry-app-installations List-an-Organizations-Integration-Platform-Installations" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<app: record<uuid: string, slug: string, sentryAppId: int>, organization: record<slug: string>, uuid: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/sentry-app-installations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update an external issue from an integration platform integration.
#
# POST /api/0/sentry-app-installations/{uuid}/external-issues/
# operationId: Create or update an External Issue
export def "0-sentry-app-installations-external-issues Create-or-update-an-External-Issue" [
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  issueId: int # The ID of the Sentry issue to link the external issue to.
  webUrl: string # The URL of the external service to link the issue to.
  project: string # The external service's project.
  identifier: string # A unique identifier of the external issue.
]: any -> record<id: string, issueId: string, serviceType: string, displayName: string, webUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/sentry-app-installations/($uuid)/external-issues/")
  let body = {issueId: $issueId, webUrl: $webUrl, project: $project, identifier: $identifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an external issue.
#
# DELETE /api/0/sentry-app-installations/{uuid}/external-issues/{external_issue_id}/
# operationId: Delete an External Issue
export def "0-sentry-app-installations-external-issues Delete-an-External-Issue" [
  uuid: string
  external_issue_id: string
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
  let full_url = (build-url $base $"/api/0/sentry-app-installations/($uuid)/external-issues/($external_issue_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Enables Spike Protection feature for some of the projects within the organization.
#
# POST /api/0/organizations/{organization_id_or_slug}/spike-protections/
# operationId: Enable Spike Protection
export def "0-organizations-spike-protections Enable-Spike-Protection" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  projects: list # Slugs of projects to enable Spike Protection for. Set to `$all` to enable Spike Protection for all the projects in the organization.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/spike-protections/")
  let body = {projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disables Spike Protection feature for some of the projects within the organization.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/spike-protections/
# operationId: Disable Spike Protection
export def "0-organizations-spike-protections Disable-Spike-Protection" [
  organization_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  projects: list # Slugs of projects to disable Spike Protection for. Set to `$all` to disable Spike Protection for all the projects in the organization.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/spike-protections/")
  let body = {projects: $projects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return details on an individual issue, including its basic stats, comment and user-report counts, and a summary of the latest event.
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/
# operationId: Retrieve an Issue
export def "0-organizations-issues Retrieve-an-Issue" [
  organization_id_or_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
  --expand: list # Additional data to include in the response.
  --collapse: list # Fields to remove from the response to improve query performance.
]: nothing -> record<isUnhandled: bool, count: string, userCount: int, firstSeen: string, lastSeen: string, id: string, shareId: string, shortId: string, title: string, culprit: string, permalink: string, logger: string, level: string, status: string, statusDetails: record<autoResolved: bool, ignoreCount: int, ignoreUntil: string, ignoreUserCount: int, ignoreUserWindow: int, ignoreWindow: int, actor: record<identities: list, avatar: record, authenticators: list, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list>, inNextRelease: bool, inRelease: string, inCommit: string, pendingEvents: int, info: any>, substatus: string, isPublic: bool, platform: string, priority: string, priorityLockedAt: string, seerFixabilityScore: float, seerAutofixLastTriggered: string, seerExplorerAutofixLastTriggered: string, project: record<id: string, name: string, slug: string, platform: string>, type: string, issueType: string, issueCategory: string, metadata: record, numComments: int, assignedTo: record<type: string, id: string, name: string, email: string>, isBookmarked: bool, isSubscribed: bool, subscriptionDetails: record<disabled: bool, reason: string>, hasSeen: bool, annotations: table<displayName: string, url: string>, firstRelease: record, lastRelease: record, tags: list<record>, stats: record, inbox: record<reason: int, reason_details: record<until: string, count: int, window: int, user_count: int, user_window: int>, date_added: string>, owners: table<type: string, owner: string, date_added: string>, forecast: record, integrationIssues: list<record>, sentryAppIssues: table<id: string, issueId: string, serviceType: string, displayName: string, webUrl: string>, latestEventHasAttachments: bool, activity: list<record>, seenBy: list<record>, pluginActions: list<any>, pluginIssues: list<record>, pluginContexts: list<record>, userReportCount: int, participants: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi") (serialize-qp "expand" $expand "multi") (serialize-qp "collapse" $collapse "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an individual issue's attributes. Only the attributes submitted are modified.
#
# PUT /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/
# operationId: Update an Issue
export def "0-organizations-issues Update-an-Issue" [
  organization_id_or_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inbox: string@bool-completer # If true, marks the issue as reviewed by the requestor.
  status: string@status-completer # Limit mutations to only issues with the given status.  * `resolved` * `unresolved` * `ignored` * `resolvedInNextRelease` * `muted`
  statusDetails: any # Additional details about the resolution. Status detail updates that include release data are only allowed for issues within a single project.
  --substatus: string@substatus-completer # The new substatus of the issue.  * `archived_until_escalating` * `archived_until_condition_met` * `archived_forever` * `escalating` * `ongoing` * `regressed` * `new` (nullable)
  --hasSeen: string@bool-completer # If true, marks the issue as seen by the requestor.
  --isBookmarked: string@bool-completer # If true, bookmarks the issue for the requestor.
  --isPublic: string@bool-completer # If true, publishes the issue.
  --isSubscribed: string@bool-completer # If true, subscribes the requestor to the issue.
  --merge: string@bool-completer # If true, merges the issues together.
  --discard: string@bool-completer # If true, discards the issues instead of updating them.
  assignedTo: string # The user or team that should be assigned to the issues. Values take the form of `<user_id>`, `user:<user_id>`, `<username>`, `<user_primary_email>`, or `team:<team_id>`.
  priority: string@priority-completer # The priority that should be set for the issues  * `low` * `medium` * `high`
]: any -> record<isUnhandled: bool, count: string, userCount: int, firstSeen: string, lastSeen: string, id: string, shareId: string, shortId: string, title: string, culprit: string, permalink: string, logger: string, level: string, status: string, statusDetails: record<autoResolved: bool, ignoreCount: int, ignoreUntil: string, ignoreUserCount: int, ignoreUserWindow: int, ignoreWindow: int, actor: record<identities: list, avatar: record, authenticators: list, canReset2fa: bool, id: string, name: string, username: string, email: string, avatarUrl: string, isActive: bool, isSuspended: bool, hasPasswordAuth: bool, isManaged: bool, dateJoined: string, lastLogin: string, has2fa: bool, lastActive: string, isSuperuser: bool, isStaff: bool, experiments: record, emails: list>, inNextRelease: bool, inRelease: string, inCommit: string, pendingEvents: int, info: any>, substatus: string, isPublic: bool, platform: string, priority: string, priorityLockedAt: string, seerFixabilityScore: float, seerAutofixLastTriggered: string, seerExplorerAutofixLastTriggered: string, project: record<id: string, name: string, slug: string, platform: string>, type: string, issueType: string, issueCategory: string, metadata: record, numComments: int, assignedTo: record<type: string, id: string, name: string, email: string>, isBookmarked: bool, isSubscribed: bool, subscriptionDetails: record<disabled: bool, reason: string>, hasSeen: bool, annotations: table<displayName: string, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/")
  let body = {inbox: $inbox, status: $status, statusDetails: $statusDetails, substatus: $substatus, hasSeen: $hasSeen, isBookmarked: $isBookmarked, isPublic: $isPublic, isSubscribed: $isSubscribed, merge: $merge, discard: $discard, assignedTo: $assignedTo, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Asynchronously queue an individual issue for deletion.
#
# DELETE /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/
# operationId: Remove an Issue
export def "0-organizations-issues Remove-an-Issue" [
  organization_id_or_slug: string
  issue_id: string
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
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve the current detailed state of an issue fix process for a specific issue including:  - Current status - Steps performed and their outcomes - Repository information and permissions - Root Cause Analysis - Proposed Solution - Generated code changes  This endpoint although documented is still experimental and the payload may change in the future.
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/autofix/
# operationId: Retrieve Seer Issue Fix State
export def "0-organizations-issues-autofix Retrieve-Seer-Issue-Fix-State" [
  organization_id_or_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<autofix: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/autofix/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a Seer Issue Fix run for a specific issue.  The issue fix process can: - Identify the root cause of the issue - Propose a solution - Generate code changes - Create a pull request with the fix  The process runs asynchronously, and you can get the state using the GET endpoint.
#
# POST /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/autofix/
# operationId: Start Seer Issue Fix
export def "0-organizations-issues-autofix Start-Seer-Issue-Fix" [
  organization_id_or_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --step: string@step-completer # Which autofix step to run.  * `root_cause` * `solution` * `code_changes` * `open_pr` * `coding_agent_handoff` (default: root_cause)
  --stopping-point: string@stopping-point-completer # Where the issue fix process should stop. If not provided, will run to root cause.  * `root_cause` * `solution` * `code_changes` * `open_pr`
  --run-id: int # Existing run ID to continue. If not provided, starts a new run.
  --integration-id: int # Coding agent integration ID. Required for coding_agent_handoff step (unless provider is specified).
  --provider: string # Coding agent provider (e.g., 'github_copilot'). Alternative to integration_id for user-authenticated providers.
  --user-context: string # Optional user context to append to the step prompt.
  --repo-name: string # Optional repository name for which to create the pull request. Do not pass a repository name to create pull requests in all relevant repositories.
  --insert-index: int # Block index to insert at. When provided, truncates blocks after this point for retry-from-step.
  --referrer: string # Referrer identifying where the issue fix was triggered from.
]: any -> record<run_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/autofix/")
  let body = {step: $step, stopping_point: $stopping_point, run_id: $run_id, integration_id: $integration_id, provider: $provider, user_context: $user_context, repo_name: $repo_name, insert_index: $insert_index, referrer: $referrer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of error events bound to an issue
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/events/
# operationId: List an Issue's Events
export def "0-organizations-issues-events List-an-Issues-Events" [
  organization_id_or_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # The start of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --end: string # The end of the period of time for the query, expected in ISO-8601 format. For example, `2001-12-14T12:34:56.7890`. (format: date-time)
  --statsPeriod: string # The period of time for the query, will override the start & end parameters, a number followed by one of: - `d` for days - `h` for hours - `m` for minutes - `s` for seconds - `w` for weeks  For example, `24h`, to mean query data starting from 24 hours ago to now.
  --environment: list # The name of environments to filter by.
  --full: string@bool-completer # Specify true to include the full event body, including the stacktrace, in the event payload. (default: false)
  --sample: string@bool-completer # Return events in pseudo-random order. This is deterministic so an identical query will always return the same events in the same order. (default: false)
  --qp-query: string # An optional search query for filtering events. See [search syntax](https://docs.sentry.io/concepts/search/) and queryable event properties at [Sentry Search Documentation](https://docs.sentry.io/concepts/search/searchable-properties/events/) for more information. An example query might be `query=transaction:foo AND release:abc`
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, event_type: string, groupID: string, eventID: string, projectID: string, message: string, title: string, location: string, culprit: string, user: record<id: string, email: string, username: string, ip_address: string, name: string, geo: record, data: record>, tags: list<record>, platform: string, dateCreated: string, crashFile: string, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "statsPeriod" $statsPeriod "scalar") (serialize-qp "environment" $environment "multi") (serialize-qp "full" $full "scalar") (serialize-qp "sample" $sample "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/events/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the details of an issue event.
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/events/{event_id}/
# operationId: Retrieve an Issue Event
export def "0-organizations-issues-events Retrieve-an-Issue-Event" [
  organization_id_or_slug: string
  issue_id: string
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
]: nothing -> record<id: string, groupID: string, eventID: string, projectID: string, message: string, title: string, location: string, user: record<id: string, email: string, username: string, ip_address: string, name: string, geo: record, data: record>, tags: table<query: string, key: string, value: string>, platform: string, dateReceived: string, contexts: record, size: int, entries: list<any>, dist: string, sdk: record, context: record, packages: record, type: string, metadata: any, errors: list<any>, occurrence: any, _meta: record, crashFile: string, culprit: string, dateCreated: string, fingerprints: list<string>, groupingConfig: any, startTimestamp: string, endTimestamp: string, measurements: any, breakdowns: any, release: record<id: int, commitCount: int, data: record, dateCreated: string, dateReleased: string, deployCount: int, ref: string, lastCommit: record, lastDeploy: record<dateStarted: string, url: string, id: string, environment: string, dateFinished: string, name: string>, status: string, url: string, userAgent: string, version: string, versionInfo: record<description: string, package: string, version: record, buildHash: string>>, userReport: record<id: string, eventID: string, name: string, email: string, comments: string, dateCreated: string, user: record<id: string, username: string, email: string, name: string, ipAddress: string, avatarUrl: string>, event: record<id: string, eventID: string>>, sdkUpdates: list<record>, resolvedWith: list<string>, nextEventID: string, previousEventID: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/events/($event_id)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve custom integration issue links for the given Sentry issue
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/external-issues/
# operationId: Retrieve custom integration issue links for the given Sentry issue
export def "0-organizations-issues-external-issues Retrieve-custom-integration-issue-links-for-the-given-Sentry-issue" [
  organization_id_or_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, issueId: string, serviceType: string, displayName: string, webUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/external-issues/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List the hashes that make up an issue. Each hash represents a grouping signature used to aggregate individual events into this issue.
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/hashes/
# operationId: List an Issue's Hashes
export def "0-organizations-issues-hashes List-an-Issues-Hashes" [
  organization_id_or_slug: string
  issue_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full: string@bool-completer # Specify true to include the full event body, including the stacktrace, in the event payload. (default: true)
  --cursor: string # A pointer to the last object fetched and its sort order; used to retrieve the next or previous results.
]: nothing -> table<id: string, latestEvent: any, mergedBySeer: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "full" $full "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/hashes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a list of values associated with this key for an issue. When paginated can return at most 1000 values.
#
# GET /api/0/organizations/{organization_id_or_slug}/issues/{issue_id}/tags/{key}/
# operationId: Retrieve Tag Details
export def "0-organizations-issues-tags Retrieve-Tag-Details" [
  issue_id: string
  organization_id_or_slug: string
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environment: list # The name of environments to filter by.
]: nothing -> record<uniqueValues: int, totalValues: int, topValues: table<query: string, key: string, name: string, value: string, count: int, lastSeen: string, firstSeen: string>, key: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environment" $environment "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/0/organizations/($organization_id_or_slug)/issues/($issue_id)/tags/($key)/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
