# Auto-generated client for Amazon GameLift v2015-10-01
# Source: https://api.apis.guru/v2/specs/amazonaws.com/gamelift/2015-10-01/openapi.json
# Auth: --token flag or $env.AMAZON_GAMELIFT_TOKEN

const BASE_URL = "http://gamelift.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_GAMELIFT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://gamelift.us-east-1.amazonaws.com" "http://gamelift.us-east-2.amazonaws.com" "http://gamelift.us-west-1.amazonaws.com" "http://gamelift.us-west-2.amazonaws.com" "http://gamelift.us-gov-west-1.amazonaws.com" "http://gamelift.us-gov-east-1.amazonaws.com" "http://gamelift.ca-central-1.amazonaws.com" "http://gamelift.eu-north-1.amazonaws.com" "http://gamelift.eu-west-1.amazonaws.com" "http://gamelift.eu-west-2.amazonaws.com" "http://gamelift.eu-west-3.amazonaws.com" "http://gamelift.eu-central-1.amazonaws.com" "http://gamelift.eu-south-1.amazonaws.com" "http://gamelift.af-south-1.amazonaws.com" "http://gamelift.ap-northeast-1.amazonaws.com" "http://gamelift.ap-northeast-2.amazonaws.com" "http://gamelift.ap-northeast-3.amazonaws.com" "http://gamelift.ap-southeast-1.amazonaws.com" "http://gamelift.ap-southeast-2.amazonaws.com" "http://gamelift.ap-east-1.amazonaws.com" "http://gamelift.ap-south-1.amazonaws.com" "http://gamelift.sa-east-1.amazonaws.com" "http://gamelift.me-south-1.amazonaws.com" "https://gamelift.us-east-1.amazonaws.com" "https://gamelift.us-east-2.amazonaws.com" "https://gamelift.us-west-1.amazonaws.com" "https://gamelift.us-west-2.amazonaws.com" "https://gamelift.us-gov-west-1.amazonaws.com" "https://gamelift.us-gov-east-1.amazonaws.com" "https://gamelift.ca-central-1.amazonaws.com" "https://gamelift.eu-north-1.amazonaws.com" "https://gamelift.eu-west-1.amazonaws.com" "https://gamelift.eu-west-2.amazonaws.com" "https://gamelift.eu-west-3.amazonaws.com" "https://gamelift.eu-central-1.amazonaws.com" "https://gamelift.eu-south-1.amazonaws.com" "https://gamelift.af-south-1.amazonaws.com" "https://gamelift.ap-northeast-1.amazonaws.com" "https://gamelift.ap-northeast-2.amazonaws.com" "https://gamelift.ap-northeast-3.amazonaws.com" "https://gamelift.ap-southeast-1.amazonaws.com" "https://gamelift.ap-southeast-2.amazonaws.com" "https://gamelift.ap-east-1.amazonaws.com" "https://gamelift.ap-south-1.amazonaws.com" "https://gamelift.sa-east-1.amazonaws.com" "https://gamelift.me-south-1.amazonaws.com" "http://gamelift.cn-north-1.amazonaws.com.cn" "http://gamelift.cn-northwest-1.amazonaws.com.cn" "https://gamelift.cn-north-1.amazonaws.com.cn" "https://gamelift.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["GameLift.AcceptMatch"] }
def x-amz-target-completer-1 [] { ["GameLift.ClaimGameServer"] }
def x-amz-target-completer-2 [] { ["GameLift.CreateAlias"] }
def x-amz-target-completer-3 [] { ["GameLift.CreateBuild"] }
def x-amz-target-completer-4 [] { ["GameLift.CreateFleet"] }
def x-amz-target-completer-5 [] { ["GameLift.CreateFleetLocations"] }
def x-amz-target-completer-6 [] { ["GameLift.CreateGameServerGroup"] }
def x-amz-target-completer-7 [] { ["GameLift.CreateGameSession"] }
def x-amz-target-completer-8 [] { ["GameLift.CreateGameSessionQueue"] }
def x-amz-target-completer-9 [] { ["GameLift.CreateLocation"] }
def x-amz-target-completer-10 [] { ["GameLift.CreateMatchmakingConfiguration"] }
def x-amz-target-completer-11 [] { ["GameLift.CreateMatchmakingRuleSet"] }
def x-amz-target-completer-12 [] { ["GameLift.CreatePlayerSession"] }
def x-amz-target-completer-13 [] { ["GameLift.CreatePlayerSessions"] }
def x-amz-target-completer-14 [] { ["GameLift.CreateScript"] }
def x-amz-target-completer-15 [] { ["GameLift.CreateVpcPeeringAuthorization"] }
def x-amz-target-completer-16 [] { ["GameLift.CreateVpcPeeringConnection"] }
def x-amz-target-completer-17 [] { ["GameLift.DeleteAlias"] }
def x-amz-target-completer-18 [] { ["GameLift.DeleteBuild"] }
def x-amz-target-completer-19 [] { ["GameLift.DeleteFleet"] }
def x-amz-target-completer-20 [] { ["GameLift.DeleteFleetLocations"] }
def x-amz-target-completer-21 [] { ["GameLift.DeleteGameServerGroup"] }
def x-amz-target-completer-22 [] { ["GameLift.DeleteGameSessionQueue"] }
def x-amz-target-completer-23 [] { ["GameLift.DeleteLocation"] }
def x-amz-target-completer-24 [] { ["GameLift.DeleteMatchmakingConfiguration"] }
def x-amz-target-completer-25 [] { ["GameLift.DeleteMatchmakingRuleSet"] }
def x-amz-target-completer-26 [] { ["GameLift.DeleteScalingPolicy"] }
def x-amz-target-completer-27 [] { ["GameLift.DeleteScript"] }
def x-amz-target-completer-28 [] { ["GameLift.DeleteVpcPeeringAuthorization"] }
def x-amz-target-completer-29 [] { ["GameLift.DeleteVpcPeeringConnection"] }
def x-amz-target-completer-30 [] { ["GameLift.DeregisterCompute"] }
def x-amz-target-completer-31 [] { ["GameLift.DeregisterGameServer"] }
def x-amz-target-completer-32 [] { ["GameLift.DescribeAlias"] }
def x-amz-target-completer-33 [] { ["GameLift.DescribeBuild"] }
def x-amz-target-completer-34 [] { ["GameLift.DescribeCompute"] }
def x-amz-target-completer-35 [] { ["GameLift.DescribeEC2InstanceLimits"] }
def x-amz-target-completer-36 [] { ["GameLift.DescribeFleetAttributes"] }
def x-amz-target-completer-37 [] { ["GameLift.DescribeFleetCapacity"] }
def x-amz-target-completer-38 [] { ["GameLift.DescribeFleetEvents"] }
def x-amz-target-completer-39 [] { ["GameLift.DescribeFleetLocationAttributes"] }
def x-amz-target-completer-40 [] { ["GameLift.DescribeFleetLocationCapacity"] }
def x-amz-target-completer-41 [] { ["GameLift.DescribeFleetLocationUtilization"] }
def x-amz-target-completer-42 [] { ["GameLift.DescribeFleetPortSettings"] }
def x-amz-target-completer-43 [] { ["GameLift.DescribeFleetUtilization"] }
def x-amz-target-completer-44 [] { ["GameLift.DescribeGameServer"] }
def x-amz-target-completer-45 [] { ["GameLift.DescribeGameServerGroup"] }
def x-amz-target-completer-46 [] { ["GameLift.DescribeGameServerInstances"] }
def x-amz-target-completer-47 [] { ["GameLift.DescribeGameSessionDetails"] }
def x-amz-target-completer-48 [] { ["GameLift.DescribeGameSessionPlacement"] }
def x-amz-target-completer-49 [] { ["GameLift.DescribeGameSessionQueues"] }
def x-amz-target-completer-50 [] { ["GameLift.DescribeGameSessions"] }
def x-amz-target-completer-51 [] { ["GameLift.DescribeInstances"] }
def x-amz-target-completer-52 [] { ["GameLift.DescribeMatchmaking"] }
def x-amz-target-completer-53 [] { ["GameLift.DescribeMatchmakingConfigurations"] }
def x-amz-target-completer-54 [] { ["GameLift.DescribeMatchmakingRuleSets"] }
def x-amz-target-completer-55 [] { ["GameLift.DescribePlayerSessions"] }
def x-amz-target-completer-56 [] { ["GameLift.DescribeRuntimeConfiguration"] }
def x-amz-target-completer-57 [] { ["GameLift.DescribeScalingPolicies"] }
def x-amz-target-completer-58 [] { ["GameLift.DescribeScript"] }
def x-amz-target-completer-59 [] { ["GameLift.DescribeVpcPeeringAuthorizations"] }
def x-amz-target-completer-60 [] { ["GameLift.DescribeVpcPeeringConnections"] }
def x-amz-target-completer-61 [] { ["GameLift.GetComputeAccess"] }
def x-amz-target-completer-62 [] { ["GameLift.GetComputeAuthToken"] }
def x-amz-target-completer-63 [] { ["GameLift.GetGameSessionLogUrl"] }
def x-amz-target-completer-64 [] { ["GameLift.GetInstanceAccess"] }
def x-amz-target-completer-65 [] { ["GameLift.ListAliases"] }
def x-amz-target-completer-66 [] { ["GameLift.ListBuilds"] }
def x-amz-target-completer-67 [] { ["GameLift.ListCompute"] }
def x-amz-target-completer-68 [] { ["GameLift.ListFleets"] }
def x-amz-target-completer-69 [] { ["GameLift.ListGameServerGroups"] }
def x-amz-target-completer-70 [] { ["GameLift.ListGameServers"] }
def x-amz-target-completer-71 [] { ["GameLift.ListLocations"] }
def x-amz-target-completer-72 [] { ["GameLift.ListScripts"] }
def x-amz-target-completer-73 [] { ["GameLift.ListTagsForResource"] }
def x-amz-target-completer-74 [] { ["GameLift.PutScalingPolicy"] }
def x-amz-target-completer-75 [] { ["GameLift.RegisterCompute"] }
def x-amz-target-completer-76 [] { ["GameLift.RegisterGameServer"] }
def x-amz-target-completer-77 [] { ["GameLift.RequestUploadCredentials"] }
def x-amz-target-completer-78 [] { ["GameLift.ResolveAlias"] }
def x-amz-target-completer-79 [] { ["GameLift.ResumeGameServerGroup"] }
def x-amz-target-completer-80 [] { ["GameLift.SearchGameSessions"] }
def x-amz-target-completer-81 [] { ["GameLift.StartFleetActions"] }
def x-amz-target-completer-82 [] { ["GameLift.StartGameSessionPlacement"] }
def x-amz-target-completer-83 [] { ["GameLift.StartMatchBackfill"] }
def x-amz-target-completer-84 [] { ["GameLift.StartMatchmaking"] }
def x-amz-target-completer-85 [] { ["GameLift.StopFleetActions"] }
def x-amz-target-completer-86 [] { ["GameLift.StopGameSessionPlacement"] }
def x-amz-target-completer-87 [] { ["GameLift.StopMatchmaking"] }
def x-amz-target-completer-88 [] { ["GameLift.SuspendGameServerGroup"] }
def x-amz-target-completer-89 [] { ["GameLift.TagResource"] }
def x-amz-target-completer-90 [] { ["GameLift.UntagResource"] }
def x-amz-target-completer-91 [] { ["GameLift.UpdateAlias"] }
def x-amz-target-completer-92 [] { ["GameLift.UpdateBuild"] }
def x-amz-target-completer-93 [] { ["GameLift.UpdateFleetAttributes"] }
def x-amz-target-completer-94 [] { ["GameLift.UpdateFleetCapacity"] }
def x-amz-target-completer-95 [] { ["GameLift.UpdateFleetPortSettings"] }
def x-amz-target-completer-96 [] { ["GameLift.UpdateGameServer"] }
def x-amz-target-completer-97 [] { ["GameLift.UpdateGameServerGroup"] }
def x-amz-target-completer-98 [] { ["GameLift.UpdateGameSession"] }
def x-amz-target-completer-99 [] { ["GameLift.UpdateGameSessionQueue"] }
def x-amz-target-completer-100 [] { ["GameLift.UpdateMatchmakingConfiguration"] }
def x-amz-target-completer-101 [] { ["GameLift.UpdateRuntimeConfiguration"] }
def x-amz-target-completer-102 [] { ["GameLift.UpdateScript"] }
def x-amz-target-completer-103 [] { ["GameLift.ValidateMatchmakingRuleSet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api create-accept-match" } } | get name | first)
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

# Registers a player's acceptance or rejection of a proposed FlexMatch match. A matchmaking configuration may require player acceptance; if so, then matches built with that configuration cannot be completed unless all players accept the proposed match within a specified time limit. When FlexMatch builds a match, all the matchmaking tickets involved in the proposed match are placed into status REQUIRES_ACCEPTANCE. This is a trigger for your game to get acceptance from all players in the ticket. Acceptances are only valid for tickets when they are in this status; all other acceptances result in an error. To register acceptance, specify the ticket ID, a response, and one or more players. Once all players have registered acceptance, the matchmaking tickets advance to status PLACING, where a new game session is created for the match. If any player rejects the match, or if acceptances are not received before a specified timeout, the proposed match is dropped. The matchmaking tickets are then handled in one of two ways: For tickets where one or more players rejected the match or failed to respond, the ticket status is set to CANCELLED, and processing is terminated. For tickets where players have accepted or not yet responded, the ticket status is returned to SEARCHING to find a new match. A new matchmaking request for these players can be submitted as needed. Learn more Add FlexMatch to a game client (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-client.html) FlexMatch events (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-events.html) (reference)
#
# POST /
# operationId: AcceptMatch
export def "api create-accept-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer
  ticket_id: any
  player_ids: any
  acceptance_type: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketId": $ticket_id, "PlayerIds": $player_ids, "AcceptanceType": $acceptance_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Locates an available game server and temporarily reserves it to host gameplay and players. This operation is called from a game client or client service (such as a matchmaker) to request hosting resources for a new game session. In response, Amazon GameLift FleetIQ locates an available game server, places it in CLAIMED status for 60 seconds, and returns connection information that players can use to connect to the game server. To claim a game server, identify a game server group. You can also specify a game server ID, although this approach bypasses Amazon GameLift FleetIQ placement optimization. Optionally, include game data to pass to the game server at the start of a game session, such as a game map or player information. When a game server is successfully claimed, connection information is returned. A claimed game server's utilization status remains AVAILABLE while the claim status is set to CLAIMED for up to 60 seconds. This time period gives the game server time to update its status to UTILIZED after players join. If the game server's status is not updated within 60 seconds, the game server reverts to unclaimed status and is available to be claimed by another request. The claim time period is a fixed value and is not configurable. If you try to claim a specific game server, this request will fail in the following cases: If the game server utilization status is UTILIZED. If the game server claim status is CLAIMED. When claiming a specific game server, this request will succeed even if the game server is running on an instance in DRAINING status. To avoid this, first check the instance status by calling DescribeGameServerInstances (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeGameServerInstances.html) . Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: ClaimGameServer
export def "api create-claim-game-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-1
  game_server_group_name: any
  --game-server-id: any
  --game-server-data: any
]: any -> record<GameServer: record<GameServerGroupName: record, GameServerGroupArn: record, GameServerId: record, InstanceId: record, ConnectionInfo: record, GameServerData: record, ClaimStatus: record, UtilizationStatus: record, RegistrationTime: record, LastClaimTime: record, LastHealthCheckTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id, "GameServerData": $game_server_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates an alias for a fleet. In most situations, you can use an alias ID in place of a fleet ID. An alias provides a level of abstraction for a fleet that is useful when redirecting player traffic from one fleet to another, such as when updating your game build. Amazon GameLift supports two types of routing strategies for aliases: simple and terminal. A simple alias points to an active fleet. A terminal alias is used to display messaging or link to a URL instead of routing players to an active fleet. For example, you might use a terminal alias when a game version is no longer supported and you want to direct players to an upgrade site. To create a fleet alias, specify an alias name, routing strategy, and optional description. Each simple alias can point to only one fleet, but a fleet can have multiple aliases. If successful, a new alias record is returned, including an alias ID and an ARN. You can reassign an alias to another fleet by calling UpdateAlias. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreateAlias
export def "api create-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-2
  name: any
  --description: any
  routing_strategy: any
  --tags: any
]: any -> record<Alias: record<AliasId: record, Name: record, AliasArn: record, Description: record, RoutingStrategy: record<Type: record, FleetId: record, Message: record>, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "RoutingStrategy": $routing_strategy, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new Amazon GameLift build resource for your game server binary files. Combine game server binaries into a zip file for use with Amazon GameLift. When setting up a new game build for Amazon GameLift, we recommend using the CLI command upload-build (https://docs.aws.amazon.com/cli/latest/reference/gamelift/upload-build.html) . This helper command combines two tasks: (1) it uploads your build files from a file directory to a Amazon GameLift Amazon S3 location, and (2) it creates a new build resource. You can use the operation in the following scenarios: To create a new game build with build files that are in an Amazon S3 location under an Amazon Web Services account that you control. To use this option, you give Amazon GameLift access to the Amazon S3 bucket. With permissions in place, specify a build name, operating system, and the Amazon S3 storage location of your game build. To directly upload your build files to a Amazon GameLift Amazon S3 location. To use this option, specify a build name and operating system. This operation creates a new build resource and also returns an Amazon S3 location with temporary access credentials. Use the credentials to manually upload your build files to the specified Amazon S3 location. For more information, see Uploading Objects (https://docs.aws.amazon.com/AmazonS3/latest/dev/UploadingObjects.html) in the Amazon S3 Developer Guide. After you upload build files to the Amazon GameLift Amazon S3 location, you can't update them. If successful, this operation creates a new build resource with a unique build ID and places it in INITIALIZED status. A build must be in READY status before you can create fleets with it. Learn more Uploading Your Game (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html) Create a Build with Files in Amazon S3 (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-cli-uploading.html#gamelift-build-cli-uploading-create-build) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreateBuild
export def "api create-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-3
  --name: any
  --version: any
  --storage-location: any
  --operating-system: any
  --tags: any
  --server-sdk-version: any
]: any -> record<Build: record<BuildId: record, BuildArn: record, Name: record, Version: record, Status: record, SizeOnDisk: record, OperatingSystem: record, CreationTime: record, ServerSdkVersion: record>, UploadCredentials: record<AccessKeyId: record, SecretAccessKey: record, SessionToken: record>, StorageLocation: record<Bucket: record, Key: record, RoleArn: record, ObjectVersion: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Version": $version, "StorageLocation": $storage_location, "OperatingSystem": $operating_system, "Tags": $tags, "ServerSdkVersion": $server_sdk_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a fleet of Amazon Elastic Compute Cloud (Amazon EC2) instances to host your custom game server or Realtime Servers. Use this operation to configure the computing resources for your fleet and provide instructions for running game servers on each instance. Most Amazon GameLift fleets can deploy instances to multiple locations, including the home Region (where the fleet is created) and an optional set of remote locations. Fleets that are created in the following Amazon Web Services Regions support multiple locations: us-east-1 (N. Virginia), us-west-2 (Oregon), eu-central-1 (Frankfurt), eu-west-1 (Ireland), ap-southeast-2 (Sydney), ap-northeast-1 (Tokyo), and ap-northeast-2 (Seoul). Fleets that are created in other Amazon GameLift Regions can deploy instances in the fleet's home Region only. All fleet instances use the same configuration regardless of location; however, you can adjust capacity settings and turn auto-scaling on/off for each location. To create a fleet, choose the hardware for your instances, specify a game server build or Realtime script to deploy, and provide a runtime configuration to direct Amazon GameLift how to start and run game servers on each instance in the fleet. Set permissions for inbound traffic to your game servers, and enable optional features as needed. When creating a multi-location fleet, provide a list of additional remote locations. If you need to debug your fleet, fetch logs, view performance metrics or other actions on the fleet, create the development fleet with port 22/3389 open. As a best practice, we recommend opening ports for remote access only when you need them and closing them when you're finished. If successful, this operation creates a new Fleet resource and places it in NEW status, which prompts Amazon GameLift to initiate the fleet creation workflow (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-all.html#fleets-creation-workflow). Learn more Setting up fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html) Debug fleet creation issues (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-debug.html#fleets-creating-debug-creation) Multi-location fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: CreateFleet
export def "api create-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-4
  name: any
  --description: any
  --build-id: any
  --script-id: any
  --server-launch-path: any
  --server-launch-parameters: any
  --log-paths: any
  --ec2-instance-type: any
  --ec2-inbound-permissions: any
  --new-game-session-protection-policy: any
  --runtime-configuration: any
  --resource-creation-limit-policy: any
  --metric-groups: any
  --peer-vpc-aws-account-id: any
  --peer-vpc-id: any
  --fleet-type: any
  --instance-role-arn: any
  --certificate-configuration: any
  --locations: any
  --tags: any
  --compute-type: any
  --anywhere-configuration: any
]: any -> record<FleetAttributes: record<FleetId: record, FleetArn: record, FleetType: record, InstanceType: record, Description: record, Name: record, CreationTime: record, TerminationTime: record, Status: record, BuildId: record, BuildArn: record, ScriptId: record, ScriptArn: record, ServerLaunchPath: record, ServerLaunchParameters: record, LogPaths: record, NewGameSessionProtectionPolicy: record, OperatingSystem: record, ResourceCreationLimitPolicy: record<NewGameSessionsPerCreator: record, PolicyPeriodInMinutes: record>, MetricGroups: record, StoppedActions: record, InstanceRoleArn: record, CertificateConfiguration: record<CertificateType: record>, ComputeType: record, AnywhereConfiguration: record<Cost: record>>, LocationStates: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "BuildId": $build_id, "ScriptId": $script_id, "ServerLaunchPath": $server_launch_path, "ServerLaunchParameters": $server_launch_parameters, "LogPaths": $log_paths, "EC2InstanceType": $ec2_instance_type, "EC2InboundPermissions": $ec2_inbound_permissions, "NewGameSessionProtectionPolicy": $new_game_session_protection_policy, "RuntimeConfiguration": $runtime_configuration, "ResourceCreationLimitPolicy": $resource_creation_limit_policy, "MetricGroups": $metric_groups, "PeerVpcAwsAccountId": $peer_vpc_aws_account_id, "PeerVpcId": $peer_vpc_id, "FleetType": $fleet_type, "InstanceRoleArn": $instance_role_arn, "CertificateConfiguration": $certificate_configuration, "Locations": $locations, "Tags": $tags, "ComputeType": $compute_type, "AnywhereConfiguration": $anywhere_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Adds remote locations to a fleet and begins populating the new locations with EC2 instances. The new instances conform to the fleet's instance type, auto-scaling, and other configuration settings. This operation cannot be used with fleets that don't support remote locations. Fleets can have multiple locations only if they reside in Amazon Web Services Regions that support this feature and were created after the feature was released in March 2021. To add fleet locations, specify the fleet to be updated and provide a list of one or more locations. If successful, this operation returns the list of added locations with their status set to NEW. Amazon GameLift initiates the process of starting an instance in each added location. You can track the status of each new location by monitoring location creation events using DescribeFleetEvents (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeFleetEvents.html). Learn more Setting up fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html) Multi-location fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: CreateFleetLocations
export def "api create-fleet-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-5
  fleet_id: any
  locations: any
]: any -> record<FleetId: record, FleetArn: record, LocationStates: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Locations": $locations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Creates a Amazon GameLift FleetIQ game server group for managing game hosting on a collection of Amazon Elastic Compute Cloud instances for game hosting. This operation creates the game server group, creates an Auto Scaling group in your Amazon Web Services account, and establishes a link between the two groups. You can view the status of your game server groups in the Amazon GameLift console. Game server group metrics and events are emitted to Amazon CloudWatch. Before creating a new game server group, you must have the following: An Amazon Elastic Compute Cloud launch template that specifies how to launch Amazon Elastic Compute Cloud instances with your game server build. For more information, see Launching an Instance from a Launch Template (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html) in the Amazon Elastic Compute Cloud User Guide. An IAM role that extends limited access to your Amazon Web Services account to allow Amazon GameLift FleetIQ to create and interact with the Auto Scaling group. For more information, see Create IAM roles for cross-service interaction (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-iam-permissions-roles.html) in the Amazon GameLift FleetIQ Developer Guide. To create a new game server group, specify a unique group name, IAM role and Amazon Elastic Compute Cloud launch template, and provide a list of instance types that can be used in the group. You must also set initial maximum and minimum limits on the group's instance count. You can optionally set an Auto Scaling policy with target tracking based on a Amazon GameLift FleetIQ metric. Once the game server group and corresponding Auto Scaling group are created, you have full access to change the Auto Scaling group's configuration as needed. Several properties that are set when creating a game server group, including maximum/minimum size and auto-scaling policy settings, must be updated directly in the Auto Scaling group. Keep in mind that some Auto Scaling group properties are periodically updated by Amazon GameLift FleetIQ as part of its balancing activities to optimize for availability and cost. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: CreateGameServerGroup
export def "api create-game-server-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-6
  game_server_group_name: any
  role_arn: any
  min_size: any
  max_size: any
  launch_template: any
  instance_definitions: any
  --auto-scaling-policy: any
  --balancing-strategy: any
  --game-server-protection-policy: any
  --vpc-subnets: any
  --tags: any
]: any -> record<GameServerGroup: record<GameServerGroupName: record, GameServerGroupArn: record, RoleArn: record, InstanceDefinitions: record, BalancingStrategy: record, GameServerProtectionPolicy: record, AutoScalingGroupArn: record, Status: record, StatusReason: record, SuspendedActions: record, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "RoleArn": $role_arn, "MinSize": $min_size, "MaxSize": $max_size, "LaunchTemplate": $launch_template, "InstanceDefinitions": $instance_definitions, "AutoScalingPolicy": $auto_scaling_policy, "BalancingStrategy": $balancing_strategy, "GameServerProtectionPolicy": $game_server_protection_policy, "VpcSubnets": $vpc_subnets, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a multiplayer game session for players in a specific fleet location. This operation prompts an available server process to start a game session and retrieves connection information for the new game session. As an alternative, consider using the Amazon GameLift game session placement feature with StartGameSessionPlacement (https://docs.aws.amazon.com/gamelift/latest/apireference/API_StartGameSessionPlacement.html) , which uses FleetIQ algorithms and queues to optimize the placement process. When creating a game session, you specify exactly where you want to place it and provide a set of game session configuration settings. The fleet must be in ACTIVE status before a game session can be created in it. This operation can be used in the following ways: To create a game session on an instance in a fleet's home Region, provide a fleet or alias ID along with your game session configuration. To create a game session on an instance in a fleet's remote location, provide a fleet or alias ID and a location name, along with your game session configuration. If successful, a workflow is initiated to start a new game session. A GameSession object is returned containing the game session configuration and status. When the status is ACTIVE, game session connection information is provided and player sessions can be created for the game session. By default, newly created game sessions are open to new players. You can restrict new player access by using UpdateGameSession (https://docs.aws.amazon.com/gamelift/latest/apireference/API_UpdateGameSession.html) to change the game session's player session creation policy. Game session logs are retained for all active game sessions for 14 days. To access the logs, call GetGameSessionLogUrl (https://docs.aws.amazon.com/gamelift/latest/apireference/API_GetGameSessionLogUrl.html) to download the log files. Available in Amazon GameLift Local. Learn more Start a game session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreateGameSession
export def "api create-game-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-7
  --fleet-id: any
  --alias-id: any
  maximum_player_session_count: any
  --name: any
  --game-properties: any
  --creator-id: any
  --game-session-id: any
  --idempotency-token: any
  --game-session-data: any
  --location: any
]: any -> record<GameSession: record<GameSessionId: record, Name: record, FleetId: record, FleetArn: record, CreationTime: record, TerminationTime: record, CurrentPlayerSessionCount: record, MaximumPlayerSessionCount: record, Status: record, StatusReason: record, GameProperties: record, IpAddress: record, DnsName: record, Port: record, PlayerSessionCreationPolicy: record, CreatorId: record, GameSessionData: record, MatchmakerData: record, Location: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "AliasId": $alias_id, "MaximumPlayerSessionCount": $maximum_player_session_count, "Name": $name, "GameProperties": $game_properties, "CreatorId": $creator_id, "GameSessionId": $game_session_id, "IdempotencyToken": $idempotency_token, "GameSessionData": $game_session_data, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a placement queue that processes requests for new game sessions. A queue uses FleetIQ algorithms to determine the best placement locations and find an available game server there, then prompts the game server process to start a new game session. A game session queue is configured with a set of destinations (Amazon GameLift fleets or aliases), which determine the locations where the queue can place new game sessions. These destinations can span multiple fleet types (Spot and On-Demand), instance types, and Amazon Web Services Regions. If the queue includes multi-location fleets, the queue is able to place game sessions in all of a fleet's remote locations. You can opt to filter out individual locations if needed. The queue configuration also determines how FleetIQ selects the best available placement for a new game session. Before searching for an available game server, FleetIQ first prioritizes the queue's destinations and locations, with the best placement locations on top. You can set up the queue to use the FleetIQ default prioritization or provide an alternate set of priorities. To create a new queue, provide a name, timeout value, and a list of destinations. Optionally, specify a sort configuration and/or a filter, and define a set of latency cap policies. You can also include the ARN for an Amazon Simple Notification Service (SNS) topic to receive notifications of game session placement activity. Notifications using SNS or CloudWatch events is the preferred way to track placement activity. If successful, a new GameSessionQueue object is returned with an assigned queue ARN. New game session requests, which are submitted to queue with StartGameSessionPlacement (https://docs.aws.amazon.com/gamelift/latest/apireference/API_StartGameSessionPlacement.html) or StartMatchmaking (https://docs.aws.amazon.com/gamelift/latest/apireference/API_StartMatchmaking.html), reference a queue's name or ARN. Learn more Design a game session queue (https://docs.aws.amazon.com/gamelift/latest/developerguide/queues-design.html) Create a game session queue (https://docs.aws.amazon.com/gamelift/latest/developerguide/queues-creating.html) Related actions CreateGameSessionQueue (https://docs.aws.amazon.com/gamelift/latest/apireference/API_CreateGameSessionQueue.html) | DescribeGameSessionQueues (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeGameSessionQueues.html) | UpdateGameSessionQueue (https://docs.aws.amazon.com/gamelift/latest/apireference/API_UpdateGameSessionQueue.html) | DeleteGameSessionQueue (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DeleteGameSessionQueue.html) | All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreateGameSessionQueue
export def "api create-game-session-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-8
  name: any
  --timeout-in-seconds: any
  --player-latency-policies: any
  --destinations: any
  --filter-configuration: any
  --priority-configuration: any
  --custom-event-data: any
  --notification-target: any
  --tags: any
]: any -> record<GameSessionQueue: record<Name: record, GameSessionQueueArn: record, TimeoutInSeconds: record, PlayerLatencyPolicies: record, Destinations: record, FilterConfiguration: record<AllowedLocations: record>, PriorityConfiguration: record<PriorityOrder: record, LocationOrder: record>, CustomEventData: record, NotificationTarget: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "TimeoutInSeconds": $timeout_in_seconds, "PlayerLatencyPolicies": $player_latency_policies, "Destinations": $destinations, "FilterConfiguration": $filter_configuration, "PriorityConfiguration": $priority_configuration, "CustomEventData": $custom_event_data, "NotificationTarget": $notification_target, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a custom location for use in an Anywhere fleet.
#
# POST /
# operationId: CreateLocation
export def "api create-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-9
  location_name: any
  --tags: any
]: any -> record<Location: record<LocationName: record, LocationArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationName": $location_name, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Defines a new matchmaking configuration for use with FlexMatch. Whether your are using FlexMatch with Amazon GameLift hosting or as a standalone matchmaking service, the matchmaking configuration sets out rules for matching players and forming teams. If you're also using Amazon GameLift hosting, it defines how to start game sessions for each match. Your matchmaking system can use multiple configurations to handle different game scenarios. All matchmaking requests identify the matchmaking configuration to use and provide player attributes consistent with that configuration. To create a matchmaking configuration, you must provide the following: configuration name and FlexMatch mode (with or without Amazon GameLift hosting); a rule set that specifies how to evaluate players and find acceptable matches; whether player acceptance is required; and the maximum time allowed for a matchmaking attempt. When using FlexMatch with Amazon GameLift hosting, you also need to identify the game session queue to use when starting a game session for the match. In addition, you must set up an Amazon Simple Notification Service topic to receive matchmaking notifications. Provide the topic ARN in the matchmaking configuration. Learn more Design a FlexMatch matchmaker (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-configuration.html) Set up FlexMatch event notification (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-notification.html)
#
# POST /
# operationId: CreateMatchmakingConfiguration
export def "api create-matchmaking-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-10
  name: any
  --description: any
  --game-session-queue-arns: any
  request_timeout_seconds: any
  --acceptance-timeout-seconds: any
  acceptance_required: any
  rule_set_name: any
  --notification-target: any
  --additional-player-count: any
  --custom-event-data: any
  --game-properties: any
  --game-session-data: any
  --backfill-mode: any
  --flex-match-mode: any
  --tags: any
]: any -> record<Configuration: record<Name: record, ConfigurationArn: record, Description: record, GameSessionQueueArns: record, RequestTimeoutSeconds: record, AcceptanceTimeoutSeconds: record, AcceptanceRequired: record, RuleSetName: record, RuleSetArn: record, NotificationTarget: record, AdditionalPlayerCount: record, CustomEventData: record, CreationTime: record, GameProperties: record, GameSessionData: record, BackfillMode: record, FlexMatchMode: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "GameSessionQueueArns": $game_session_queue_arns, "RequestTimeoutSeconds": $request_timeout_seconds, "AcceptanceTimeoutSeconds": $acceptance_timeout_seconds, "AcceptanceRequired": $acceptance_required, "RuleSetName": $rule_set_name, "NotificationTarget": $notification_target, "AdditionalPlayerCount": $additional_player_count, "CustomEventData": $custom_event_data, "GameProperties": $game_properties, "GameSessionData": $game_session_data, "BackfillMode": $backfill_mode, "FlexMatchMode": $flex_match_mode, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new rule set for FlexMatch matchmaking. A rule set describes the type of match to create, such as the number and size of teams. It also sets the parameters for acceptable player matches, such as minimum skill level or character type. To create a matchmaking rule set, provide unique rule set name and the rule set body in JSON format. Rule sets must be defined in the same Region as the matchmaking configuration they are used with. Since matchmaking rule sets cannot be edited, it is a good idea to check the rule set syntax using ValidateMatchmakingRuleSet (https://docs.aws.amazon.com/gamelift/latest/apireference/API_ValidateMatchmakingRuleSet.html) before creating a new rule set. Learn more Build a rule set (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-rulesets.html) Design a matchmaker (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-configuration.html) Matchmaking with FlexMatch (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-intro.html)
#
# POST /
# operationId: CreateMatchmakingRuleSet
export def "api create-matchmaking-rule-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-11
  name: any
  rule_set_body: any
  --tags: any
]: any -> record<RuleSet: record<RuleSetName: record, RuleSetArn: record, RuleSetBody: record, CreationTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "RuleSetBody": $rule_set_body, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Reserves an open player slot in a game session for a player. New player sessions can be created in any game session with an open slot that is in ACTIVE status and has a player creation policy of ACCEPT_ALL. You can add a group of players to a game session with CreatePlayerSessions (https://docs.aws.amazon.com/gamelift/latest/apireference/API_CreatePlayerSessions.html) . To create a player session, specify a game session ID, player ID, and optionally a set of player data. If successful, a slot is reserved in the game session for the player and a new PlayerSessions object is returned with a player session ID. The player references the player session ID when sending a connection request to the game session, and the game server can use it to validate the player reservation with the Amazon GameLift service. Player sessions cannot be updated. The maximum number of players per game session is 200. It is not adjustable. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreatePlayerSession
export def "api create-player-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-12
  game_session_id: any
  player_id: any
  --player-data: any
]: any -> record<PlayerSession: record<PlayerSessionId: record, PlayerId: record, GameSessionId: record, FleetId: record, FleetArn: record, CreationTime: record, TerminationTime: record, Status: record, IpAddress: record, DnsName: record, Port: record, PlayerData: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameSessionId": $game_session_id, "PlayerId": $player_id, "PlayerData": $player_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Reserves open slots in a game session for a group of players. New player sessions can be created in any game session with an open slot that is in ACTIVE status and has a player creation policy of ACCEPT_ALL. To add a single player to a game session, use CreatePlayerSession (https://docs.aws.amazon.com/gamelift/latest/apireference/API_CreatePlayerSession.html) To create player sessions, specify a game session ID and a list of player IDs. Optionally, provide a set of player data for each player ID. If successful, a slot is reserved in the game session for each player, and new PlayerSession objects are returned with player session IDs. Each player references their player session ID when sending a connection request to the game session, and the game server can use it to validate the player reservation with the Amazon GameLift service. Player sessions cannot be updated. The maximum number of players per game session is 200. It is not adjustable. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreatePlayerSessions
export def "api create-player-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-13
  game_session_id: any
  player_ids: any
  --player-data-map: any
]: any -> record<PlayerSessions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameSessionId": $game_session_id, "PlayerIds": $player_ids, "PlayerDataMap": $player_data_map} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new script record for your Realtime Servers script. Realtime scripts are JavaScript that provide configuration settings and optional custom game logic for your game. The script is deployed when you create a Realtime Servers fleet to host your game sessions. Script logic is executed during an active game session. To create a new script record, specify a script name and provide the script file(s). The script files and all dependencies must be zipped into a single file. You can pull the zip file from either of these locations: A locally available directory. Use the ZipFile parameter for this option. An Amazon Simple Storage Service (Amazon S3) bucket under your Amazon Web Services account. Use the StorageLocation parameter for this option. You'll need to have an Identity Access Management (IAM) role that allows the Amazon GameLift service to access your S3 bucket. If the call is successful, a new script record is created with a unique script ID. If the script file is provided as a local file, the file is uploaded to an Amazon GameLift-owned S3 bucket and the script record's storage location reflects this location. If the script file is provided as an S3 bucket, Amazon GameLift accesses the file at this storage location as needed for deployment. Learn more Amazon GameLift Realtime Servers (https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html) Set Up a Role for Amazon GameLift Access (https://docs.aws.amazon.com/gamelift/latest/developerguide/setting-up-role.html) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreateScript
export def "api create-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-14
  --name: any
  --version: any
  --storage-location: any
  --zip-file: any
  --tags: any
]: any -> record<Script: record<ScriptId: record, ScriptArn: record, Name: record, Version: record, SizeOnDisk: record, CreationTime: record, StorageLocation: record<Bucket: record, Key: record, RoleArn: record, ObjectVersion: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Version": $version, "StorageLocation": $storage_location, "ZipFile": $zip_file, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Requests authorization to create or delete a peer connection between the VPC for your Amazon GameLift fleet and a virtual private cloud (VPC) in your Amazon Web Services account. VPC peering enables the game servers on your fleet to communicate directly with other Amazon Web Services resources. After you've received authorization, use CreateVpcPeeringConnection (https://docs.aws.amazon.com/gamelift/latest/apireference/API_CreateVpcPeeringConnection.html) to establish the peering connection. For more information, see VPC Peering with Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html). You can peer with VPCs that are owned by any Amazon Web Services account you have access to, including the account that you use to manage your Amazon GameLift fleets. You cannot peer with VPCs that are in different Regions. To request authorization to create a connection, call this operation from the Amazon Web Services account with the VPC that you want to peer to your Amazon GameLift fleet. For example, to enable your game servers to retrieve data from a DynamoDB table, use the account that manages that DynamoDB resource. Identify the following values: (1) The ID of the VPC that you want to peer with, and (2) the ID of the Amazon Web Services account that you use to manage Amazon GameLift. If successful, VPC peering is authorized for the specified VPC. To request authorization to delete a connection, call this operation from the Amazon Web Services account with the VPC that is peered with your Amazon GameLift fleet. Identify the following values: (1) VPC ID that you want to delete the peering connection for, and (2) ID of the Amazon Web Services account that you use to manage Amazon GameLift. The authorization remains valid for 24 hours unless it is canceled. You must create or delete the peering connection while the authorization is valid. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreateVpcPeeringAuthorization
export def "api create-vpc-peering-authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-15
  game_lift_aws_account_id: any
  peer_vpc_id: any
]: any -> record<VpcPeeringAuthorization: record<GameLiftAwsAccountId: record, PeerVpcAwsAccountId: record, PeerVpcId: record, CreationTime: record, ExpirationTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameLiftAwsAccountId": $game_lift_aws_account_id, "PeerVpcId": $peer_vpc_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Establishes a VPC peering connection between a virtual private cloud (VPC) in an Amazon Web Services account with the VPC for your Amazon GameLift fleet. VPC peering enables the game servers on your fleet to communicate directly with other Amazon Web Services resources. You can peer with VPCs in any Amazon Web Services account that you have access to, including the account that you use to manage your Amazon GameLift fleets. You cannot peer with VPCs that are in different Regions. For more information, see VPC Peering with Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html). Before calling this operation to establish the peering connection, you first need to use CreateVpcPeeringAuthorization (https://docs.aws.amazon.com/gamelift/latest/apireference/API_CreateVpcPeeringAuthorization.html) and identify the VPC you want to peer with. Once the authorization for the specified VPC is issued, you have 24 hours to establish the connection. These two operations handle all tasks necessary to peer the two VPCs, including acceptance, updating routing tables, etc. To establish the connection, call this operation from the Amazon Web Services account that is used to manage the Amazon GameLift fleets. Identify the following values: (1) The ID of the fleet you want to be enable a VPC peering connection for; (2) The Amazon Web Services account with the VPC that you want to peer with; and (3) The ID of the VPC you want to peer with. This operation is asynchronous. If successful, a connection request is created. You can use continuous polling to track the request's status using DescribeVpcPeeringConnections (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeVpcPeeringConnections.html) , or by monitoring fleet events for success or failure using DescribeFleetEvents (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeFleetEvents.html) . Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: CreateVpcPeeringConnection
export def "api create-vpc-peering-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-16
  fleet_id: any
  peer_vpc_aws_account_id: any
  peer_vpc_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "PeerVpcAwsAccountId": $peer_vpc_aws_account_id, "PeerVpcId": $peer_vpc_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an alias. This operation removes all record of the alias. Game clients attempting to access a server process using the deleted alias receive an error. To delete an alias, specify the alias ID to be deleted. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DeleteAlias
export def "api delete-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-17
  alias_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AliasId": $alias_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a build. This operation permanently deletes the build resource and any uploaded build files. Deleting a build does not affect the status of any active fleets using the build, but you can no longer create new fleets with the deleted build. To delete a build, specify the build ID. Learn more Upload a Custom Server Build (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DeleteBuild
export def "api delete-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-18
  build_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BuildId": $build_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes all resources and information related a fleet. Any current fleet instances, including those in remote locations, are shut down. You don't need to call DeleteFleetLocations separately. If the fleet being deleted has a VPC peering connection, you first need to get a valid authorization (good for 24 hours) by calling CreateVpcPeeringAuthorization (https://docs.aws.amazon.com/gamelift/latest/apireference/API_CreateVpcPeeringAuthorization.html). You do not need to explicitly delete the VPC peering connection. To delete a fleet, specify the fleet ID to be terminated. During the deletion process the fleet status is changed to DELETING. When completed, the status switches to TERMINATED and the fleet event FLEET_DELETED is sent. Learn more Setting up Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: DeleteFleet
export def "api delete-fleet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-19
  fleet_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes locations from a multi-location fleet. When deleting a location, all game server process and all instances that are still active in the location are shut down. To delete fleet locations, identify the fleet ID and provide a list of the locations to be deleted. If successful, GameLift sets the location status to DELETING, and begins to shut down existing server processes and terminate instances in each location being deleted. When completed, the location status changes to TERMINATED. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: DeleteFleetLocations
export def "api delete-fleet-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-20
  fleet_id: any
  locations: any
]: any -> record<FleetId: record, FleetArn: record, LocationStates: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Locations": $locations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Terminates a game server group and permanently deletes the game server group record. You have several options for how these resources are impacted when deleting the game server group. Depending on the type of delete operation selected, this operation might affect these resources: The game server group The corresponding Auto Scaling group All game servers that are currently running in the group To delete a game server group, identify the game server group to delete and specify the type of delete operation to initiate. Game server groups can only be deleted if they are in ACTIVE or ERROR status. If the delete request is successful, a series of operations are kicked off. The game server group status is changed to DELETE_SCHEDULED, which prevents new game servers from being registered and stops automatic scaling activity. Once all game servers in the game server group are deregistered, Amazon GameLift FleetIQ can begin deleting resources. If any of the delete operations fail, the game server group is placed in ERROR status. Amazon GameLift FleetIQ emits delete events to Amazon CloudWatch. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: DeleteGameServerGroup
export def "api delete-game-server-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-21
  game_server_group_name: any
  --delete-option: any
]: any -> record<GameServerGroup: record<GameServerGroupName: record, GameServerGroupArn: record, RoleArn: record, InstanceDefinitions: record, BalancingStrategy: record, GameServerProtectionPolicy: record, AutoScalingGroupArn: record, Status: record, StatusReason: record, SuspendedActions: record, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "DeleteOption": $delete_option} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a game session queue. Once a queue is successfully deleted, unfulfilled StartGameSessionPlacement (https://docs.aws.amazon.com/gamelift/latest/apireference/API_StartGameSessionPlacement.html) requests that reference the queue will fail. To delete a queue, specify the queue name.
#
# POST /
# operationId: DeleteGameSessionQueue
export def "api delete-game-session-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-22
  name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a custom location. Before deleting a custom location, review any fleets currently using the custom location and deregister the location if it is in use. For more information see, DeregisterCompute (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DeregisterCompute.html).
#
# POST /
# operationId: DeleteLocation
export def "api delete-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-23
  location_name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationName": $location_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Permanently removes a FlexMatch matchmaking configuration. To delete, specify the configuration name. A matchmaking configuration cannot be deleted if it is being used in any active matchmaking tickets.
#
# POST /
# operationId: DeleteMatchmakingConfiguration
export def "api delete-matchmaking-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-24
  name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an existing matchmaking rule set. To delete the rule set, provide the rule set name. Rule sets cannot be deleted if they are currently being used by a matchmaking configuration. Learn more Build a rule set (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-rulesets.html)
#
# POST /
# operationId: DeleteMatchmakingRuleSet
export def "api delete-matchmaking-rule-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-25
  name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a fleet scaling policy. Once deleted, the policy is no longer in force and Amazon GameLift removes all record of it. To delete a scaling policy, specify both the scaling policy name and the fleet ID it is associated with. To temporarily suspend scaling policies, use StopFleetActions (https://docs.aws.amazon.com/gamelift/latest/apireference/API_StopFleetActions.html). This operation suspends all policies for the fleet.
#
# POST /
# operationId: DeleteScalingPolicy
export def "api delete-scaling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-26
  name: any
  fleet_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "FleetId": $fleet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a Realtime script. This operation permanently deletes the script record. If script files were uploaded, they are also deleted (files stored in an S3 bucket are not deleted). To delete a script, specify the script ID. Before deleting a script, be sure to terminate all fleets that are deployed with the script being deleted. Fleet instances periodically check for script updates, and if the script record no longer exists, the instance will go into an error state and be unable to host game sessions. Learn more Amazon GameLift Realtime Servers (https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DeleteScript
export def "api delete-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-27
  script_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScriptId": $script_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancels a pending VPC peering authorization for the specified VPC. If you need to delete an existing VPC peering connection, use DeleteVpcPeeringConnection (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DeleteVpcPeeringConnection.html). Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DeleteVpcPeeringAuthorization
export def "api delete-vpc-peering-authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28
  game_lift_aws_account_id: any
  peer_vpc_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameLiftAwsAccountId": $game_lift_aws_account_id, "PeerVpcId": $peer_vpc_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes a VPC peering connection. To delete the connection, you must have a valid authorization for the VPC peering connection that you want to delete.. Once a valid authorization exists, call this operation from the Amazon Web Services account that is used to manage the Amazon GameLift fleets. Identify the connection to delete by the connection ID and fleet ID. If successful, the connection is removed. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DeleteVpcPeeringConnection
export def "api delete-vpc-peering-connection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-29
  fleet_id: any
  vpc_peering_connection_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "VpcPeeringConnectionId": $vpc_peering_connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes a compute resource from the specified fleet. Deregister your compute resources before you delete the compute.
#
# POST /
# operationId: DeregisterCompute
export def "api create-deregister-compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30
  fleet_id: any
  compute_name: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Removes the game server from a game server group. As a result of this operation, the deregistered game server can no longer be claimed and will not be returned in a list of active game servers. To deregister a game server, specify the game server group and game server ID. If successful, this operation emits a CloudWatch event with termination timestamp and reason. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: DeregisterGameServer
export def "api create-deregister-game-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31
  game_server_group_name: any
  game_server_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves properties for an alias. This operation returns all alias metadata and settings. To get an alias's target fleet ID only, use ResolveAlias. To get alias properties, specify the alias ID. If successful, the requested alias record is returned. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribeAlias
export def "api get-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32
  alias_id: any
]: any -> record<Alias: record<AliasId: record, Name: record, AliasArn: record, Description: record, RoutingStrategy: record<Type: record, FleetId: record, Message: record>, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AliasId": $alias_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves properties for a custom game build. To request a build resource, specify a build ID. If successful, an object containing the build properties is returned. Learn more Upload a Custom Server Build (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribeBuild
export def "api get-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33
  build_id: any
]: any -> record<Build: record<BuildId: record, BuildArn: record, Name: record, Version: record, Status: record, SizeOnDisk: record, OperatingSystem: record, CreationTime: record, ServerSdkVersion: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BuildId": $build_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves properties for a compute resource. To request a compute resource specify the fleet ID and compute name. If successful, Amazon GameLift returns an object containing the build properties.
#
# POST /
# operationId: DescribeCompute
export def "api get-compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34
  fleet_id: any
  compute_name: any
]: any -> record<Compute: record<FleetId: record, FleetArn: record, ComputeName: record, ComputeArn: record, IpAddress: record, DnsName: record, ComputeStatus: record, Location: record, CreationTime: record, OperatingSystem: record, Type: record, GameLiftServiceSdkEndpoint: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the instance limits and current utilization for an Amazon Web Services Region or location. Instance limits control the number of instances, per instance type, per location, that your Amazon Web Services account can use. Learn more at Amazon EC2 Instance Types (http://aws.amazon.com/ec2/instance-types/). The information returned includes the maximum number of instances allowed and your account's current usage across all fleets. This information can affect your ability to scale your Amazon GameLift fleets. You can request a limit increase for your account by using the Service limits page in the Amazon GameLift console. Instance limits differ based on whether the instances are deployed in a fleet's home Region or in a remote location. For remote locations, limits also differ based on the combination of home Region and remote location. All requests must specify an Amazon Web Services Region (either explicitly or as your default settings). To get the limit for a remote location, you must also specify the location. For example, the following requests all return different results: Request specifies the Region ap-northeast-1 with no location. The result is limits and usage data on all instance types that are deployed in us-east-2, by all of the fleets that reside in ap-northeast-1. Request specifies the Region us-east-1 with location ca-central-1. The result is limits and usage data on all instance types that are deployed in ca-central-1, by all of the fleets that reside in us-east-2. These limits do not affect fleets in any other Regions that deploy instances to ca-central-1. Request specifies the Region eu-west-1 with location ca-central-1. The result is limits and usage data on all instance types that are deployed in ca-central-1, by all of the fleets that reside in eu-west-1. This operation can be used in the following ways: To get limit and usage data for all instance types that are deployed in an Amazon Web Services Region by fleets that reside in the same Region: Specify the Region only. Optionally, specify a single instance type to retrieve information for. To get limit and usage data for all instance types that are deployed to a remote location by fleets that reside in different Amazon Web Services Region: Provide both the Amazon Web Services Region and the remote location. Optionally, specify a single instance type to retrieve information for. If successful, an EC2InstanceLimits object is returned with limits and usage data for each requested instance type. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: DescribeEC2InstanceLimits
export def "api get-ec2-instance-limits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-35
  --ec2-instance-type: any
  --location: any
]: any -> record<EC2InstanceLimits: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"EC2InstanceType": $ec2_instance_type, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves core fleet-wide properties, including the computing hardware and deployment configuration for all instances in the fleet. This operation can be used in the following ways: To get attributes for one or more specific fleets, provide a list of fleet IDs or fleet ARNs. To get attributes for all fleets, do not provide a fleet identifier. When requesting attributes for multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a FleetAttributes object is returned for each fleet requested, unless the fleet identifier is not found. Some API operations limit the number of fleet IDs that allowed in one request. If a request exceeds this limit, the request fails and the error message contains the maximum allowed number. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: DescribeFleetAttributes
export def "api get-fleet-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36
  --fleet-ids: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<FleetAttributes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetIds": $fleet_ids, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the resource capacity settings for one or more fleets. The data returned includes the current fleet capacity (number of EC2 instances), and settings that can control how capacity scaling. For fleets with remote locations, this operation retrieves data for the fleet's home Region only. This operation can be used in the following ways: To get capacity data for one or more specific fleets, provide a list of fleet IDs or fleet ARNs. To get capacity data for all fleets, do not provide a fleet identifier. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a FleetCapacity object is returned for each requested fleet ID. Each FleetCapacity object includes a Location property, which is set to the fleet's home Region. When a list of fleet IDs is provided, attribute objects are returned only for fleets that currently exist. Some API operations may limit the number of fleet IDs that are allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html) GameLift metrics for fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/monitoring-cloudwatch.html#gamelift-metrics-fleet)
#
# POST /
# operationId: DescribeFleetCapacity
export def "api get-fleet-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37
  --fleet-ids: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<FleetCapacity: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetIds": $fleet_ids, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves entries from a fleet's event log. Fleet events are initiated by changes in status, such as during fleet creation and termination, changes in capacity, etc. If a fleet has multiple locations, events are also initiated by changes to status and capacity in remote locations. You can specify a time range to limit the result set. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a collection of event log entries matching the request are returned. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: DescribeFleetEvents
export def "api get-fleet-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38
  fleet_id: any
  --start-time: any
  --end-time: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<Events: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "StartTime": $start_time, "EndTime": $end_time, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information on a fleet's remote locations, including life-cycle status and any suspended fleet activity. This operation can be used in the following ways: To get data for specific locations, provide a fleet identifier and a list of locations. Location data is returned in the order that it is requested. To get data for all locations, provide a fleet identifier only. Location data is returned in no particular order. When requesting attributes for multiple locations, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a LocationAttributes object is returned for each requested location. If the fleet does not have a requested location, no information is returned. This operation does not return the home Region. To get information on a fleet's home Region, call DescribeFleetAttributes. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: DescribeFleetLocationAttributes
export def "api get-fleet-location-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-39
  fleet_id: any
  --locations: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<FleetId: record, FleetArn: record, LocationAttributes: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "Locations": $locations, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the resource capacity settings for a fleet location. The data returned includes the current capacity (number of EC2 instances) and some scaling settings for the requested fleet location. Use this operation to retrieve capacity information for a fleet's remote location or home Region (you can also retrieve home Region capacity by calling DescribeFleetCapacity). To retrieve capacity data, identify a fleet and location. If successful, a FleetCapacity object is returned for the requested fleet location. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html) GameLift metrics for fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/monitoring-cloudwatch.html#gamelift-metrics-fleet)
#
# POST /
# operationId: DescribeFleetLocationCapacity
export def "api get-fleet-location-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40
  fleet_id: any
  location: any
]: any -> record<FleetCapacity: record<FleetId: record, FleetArn: record, InstanceType: record, InstanceCounts: record<DESIRED: record, MINIMUM: record, MAXIMUM: record, PENDING: record, ACTIVE: record, IDLE: record, TERMINATING: record>, Location: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves current usage data for a fleet location. Utilization data provides a snapshot of current game hosting activity at the requested location. Use this operation to retrieve utilization information for a fleet's remote location or home Region (you can also retrieve home Region utilization by calling DescribeFleetUtilization). To retrieve utilization data, identify a fleet and location. If successful, a FleetUtilization object is returned for the requested fleet location. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html) GameLift metrics for fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/monitoring-cloudwatch.html#gamelift-metrics-fleet)
#
# POST /
# operationId: DescribeFleetLocationUtilization
export def "api get-fleet-location-utilization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41
  fleet_id: any
  location: any
]: any -> record<FleetUtilization: record<FleetId: record, FleetArn: record, ActiveServerProcessCount: record, ActiveGameSessionCount: record, CurrentPlayerSessionCount: record, MaximumPlayerSessionCount: record, Location: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a fleet's inbound connection permissions. Connection permissions specify the range of IP addresses and port settings that incoming traffic can use to access server processes in the fleet. Game sessions that are running on instances in the fleet must use connections that fall in this range. This operation can be used in the following ways: To retrieve the inbound connection permissions for a fleet, identify the fleet's unique identifier. To check the status of recent updates to a fleet remote location, specify the fleet ID and a location. Port setting updates can take time to propagate across all locations. If successful, a set of IpPermission objects is returned for the requested fleet ID. When a location is specified, a pending status is included. If the requested fleet has been deleted, the result set is empty. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: DescribeFleetPortSettings
export def "api get-fleet-port-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42
  fleet_id: any
  --location: any
]: any -> record<FleetId: record, FleetArn: record, InboundPermissions: record, UpdateStatus: record, Location: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves utilization statistics for one or more fleets. Utilization data provides a snapshot of how the fleet's hosting resources are currently being used. For fleets with remote locations, this operation retrieves data for the fleet's home Region only. See DescribeFleetLocationUtilization (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeFleetLocationUtilization.html) to get utilization statistics for a fleet's remote locations. This operation can be used in the following ways: To get utilization data for one or more specific fleets, provide a list of fleet IDs or fleet ARNs. To get utilization data for all fleets, do not provide a fleet identifier. When requesting multiple fleets, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a FleetUtilization (https://docs.aws.amazon.com/gamelift/latest/apireference/API_FleetUtilization.html) object is returned for each requested fleet ID, unless the fleet identifier is not found. Each fleet utilization object includes a Location property, which is set to the fleet's home Region. Some API operations may limit the number of fleet IDs allowed in one request. If a request exceeds this limit, the request fails and the error message includes the maximum allowed. Learn more Setting up Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html) GameLift Metrics for Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/monitoring-cloudwatch.html#gamelift-metrics-fleet)
#
# POST /
# operationId: DescribeFleetUtilization
export def "api get-fleet-utilization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43
  --fleet-ids: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<FleetUtilization: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetIds": $fleet_ids, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Retrieves information for a registered game server. Information includes game server status, health check info, and the instance that the game server is running on. To retrieve game server information, specify the game server ID. If successful, the requested game server object is returned. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: DescribeGameServer
export def "api get-game-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44
  game_server_group_name: any
  game_server_id: any
]: any -> record<GameServer: record<GameServerGroupName: record, GameServerGroupArn: record, GameServerId: record, InstanceId: record, ConnectionInfo: record, GameServerData: record, ClaimStatus: record, UtilizationStatus: record, RegistrationTime: record, LastClaimTime: record, LastHealthCheckTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Retrieves information on a game server group. This operation returns only properties related to Amazon GameLift FleetIQ. To view or update properties for the corresponding Auto Scaling group, such as launch template, auto scaling policies, and maximum/minimum group size, access the Auto Scaling group directly. To get attributes for a game server group, provide a group name or ARN value. If successful, a GameServerGroup object is returned. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: DescribeGameServerGroup
export def "api get-game-server-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45
  game_server_group_name: any
]: any -> record<GameServerGroup: record<GameServerGroupName: record, GameServerGroupArn: record, RoleArn: record, InstanceDefinitions: record, BalancingStrategy: record, GameServerProtectionPolicy: record, AutoScalingGroupArn: record, Status: record, StatusReason: record, SuspendedActions: record, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Retrieves status information about the Amazon EC2 instances associated with a Amazon GameLift FleetIQ game server group. Use this operation to detect when instances are active or not available to host new game servers. To request status for all instances in the game server group, provide a game server group ID only. To request status for specific instances, provide the game server group ID and one or more instance IDs. Use the pagination parameters to retrieve results in sequential segments. If successful, a collection of GameServerInstance objects is returned. This operation is not designed to be called with every game server claim request; this practice can cause you to exceed your API limit, which results in errors. Instead, as a best practice, cache the results and refresh your cache no more than once every 10 seconds. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: DescribeGameServerInstances
export def "api get-game-server-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46
  game_server_group_name: any
  --instance-ids: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<GameServerInstances: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "InstanceIds": $instance_ids, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves additional game session properties, including the game session protection policy in force, a set of one or more game sessions in a specific fleet location. You can optionally filter the results by current game session status. This operation can be used in the following ways: To retrieve details for all game sessions that are currently running on all locations in a fleet, provide a fleet or alias ID, with an optional status filter. This approach returns details from the fleet's home Region and all remote locations. To retrieve details for all game sessions that are currently running on a specific fleet location, provide a fleet or alias ID and a location name, with optional status filter. The location can be the fleet's home Region or any remote location. To retrieve details for a specific game session, provide the game session ID. This approach looks for the game session ID in all fleets that reside in the Amazon Web Services Region defined in the request. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a GameSessionDetail object is returned for each game session that matches the request. Learn more Find a game session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-client-api.html#gamelift-sdk-client-api-find) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribeGameSessionDetails
export def "api get-game-session-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47
  --fleet-id: any
  --game-session-id: any
  --alias-id: any
  --location: any
  --status-filter: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<GameSessionDetails: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "GameSessionId": $game_session_id, "AliasId": $alias_id, "Location": $location, "StatusFilter": $status_filter, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information, including current status, about a game session placement request. To get game session placement details, specify the placement ID. This operation is not designed to be continually called to track game session status. This practice can cause you to exceed your API limit, which results in errors. Instead, you must configure configure an Amazon Simple Notification Service (SNS) topic to receive notifications from FlexMatch or queues. Continuously polling with DescribeGameSessionPlacement should only be used for games in development with low game session usage.
#
# POST /
# operationId: DescribeGameSessionPlacement
export def "api get-game-session-placement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48
  placement_id: any
]: any -> record<GameSessionPlacement: record<PlacementId: record, GameSessionQueueName: record, Status: record, GameProperties: record, MaximumPlayerSessionCount: record, GameSessionName: record, GameSessionId: record, GameSessionArn: record, GameSessionRegion: record, PlayerLatencies: record, StartTime: record, EndTime: record, IpAddress: record, DnsName: record, Port: record, PlacedPlayerSessions: record, GameSessionData: record, MatchmakerData: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PlacementId": $placement_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the properties for one or more game session queues. When requesting multiple queues, use the pagination parameters to retrieve results as a set of sequential pages. When specifying a list of queues, objects are returned only for queues that currently exist in the Region. Learn more View Your Queues (https://docs.aws.amazon.com/gamelift/latest/developerguide/queues-console.html)
#
# POST /
# operationId: DescribeGameSessionQueues
export def "api get-game-session-queues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49
  --names: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<GameSessionQueues: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Names": $names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a set of one or more game sessions in a specific fleet location. You can optionally filter the results by current game session status. This operation can be used in the following ways: To retrieve all game sessions that are currently running on all locations in a fleet, provide a fleet or alias ID, with an optional status filter. This approach returns all game sessions in the fleet's home Region and all remote locations. To retrieve all game sessions that are currently running on a specific fleet location, provide a fleet or alias ID and a location name, with optional status filter. The location can be the fleet's home Region or any remote location. To retrieve a specific game session, provide the game session ID. This approach looks for the game session ID in all fleets that reside in the Amazon Web Services Region defined in the request. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a GameSession object is returned for each game session that matches the request. This operation is not designed to be continually called to track game session status. This practice can cause you to exceed your API limit, which results in errors. Instead, you must configure an Amazon Simple Notification Service (SNS) topic to receive notifications from FlexMatch or queues. Continuously polling with DescribeGameSessions should only be used for games in development with low game session usage. Available in Amazon GameLift Local. Learn more Find a game session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-client-api.html#gamelift-sdk-client-api-find) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribeGameSessions
export def "api get-game-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50
  --fleet-id: any
  --game-session-id: any
  --alias-id: any
  --location: any
  --status-filter: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<GameSessions: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "GameSessionId": $game_session_id, "AliasId": $alias_id, "Location": $location, "StatusFilter": $status_filter, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information about a fleet's instances, including instance IDs, connection data, and status. This operation can be used in the following ways: To get information on all instances that are deployed to a fleet's home Region, provide the fleet ID. To get information on all instances that are deployed to a fleet's remote location, provide the fleet ID and location name. To get information on a specific instance in a fleet, provide the fleet ID and instance ID. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, an Instance object is returned for each requested instance. Instances are not returned in any particular order. Learn more Remotely Access Fleet Instances (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-remote-access.html) Debug Fleet Issues (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-debug.html) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribeInstances
export def "api get-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51
  fleet_id: any
  --instance-id: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
  --location: any
]: any -> record<Instances: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "InstanceId": $instance_id, "Limit": $limit_body, "NextToken": $next_token_body, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves one or more matchmaking tickets. Use this operation to retrieve ticket information, including--after a successful match is made--connection information for the resulting new game session. To request matchmaking tickets, provide a list of up to 10 ticket IDs. If the request is successful, a ticket object is returned for each requested ID that currently exists. This operation is not designed to be continually called to track matchmaking ticket status. This practice can cause you to exceed your API limit, which results in errors. Instead, as a best practice, set up an Amazon Simple Notification Service to receive notifications, and provide the topic ARN in the matchmaking configuration. Learn more Add FlexMatch to a game client (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-client.html) Set Up FlexMatch event notification (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-notification.html)
#
# POST /
# operationId: DescribeMatchmaking
export def "api get-matchmaking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-52
  ticket_ids: any
]: any -> record<TicketList: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketIds": $ticket_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the details of FlexMatch matchmaking configurations. This operation offers the following options: (1) retrieve all matchmaking configurations, (2) retrieve configurations for a specified list, or (3) retrieve all configurations that use a specified rule set name. When requesting multiple items, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a configuration is returned for each requested name. When specifying a list of names, only configurations that currently exist are returned. Learn more Setting up FlexMatch matchmakers (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/matchmaker-build.html)
#
# POST /
# operationId: DescribeMatchmakingConfigurations
export def "api get-matchmaking-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53
  --names: any
  --rule-set-name: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<Configurations: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Names": $names, "RuleSetName": $rule_set_name, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the details for FlexMatch matchmaking rule sets. You can request all existing rule sets for the Region, or provide a list of one or more rule set names. When requesting multiple items, use the pagination parameters to retrieve results as a set of sequential pages. If successful, a rule set is returned for each requested name. Learn more Build a rule set (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-rulesets.html)
#
# POST /
# operationId: DescribeMatchmakingRuleSets
export def "api get-matchmaking-rule-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54
  --names: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<RuleSets: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Names": $names, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves properties for one or more player sessions. This action can be used in the following ways: To retrieve a specific player session, provide the player session ID only. To retrieve all player sessions in a game session, provide the game session ID only. To retrieve all player sessions for a specific player, provide a player ID only. To request player sessions, specify either a player session ID, game session ID, or player ID. You can filter this request by player session status. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a PlayerSession object is returned for each session that matches the request. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribePlayerSessions
export def "api get-player-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55
  --game-session-id: any
  --player-id: any
  --player-session-id: any
  --player-session-status-filter: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<PlayerSessions: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"GameSessionId": $game_session_id, "PlayerId": $player_id, "PlayerSessionId": $player_session_id, "PlayerSessionStatusFilter": $player_session_status_filter, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a fleet's runtime configuration settings. The runtime configuration tells Amazon GameLift which server processes to run (and how) on each instance in the fleet. To get the runtime configuration that is currently in forces for a fleet, provide the fleet ID. If successful, a RuntimeConfiguration object is returned for the requested fleet. If the requested fleet has been deleted, the result set is empty. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html) Running multiple processes on a fleet (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-multiprocess.html)
#
# POST /
# operationId: DescribeRuntimeConfiguration
export def "api get-runtime-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-56
  fleet_id: any
]: any -> record<RuntimeConfiguration: record<ServerProcesses: record, MaxConcurrentGameSessionActivations: record, GameSessionActivationTimeoutSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves all scaling policies applied to a fleet. To get a fleet's scaling policies, specify the fleet ID. You can filter this request by policy status, such as to retrieve only active scaling policies. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, set of ScalingPolicy objects is returned for the fleet. A fleet may have all of its scaling policies suspended. This operation does not affect the status of the scaling policies, which remains ACTIVE.
#
# POST /
# operationId: DescribeScalingPolicies
export def "api get-scaling-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57
  fleet_id: any
  --status-filter: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
  --location: any
]: any -> record<ScalingPolicies: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "StatusFilter": $status_filter, "Limit": $limit_body, "NextToken": $next_token_body, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves properties for a Realtime script. To request a script record, specify the script ID. If successful, an object containing the script properties is returned. Learn more Amazon GameLift Realtime Servers (https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribeScript
export def "api get-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-58
  script_id: any
]: any -> record<Script: record<ScriptId: record, ScriptArn: record, Name: record, Version: record, SizeOnDisk: record, CreationTime: record, StorageLocation: record<Bucket: record, Key: record, RoleArn: record, ObjectVersion: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScriptId": $script_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves valid VPC peering authorizations that are pending for the Amazon Web Services account. This operation returns all VPC peering authorizations and requests for peering. This includes those initiated and received by this account. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribeVpcPeeringAuthorizations
export def "api get-vpc-peering-authorizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-59
  --body: record
]: any -> record<VpcPeeringAuthorizations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information on VPC peering connections. Use this operation to get peering information for all fleets or for one specific fleet ID. To retrieve connection information, call this operation from the Amazon Web Services account that is used to manage the Amazon GameLift fleets. Specify a fleet ID or leave the parameter empty to retrieve all connection records. If successful, the retrieved information includes both active and pending connections. Active connections identify the IpV4 CIDR block that the VPC uses to connect. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: DescribeVpcPeeringConnections
export def "api get-vpc-peering-connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-60
  --fleet-id: any
]: any -> record<VpcPeeringConnections: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Requests remote access to a fleet instance. Remote access is useful for debugging, gathering benchmarking data, or observing activity in real time. To remotely access an instance, you need credentials that match the operating system of the instance. For a Windows instance, Amazon GameLift returns a user name and password as strings for use with a Windows Remote Desktop client. For a Linux instance, Amazon GameLift returns a user name and RSA private key, also as strings, for use with an SSH client. The private key must be saved in the proper format to a .pem file before using. If you're making this request using the CLI, saving the secret can be handled as part of the GetInstanceAccess request, as shown in one of the examples for this operation. To request access to a specific instance, specify the IDs of both the instance and the fleet it belongs to. Learn more Remotely Access Fleet Instances (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-remote-access.html) Debug Fleet Issues (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-debug.html)
#
# POST /
# operationId: GetComputeAccess
export def "api get-compute-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-61
  fleet_id: any
  compute_name: any
]: any -> record<FleetId: record, FleetArn: record, ComputeName: record, ComputeArn: record, Credentials: record<AccessKeyId: record, SecretAccessKey: record, SessionToken: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Requests an authentication token from Amazon GameLift. The authentication token is used by your game server to authenticate with Amazon GameLift. Each authentication token has an expiration time. To continue using the compute resource to host your game server, regularly retrieve a new authorization token.
#
# POST /
# operationId: GetComputeAuthToken
export def "api get-compute-auth-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-62
  fleet_id: any
  compute_name: any
]: any -> record<FleetId: record, FleetArn: record, ComputeName: record, ComputeArn: record, AuthToken: record, ExpirationTimestamp: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the location of stored game session logs for a specified game session. When a game session is terminated, Amazon GameLift automatically stores the logs in Amazon S3 and retains them for 14 days. Use this URL to download the logs. See the Amazon Web Services Service Limits (https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_gamelift) page for maximum log file sizes. Log files that exceed this limit are not saved. All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: GetGameSessionLogUrl
export def "api get-game-session-log-url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-63
  game_session_id: any
]: any -> record<PreSignedUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameSessionId": $game_session_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Requests remote access to a fleet instance. Remote access is useful for debugging, gathering benchmarking data, or observing activity in real time. To remotely access an instance, you need credentials that match the operating system of the instance. For a Windows instance, Amazon GameLift returns a user name and password as strings for use with a Windows Remote Desktop client. For a Linux instance, Amazon GameLift returns a user name and RSA private key, also as strings, for use with an SSH client. The private key must be saved in the proper format to a .pem file before using. If you're making this request using the CLI, saving the secret can be handled as part of the GetInstanceAccess request, as shown in one of the examples for this operation. To request access to a specific instance, specify the IDs of both the instance and the fleet it belongs to. You can retrieve a fleet's instance IDs by calling DescribeInstances (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeInstances.html). Learn more Remotely Access Fleet Instances (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-remote-access.html) Debug Fleet Issues (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-debug.html) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: GetInstanceAccess
export def "api get-instance-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-64
  fleet_id: any
  instance_id: any
]: any -> record<InstanceAccess: record<FleetId: record, InstanceId: record, IpAddress: record, OperatingSystem: record, Credentials: record<UserName: record, Secret: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "InstanceId": $instance_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves all aliases for this Amazon Web Services account. You can filter the result set by alias name and/or routing strategy type. Use the pagination parameters to retrieve results in sequential pages. Returned aliases are not listed in any particular order. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: ListAliases
export def "api list-aliases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-65
  --routing-strategy-type: any
  --name: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<Aliases: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"RoutingStrategyType": $routing_strategy_type, "Name": $name, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves build resources for all builds associated with the Amazon Web Services account in use. You can limit results to builds that are in a specific status by using the Status parameter. Use the pagination parameters to retrieve results in a set of sequential pages. Build resources are not listed in any particular order. Learn more Upload a Custom Server Build (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: ListBuilds
export def "api list-builds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-66
  --status: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<Builds: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Status": $status, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves all compute resources registered to a fleet in your Amazon Web Services account. You can filter the result set by location.
#
# POST /
# operationId: ListCompute
export def "api list-compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67
  fleet_id: any
  --location: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<ComputeList: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "Location": $location, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a collection of fleet resources in an Amazon Web Services Region. You can call this operation to get fleets in a previously selected default Region (see https://docs.aws.amazon.com/credref/latest/refdocs/setting-global-region.html (https://docs.aws.amazon.com/credref/latest/refdocs/setting-global-region.html)or specify a Region in your request. You can filter the result set to find only those fleets that are deployed with a specific build or script. For fleets that have multiple locations, this operation retrieves fleets based on their home Region only. This operation can be used in the following ways: To get a list of all fleets in a Region, don't provide a build or script identifier. To get a list of all fleets where a specific custom game build is deployed, provide the build ID. To get a list of all Realtime Servers fleets with a specific configuration script, provide the script ID. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a list of fleet IDs that match the request parameters is returned. A NextToken value is also returned if there are more result pages to retrieve. Fleet resources are not listed in a particular order. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: ListFleets
export def "api list-fleets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68
  --build-id: any
  --script-id: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<FleetIds: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"BuildId": $build_id, "ScriptId": $script_id, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists a game server groups.
#
# POST /
# operationId: ListGameServerGroups
export def "api list-game-server-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-69
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<GameServerGroups: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Retrieves information on all game servers that are currently active in a specified game server group. You can opt to sort the list by game server age. Use the pagination parameters to retrieve results in a set of sequential segments. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: ListGameServers
export def "api list-game-servers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-70
  game_server_group_name: any
  --sort-order: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<GameServers: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "SortOrder": $sort_order, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all custom and Amazon Web Services locations.
#
# POST /
# operationId: ListLocations
export def "api list-locations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-71
  --filters: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<Locations: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves script records for all Realtime scripts that are associated with the Amazon Web Services account in use. Learn more Amazon GameLift Realtime Servers (https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: ListScripts
export def "api list-scripts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-72
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<Scripts: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves all tags assigned to a Amazon GameLift resource. Use resource tags to organize Amazon Web Services resources for a range of purposes. This operation handles the permissions necessary to manage tags for Amazon GameLift resources that support tagging. To list tags for a resource, specify the unique ARN value for the resource. Learn more Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference Amazon Web Services Tagging Strategies (http://aws.amazon.com/answers/account-management/aws-tagging-strategies/) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: ListTagsForResource
export def "api list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-73
  resource_arn: any
]: any -> record<Tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates or updates a scaling policy for a fleet. Scaling policies are used to automatically scale a fleet's hosting capacity to meet player demand. An active scaling policy instructs Amazon GameLift to track a fleet metric and automatically change the fleet's capacity when a certain threshold is reached. There are two types of scaling policies: target-based and rule-based. Use a target-based policy to quickly and efficiently manage fleet scaling; this option is the most commonly used. Use rule-based policies when you need to exert fine-grained control over auto-scaling. Fleets can have multiple scaling policies of each type in force at the same time; you can have one target-based policy, one or multiple rule-based scaling policies, or both. We recommend caution, however, because multiple auto-scaling policies can have unintended consequences. Learn more about how to work with auto-scaling in Set Up Fleet Automatic Scaling (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-autoscaling.html). Target-based policy A target-based policy tracks a single metric: PercentAvailableGameSessions. This metric tells us how much of a fleet's hosting capacity is ready to host game sessions but is not currently in use. This is the fleet's buffer; it measures the additional player demand that the fleet could handle at current capacity. With a target-based policy, you set your ideal buffer size and leave it to Amazon GameLift to take whatever action is needed to maintain that target. For example, you might choose to maintain a 10% buffer for a fleet that has the capacity to host 100 simultaneous game sessions. This policy tells Amazon GameLift to take action whenever the fleet's available capacity falls below or rises above 10 game sessions. Amazon GameLift will start new instances or stop unused instances in order to return to the 10% buffer. To create or update a target-based policy, specify a fleet ID and name, and set the policy type to "TargetBased". Specify the metric to track (PercentAvailableGameSessions) and reference a TargetConfiguration object with your desired buffer value. Exclude all other parameters. On a successful request, the policy name is returned. The scaling policy is automatically in force as soon as it's successfully created. If the fleet's auto-scaling actions are temporarily suspended, the new policy will be in force once the fleet actions are restarted. Rule-based policy A rule-based policy tracks specified fleet metric, sets a threshold value, and specifies the type of action to initiate when triggered. With a rule-based policy, you can select from several available fleet metrics. Each policy specifies whether to scale up or scale down (and by how much), so you need one policy for each type of action. For example, a policy may make the following statement: "If the percentage of idle instances is greater than 20% for more than 15 minutes, then reduce the fleet capacity by 10%." A policy's rule statement has the following structure: If [MetricName] is [ComparisonOperator] [Threshold] for [EvaluationPeriods] minutes, then [ScalingAdjustmentType] to/by [ScalingAdjustment]. To implement the example, the rule statement would look like this: If [PercentIdleInstances] is [GreaterThanThreshold] [20] for [15] minutes, then [PercentChangeInCapacity] to/by [10]. To create or update a scaling policy, specify a unique combination of name and fleet ID, and set the policy type to "RuleBased". Specify the parameter values for a policy rule statement. On a successful request, the policy name is returned. Scaling policies are automatically in force as soon as they're successfully created. If the fleet's auto-scaling actions are temporarily suspended, the new policy will be in force once the fleet actions are restarted.
#
# POST /
# operationId: PutScalingPolicy
export def "api update-scaling-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-74
  name: any
  fleet_id: any
  --scaling-adjustment: any
  --scaling-adjustment-type: any
  --threshold: any
  --comparison-operator: any
  --evaluation-periods: any
  metric_name: any
  --policy-type: any
  --target-configuration: any
]: any -> record<Name: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "FleetId": $fleet_id, "ScalingAdjustment": $scaling_adjustment, "ScalingAdjustmentType": $scaling_adjustment_type, "Threshold": $threshold, "ComparisonOperator": $comparison_operator, "EvaluationPeriods": $evaluation_periods, "MetricName": $metric_name, "PolicyType": $policy_type, "TargetConfiguration": $target_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Registers your compute resources in a fleet you previously created. After you register a compute to your fleet, you can monitor and manage your compute using Amazon GameLift. The operation returns the compute resource containing SDK endpoint you can use to connect your game server to Amazon GameLift. Learn more Create an Anywhere fleet (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-creating-anywhere.html) Test your integration (https://docs.aws.amazon.com/gamelift/latest/developerguide/integration-testing.html)
#
# POST /
# operationId: RegisterCompute
export def "api create-compute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-75
  fleet_id: any
  compute_name: any
  --certificate-path: any
  --dns-name: any
  --ip-address: any
  --location: any
]: any -> record<Compute: record<FleetId: record, FleetArn: record, ComputeName: record, ComputeArn: record, IpAddress: record, DnsName: record, ComputeStatus: record, Location: record, CreationTime: record, OperatingSystem: record, Type: record, GameLiftServiceSdkEndpoint: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name, "CertificatePath": $certificate_path, "DnsName": $dns_name, "IpAddress": $ip_address, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Creates a new game server resource and notifies Amazon GameLift FleetIQ that the game server is ready to host gameplay and players. This operation is called by a game server process that is running on an instance in a game server group. Registering game servers enables Amazon GameLift FleetIQ to track available game servers and enables game clients and services to claim a game server for a new game session. To register a game server, identify the game server group and instance where the game server is running, and provide a unique identifier for the game server. You can also include connection and game server data. Once a game server is successfully registered, it is put in status AVAILABLE. A request to register a game server may fail if the instance it is running on is in the process of shutting down as part of instance balancing or scale-down activity. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: RegisterGameServer
export def "api create-game-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-76
  game_server_group_name: any
  game_server_id: any
  instance_id: any
  --connection-info: any
  --game-server-data: any
]: any -> record<GameServer: record<GameServerGroupName: record, GameServerGroupArn: record, GameServerId: record, InstanceId: record, ConnectionInfo: record, GameServerData: record, ClaimStatus: record, UtilizationStatus: record, RegistrationTime: record, LastClaimTime: record, LastHealthCheckTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id, "InstanceId": $instance_id, "ConnectionInfo": $connection_info, "GameServerData": $game_server_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a fresh set of credentials for use when uploading a new set of game build files to Amazon GameLift's Amazon S3. This is done as part of the build creation process; see GameSession (https://docs.aws.amazon.com/gamelift/latest/apireference/API_CreateBuild.html). To request new credentials, specify the build ID as returned with an initial CreateBuild request. If successful, a new set of credentials are returned, along with the S3 storage location associated with the build ID. Learn more Create a Build with Files in S3 (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-cli-uploading.html#gamelift-build-cli-uploading-create-build) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: RequestUploadCredentials
export def "api request-upload-credentials" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-77
  build_id: any
]: any -> record<UploadCredentials: record<AccessKeyId: record, SecretAccessKey: record, SessionToken: record>, StorageLocation: record<Bucket: record, Key: record, RoleArn: record, ObjectVersion: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BuildId": $build_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the fleet ID that an alias is currently pointing to. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: ResolveAlias
export def "api create-resolve-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-78
  alias_id: any
]: any -> record<FleetId: record, FleetArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AliasId": $alias_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Reinstates activity on a game server group after it has been suspended. A game server group might be suspended by the SuspendGameServerGroup (gamelift/latest/apireference/API_SuspendGameServerGroup.html) operation, or it might be suspended involuntarily due to a configuration problem. In the second case, you can manually resume activity on the group once the configuration problem has been resolved. Refer to the game server group status and status reason for more information on why group activity is suspended. To resume activity, specify a game server group ARN and the type of activity to be resumed. If successful, a GameServerGroup object is returned showing that the resumed activity is no longer listed in SuspendedActions. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: ResumeGameServerGroup
export def "api create-resume-game-server-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-79
  game_server_group_name: any
  resume_actions: any
]: any -> record<GameServerGroup: record<GameServerGroupName: record, GameServerGroupArn: record, RoleArn: record, InstanceDefinitions: record, BalancingStrategy: record, GameServerProtectionPolicy: record, AutoScalingGroupArn: record, Status: record, StatusReason: record, SuspendedActions: record, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "ResumeActions": $resume_actions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves all active game sessions that match a set of search criteria and sorts them into a specified order. This operation is not designed to be continually called to track game session status. This practice can cause you to exceed your API limit, which results in errors. Instead, you must configure configure an Amazon Simple Notification Service (SNS) topic to receive notifications from FlexMatch or queues. Continuously polling game session status with DescribeGameSessions should only be used for games in development with low game session usage. When searching for game sessions, you specify exactly where you want to search and provide a search filter expression, a sort expression, or both. A search request can search only one fleet, but it can search all of a fleet's locations. This operation can be used in the following ways: To search all game sessions that are currently running on all locations in a fleet, provide a fleet or alias ID. This approach returns game sessions in the fleet's home Region and all remote locations that fit the search criteria. To search all game sessions that are currently running on a specific fleet location, provide a fleet or alias ID and a location name. For location, you can specify a fleet's home Region or any remote location. Use the pagination parameters to retrieve results as a set of sequential pages. If successful, a GameSession object is returned for each game session that matches the request. Search finds game sessions that are in ACTIVE status only. To retrieve information on game sessions in other statuses, use DescribeGameSessions (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeGameSessions.html) . You can search or sort by the following game session attributes: gameSessionId -- A unique identifier for the game session. You can use either a GameSessionId or GameSessionArn value. gameSessionName -- Name assigned to a game session. Game session names do not need to be unique to a game session. gameSessionProperties -- Custom data defined in a game session's GameProperty parameter. GameProperty values are stored as key:value pairs; the filter expression must indicate the key and a string to search the data values for. For example, to search for game sessions with custom data containing the key:value pair "gameMode:brawl", specify the following: gameSessionProperties.gameMode = "brawl". All custom data values are searched as strings. maximumSessions -- Maximum number of player sessions allowed for a game session. creationTimeMillis -- Value indicating when a game session was created. It is expressed in Unix time as milliseconds. playerSessionCount -- Number of players currently connected to a game session. This value changes rapidly as players join the session or drop out. hasAvailablePlayerSessions -- Boolean value indicating whether a game session has reached its maximum number of players. It is highly recommended that all search requests include this filter attribute to optimize search performance and return only sessions that players can join. Returned values for playerSessionCount and hasAvailablePlayerSessions change quickly as players join sessions and others drop out. Results should be considered a snapshot in time. Be sure to refresh search results often, and handle sessions that fill up before a player can join. All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: SearchGameSessions
export def "api list-game-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-80
  --fleet-id: any
  --alias-id: any
  --location: any
  --filter-expression: any
  --sort-expression: any
  --limit-body: any #  (body field)
  --next-token-body: any #  (body field)
]: any -> record<GameSessions: record, NextToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "AliasId": $alias_id, "Location": $location, "FilterExpression": $filter_expression, "SortExpression": $sort_expression, "Limit": $limit_body, "NextToken": $next_token_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Limit": $limit, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Resumes certain types of activity on fleet instances that were suspended with StopFleetActions (https://docs.aws.amazon.com/gamelift/latest/apireference/API_StopFleetActions.html). For multi-location fleets, fleet actions are managed separately for each location. Currently, this operation is used to restart a fleet's auto-scaling activity. This operation can be used in the following ways: To restart actions on instances in the fleet's home Region, provide a fleet ID and the type of actions to resume. To restart actions on instances in one of the fleet's remote locations, provide a fleet ID, a location name, and the type of actions to resume. If successful, Amazon GameLift once again initiates scaling events as triggered by the fleet's scaling policies. If actions on the fleet location were never stopped, this operation will have no effect. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: StartFleetActions
export def "api start-fleet-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-81
  fleet_id: any
  actions: any
  --location: any
]: any -> record<FleetId: record, FleetArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Actions": $actions, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Places a request for a new game session in a queue. When processing a placement request, Amazon GameLift searches for available resources on the queue's destinations, scanning each until it finds resources or the placement request times out. A game session placement request can also request player sessions. When a new game session is successfully created, Amazon GameLift creates a player session for each player included in the request. When placing a game session, by default Amazon GameLift tries each fleet in the order they are listed in the queue configuration. Ideally, a queue's destinations are listed in preference order. Alternatively, when requesting a game session with players, you can also provide latency data for each player in relevant Regions. Latency data indicates the performance lag a player experiences when connected to a fleet in the Region. Amazon GameLift uses latency data to reorder the list of destinations to place the game session in a Region with minimal lag. If latency data is provided for multiple players, Amazon GameLift calculates each Region's average lag for all players and reorders to get the best game play across all players. To place a new game session request, specify the following: The queue name and a set of game session properties and settings A unique ID (such as a UUID) for the placement. You use this ID to track the status of the placement request (Optional) A set of player data and a unique player ID for each player that you are joining to the new game session (player data is optional, but if you include it, you must also provide a unique ID for each player) Latency data for all players (if you want to optimize game play for the players) If successful, a new game session placement is created. To track the status of a placement request, call DescribeGameSessionPlacement (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeGameSessionPlacement.html) and check the request's status. If the status is FULFILLED, a new game session has been created and a game session ARN and Region are referenced. If the placement request times out, you can resubmit the request or retry it with a different queue.
#
# POST /
# operationId: StartGameSessionPlacement
export def "api start-game-session-placement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-82
  placement_id: any
  game_session_queue_name: any
  --game-properties: any
  maximum_player_session_count: any
  --game-session-name: any
  --player-latencies: any
  --desired-player-sessions: any
  --game-session-data: any
]: any -> record<GameSessionPlacement: record<PlacementId: record, GameSessionQueueName: record, Status: record, GameProperties: record, MaximumPlayerSessionCount: record, GameSessionName: record, GameSessionId: record, GameSessionArn: record, GameSessionRegion: record, PlayerLatencies: record, StartTime: record, EndTime: record, IpAddress: record, DnsName: record, Port: record, PlacedPlayerSessions: record, GameSessionData: record, MatchmakerData: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PlacementId": $placement_id, "GameSessionQueueName": $game_session_queue_name, "GameProperties": $game_properties, "MaximumPlayerSessionCount": $maximum_player_session_count, "GameSessionName": $game_session_name, "PlayerLatencies": $player_latencies, "DesiredPlayerSessions": $desired_player_sessions, "GameSessionData": $game_session_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Finds new players to fill open slots in currently running game sessions. The backfill match process is essentially identical to the process of forming new matches. Backfill requests use the same matchmaker that was used to make the original match, and they provide matchmaking data for all players currently in the game session. FlexMatch uses this information to select new players so that backfilled match continues to meet the original match requirements. When using FlexMatch with Amazon GameLift managed hosting, you can request a backfill match from a client service by calling this operation with a GameSessions ID. You also have the option of making backfill requests directly from your game server. In response to a request, FlexMatch creates player sessions for the new players, updates the GameSession resource, and sends updated matchmaking data to the game server. You can request a backfill match at any point after a game session is started. Each game session can have only one active backfill request at a time; a subsequent request automatically replaces the earlier request. When using FlexMatch as a standalone component, request a backfill match by calling this operation without a game session identifier. As with newly formed matches, matchmaking results are returned in a matchmaking event so that your game can update the game session that is being backfilled. To request a backfill match, specify a unique ticket ID, the original matchmaking configuration, and matchmaking data for all current players in the game session being backfilled. Optionally, specify the GameSession ARN. If successful, a match backfill ticket is created and returned with status set to QUEUED. Track the status of backfill tickets using the same method for tracking tickets for new matches. Only game sessions created by FlexMatch are supported for match backfill. Learn more Backfill existing games with FlexMatch (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-backfill.html) Matchmaking events (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-events.html) (reference) How Amazon GameLift FlexMatch works (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/gamelift-match.html)
#
# POST /
# operationId: StartMatchBackfill
export def "api start-match-backfill" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-83
  --ticket-id: any
  configuration_name: any
  --game-session-arn: any
  players: any
]: any -> record<MatchmakingTicket: record<TicketId: record, ConfigurationName: record, ConfigurationArn: record, Status: record, StatusReason: record, StatusMessage: record, StartTime: record, EndTime: record, Players: record, GameSessionConnectionInfo: record<GameSessionArn: record, IpAddress: record, DnsName: record, Port: record, MatchedPlayerSessions: record>, EstimatedWaitTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketId": $ticket_id, "ConfigurationName": $configuration_name, "GameSessionArn": $game_session_arn, "Players": $players} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Uses FlexMatch to create a game match for a group of players based on custom matchmaking rules. With games that use Amazon GameLift managed hosting, this operation also triggers Amazon GameLift to find hosting resources and start a new game session for the new match. Each matchmaking request includes information on one or more players and specifies the FlexMatch matchmaker to use. When a request is for multiple players, FlexMatch attempts to build a match that includes all players in the request, placing them in the same team and finding additional players as needed to fill the match. To start matchmaking, provide a unique ticket ID, specify a matchmaking configuration, and include the players to be matched. You must also include any player attributes that are required by the matchmaking configuration's rule set. If successful, a matchmaking ticket is returned with status set to QUEUED. Track matchmaking events to respond as needed and acquire game session connection information for successfully completed matches. Ticket status updates are tracked using event notification through Amazon Simple Notification Service, which is defined in the matchmaking configuration. Learn more Add FlexMatch to a game client (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-client.html) Set Up FlexMatch event notification (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-notification.html) How Amazon GameLift FlexMatch works (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/gamelift-match.html)
#
# POST /
# operationId: StartMatchmaking
export def "api start-matchmaking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-84
  --ticket-id: any
  configuration_name: any
  players: any
]: any -> record<MatchmakingTicket: record<TicketId: record, ConfigurationName: record, ConfigurationArn: record, Status: record, StatusReason: record, StatusMessage: record, StartTime: record, EndTime: record, Players: record, GameSessionConnectionInfo: record<GameSessionArn: record, IpAddress: record, DnsName: record, Port: record, MatchedPlayerSessions: record>, EstimatedWaitTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketId": $ticket_id, "ConfigurationName": $configuration_name, "Players": $players} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Suspends certain types of activity in a fleet location. Currently, this operation is used to stop auto-scaling activity. For multi-location fleets, fleet actions are managed separately for each location. Stopping fleet actions has several potential purposes. It allows you to temporarily stop auto-scaling activity but retain your scaling policies for use in the future. For multi-location fleets, you can set up fleet-wide auto-scaling, and then opt out of it for certain locations. This operation can be used in the following ways: To stop actions on instances in the fleet's home Region, provide a fleet ID and the type of actions to suspend. To stop actions on instances in one of the fleet's remote locations, provide a fleet ID, a location name, and the type of actions to suspend. If successful, Amazon GameLift no longer initiates scaling events except in response to manual changes using UpdateFleetCapacity (https://docs.aws.amazon.com/gamelift/latest/apireference/API_UpdateFleetCapacity.html). Learn more Setting up Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: StopFleetActions
export def "api stop-fleet-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-85
  fleet_id: any
  actions: any
  --location: any
]: any -> record<FleetId: record, FleetArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Actions": $actions, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancels a game session placement that is in PENDING status. To stop a placement, provide the placement ID values. If successful, the placement is moved to CANCELLED status.
#
# POST /
# operationId: StopGameSessionPlacement
export def "api stop-game-session-placement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-86
  placement_id: any
]: any -> record<GameSessionPlacement: record<PlacementId: record, GameSessionQueueName: record, Status: record, GameProperties: record, MaximumPlayerSessionCount: record, GameSessionName: record, GameSessionId: record, GameSessionArn: record, GameSessionRegion: record, PlayerLatencies: record, StartTime: record, EndTime: record, IpAddress: record, DnsName: record, Port: record, PlacedPlayerSessions: record, GameSessionData: record, MatchmakerData: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PlacementId": $placement_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancels a matchmaking ticket or match backfill ticket that is currently being processed. To stop the matchmaking operation, specify the ticket ID. If successful, work on the ticket is stopped, and the ticket status is changed to CANCELLED. This call is also used to turn off automatic backfill for an individual game session. This is for game sessions that are created with a matchmaking configuration that has automatic backfill enabled. The ticket ID is included in the MatchmakerData of an updated game session object, which is provided to the game server. If the operation is successful, the service sends back an empty JSON struct with the HTTP 200 response (not an empty HTTP body). Learn more Add FlexMatch to a game client (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-client.html)
#
# POST /
# operationId: StopMatchmaking
export def "api stop-matchmaking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-87
  ticket_id: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketId": $ticket_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Temporarily stops activity on a game server group without terminating instances or the game server group. You can restart activity by calling ResumeGameServerGroup (gamelift/latest/apireference/API_ResumeGameServerGroup.html). You can suspend the following activity: Instance type replacement - This activity evaluates the current game hosting viability of all Spot instance types that are defined for the game server group. It updates the Auto Scaling group to remove nonviable Spot Instance types, which have a higher chance of game server interruptions. It then balances capacity across the remaining viable Spot Instance types. When this activity is suspended, the Auto Scaling group continues with its current balance, regardless of viability. Instance protection, utilization metrics, and capacity scaling activities continue to be active. To suspend activity, specify a game server group ARN and the type of activity to be suspended. If successful, a GameServerGroup object is returned showing that the activity is listed in SuspendedActions. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: SuspendGameServerGroup
export def "api create-suspend-game-server-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-88
  game_server_group_name: any
  suspend_actions: any
]: any -> record<GameServerGroup: record<GameServerGroupName: record, GameServerGroupArn: record, RoleArn: record, InstanceDefinitions: record, BalancingStrategy: record, GameServerProtectionPolicy: record, AutoScalingGroupArn: record, Status: record, StatusReason: record, SuspendedActions: record, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "SuspendActions": $suspend_actions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Assigns a tag to an Amazon GameLift resource. You can use tags to organize resources, create IAM permissions policies to manage access to groups of resources, customize Amazon Web Services cost breakdowns, and more. This operation handles the permissions necessary to manage tags for Amazon GameLift resources that support tagging. To add a tag to a resource, specify the unique ARN value for the resource and provide a tag list containing one or more tags. The operation succeeds even if the list includes tags that are already assigned to the resource. Learn more Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference Amazon Web Services Tagging Strategies (http://aws.amazon.com/answers/account-management/aws-tagging-strategies/) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: TagResource
export def "api tag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-89
  resource_arn: any
  tags: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "Tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes a tag assigned to a Amazon GameLift resource. You can use resource tags to organize Amazon Web Services resources for a range of purposes. This operation handles the permissions necessary to manage tags for Amazon GameLift resources that support tagging. To remove a tag from a resource, specify the unique ARN value for the resource and provide a string list containing one or more tags to remove. This operation succeeds even if the list includes tags that aren't assigned to the resource. Learn more Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference Amazon Web Services Tagging Strategies (http://aws.amazon.com/answers/account-management/aws-tagging-strategies/) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: UntagResource
export def "api untag-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-90
  resource_arn: any
  tag_keys: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates properties for an alias. To update properties, specify the alias ID to be updated and provide the information to be changed. To reassign an alias to another fleet, provide an updated routing strategy. If successful, the updated alias record is returned. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: UpdateAlias
export def "api update-alias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-91
  alias_id: any
  --name: any
  --description: any
  --routing-strategy: any
]: any -> record<Alias: record<AliasId: record, Name: record, AliasArn: record, Description: record, RoutingStrategy: record<Type: record, FleetId: record, Message: record>, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AliasId": $alias_id, "Name": $name, "Description": $description, "RoutingStrategy": $routing_strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates metadata in a build resource, including the build name and version. To update the metadata, specify the build ID to update and provide the new values. If successful, a build object containing the updated metadata is returned. Learn more Upload a Custom Server Build (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-build-intro.html) All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: UpdateBuild
export def "api update-build" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-92
  build_id: any
  --name: any
  --version: any
]: any -> record<Build: record<BuildId: record, BuildArn: record, Name: record, Version: record, Status: record, SizeOnDisk: record, OperatingSystem: record, CreationTime: record, ServerSdkVersion: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BuildId": $build_id, "Name": $name, "Version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates a fleet's mutable attributes, including game session protection and resource creation limits. To update fleet attributes, specify the fleet ID and the property values that you want to change. If successful, an updated FleetAttributes object is returned. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: UpdateFleetAttributes
export def "api update-fleet-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-93
  fleet_id: any
  --name: any
  --description: any
  --new-game-session-protection-policy: any
  --resource-creation-limit-policy: any
  --metric-groups: any
  --anywhere-configuration: any
]: any -> record<FleetId: record, FleetArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Name": $name, "Description": $description, "NewGameSessionProtectionPolicy": $new_game_session_protection_policy, "ResourceCreationLimitPolicy": $resource_creation_limit_policy, "MetricGroups": $metric_groups, "AnywhereConfiguration": $anywhere_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates capacity settings for a fleet. For fleets with multiple locations, use this operation to manage capacity settings in each location individually. Fleet capacity determines the number of game sessions and players that can be hosted based on the fleet configuration. Use this operation to set the following fleet capacity properties: Minimum/maximum size: Set hard limits on fleet capacity. Amazon GameLift cannot set the fleet's capacity to a value outside of this range, whether the capacity is changed manually or through automatic scaling. Desired capacity: Manually set the number of Amazon EC2 instances to be maintained in a fleet location. Before changing a fleet's desired capacity, you may want to call DescribeEC2InstanceLimits (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeEC2InstanceLimits.html) to get the maximum capacity of the fleet's Amazon EC2 instance type. Alternatively, consider using automatic scaling to adjust capacity based on player demand. This operation can be used in the following ways: To update capacity for a fleet's home Region, or if the fleet has no remote locations, omit the Location parameter. The fleet must be in ACTIVE status. To update capacity for a fleet's remote location, include the Location parameter set to the location to be updated. The location must be in ACTIVE status. If successful, capacity settings are updated immediately. In response a change in desired capacity, Amazon GameLift initiates steps to start new instances or terminate existing instances in the requested fleet location. This continues until the location's active instance count matches the new desired instance count. You can track a fleet's current capacity by calling DescribeFleetCapacity (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeFleetCapacity.html) or DescribeFleetLocationCapacity (https://docs.aws.amazon.com/gamelift/latest/apireference/API_DescribeFleetLocationCapacity.html). If the requested desired instance count is higher than the instance type's limit, the LimitExceeded exception occurs. Learn more Scaling fleet capacity (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-manage-capacity.html)
#
# POST /
# operationId: UpdateFleetCapacity
export def "api update-fleet-capacity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-94
  fleet_id: any
  --desired-instances: any
  --min-size: any
  --max-size: any
  --location: any
]: any -> record<FleetId: record, FleetArn: record, Location: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "DesiredInstances": $desired_instances, "MinSize": $min_size, "MaxSize": $max_size, "Location": $location} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates permissions that allow inbound traffic to connect to game sessions that are being hosted on instances in the fleet. To update settings, specify the fleet ID to be updated and specify the changes to be made. List the permissions you want to add in InboundPermissionAuthorizations, and permissions you want to remove in InboundPermissionRevocations. Permissions to be removed must match existing fleet permissions. If successful, the fleet ID for the updated fleet is returned. For fleets with remote locations, port setting updates can take time to propagate across all locations. You can check the status of updates in each location by calling DescribeFleetPortSettings with a location name. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: UpdateFleetPortSettings
export def "api update-fleet-port-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-95
  fleet_id: any
  --inbound-permission-authorizations: any
  --inbound-permission-revocations: any
]: any -> record<FleetId: record, FleetArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "InboundPermissionAuthorizations": $inbound_permission_authorizations, "InboundPermissionRevocations": $inbound_permission_revocations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Updates information about a registered game server to help Amazon GameLift FleetIQ to track game server availability. This operation is called by a game server process that is running on an instance in a game server group. Use this operation to update the following types of game server information. You can make all three types of updates in the same request: To update the game server's utilization status, identify the game server and game server group and specify the current utilization status. Use this status to identify when game servers are currently hosting games and when they are available to be claimed. To report health status, identify the game server and game server group and set health check to HEALTHY. If a game server does not report health status for a certain length of time, the game server is no longer considered healthy. As a result, it will be eventually deregistered from the game server group to avoid affecting utilization metrics. The best practice is to report health every 60 seconds. To change game server metadata, provide updated game server data. Once a game server is successfully updated, the relevant statuses and timestamps are updated. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: UpdateGameServer
export def "api update-game-server" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-96
  game_server_group_name: any
  game_server_id: any
  --game-server-data: any
  --utilization-status: any
  --health-check: any
]: any -> record<GameServer: record<GameServerGroupName: record, GameServerGroupArn: record, GameServerId: record, InstanceId: record, ConnectionInfo: record, GameServerData: record, ClaimStatus: record, UtilizationStatus: record, RegistrationTime: record, LastClaimTime: record, LastHealthCheckTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id, "GameServerData": $game_server_data, "UtilizationStatus": $utilization_status, "HealthCheck": $health_check} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# This operation is used with the Amazon GameLift FleetIQ solution and game server groups. Updates Amazon GameLift FleetIQ-specific properties for a game server group. Many Auto Scaling group properties are updated on the Auto Scaling group directly, including the launch template, Auto Scaling policies, and maximum/minimum/desired instance counts. To update the game server group, specify the game server group ID and provide the updated values. Before applying the updates, the new values are validated to ensure that Amazon GameLift FleetIQ can continue to perform instance balancing activity. If successful, a GameServerGroup object is returned. Learn more Amazon GameLift FleetIQ Guide (https://docs.aws.amazon.com/gamelift/latest/fleetiqguide/gsg-intro.html)
#
# POST /
# operationId: UpdateGameServerGroup
export def "api update-game-server-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-97
  game_server_group_name: any
  --role-arn: any
  --instance-definitions: any
  --game-server-protection-policy: any
  --balancing-strategy: any
]: any -> record<GameServerGroup: record<GameServerGroupName: record, GameServerGroupArn: record, RoleArn: record, InstanceDefinitions: record, BalancingStrategy: record, GameServerProtectionPolicy: record, AutoScalingGroupArn: record, Status: record, StatusReason: record, SuspendedActions: record, CreationTime: record, LastUpdatedTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "RoleArn": $role_arn, "InstanceDefinitions": $instance_definitions, "GameServerProtectionPolicy": $game_server_protection_policy, "BalancingStrategy": $balancing_strategy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the mutable properties of a game session. To update a game session, specify the game session ID and the values you want to change. If successful, the updated GameSession object is returned. All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: UpdateGameSession
export def "api update-game-session" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-98
  game_session_id: any
  --maximum-player-session-count: any
  --name: any
  --player-session-creation-policy: any
  --protection-policy: any
]: any -> record<GameSession: record<GameSessionId: record, Name: record, FleetId: record, FleetArn: record, CreationTime: record, TerminationTime: record, CurrentPlayerSessionCount: record, MaximumPlayerSessionCount: record, Status: record, StatusReason: record, GameProperties: record, IpAddress: record, DnsName: record, Port: record, PlayerSessionCreationPolicy: record, CreatorId: record, GameSessionData: record, MatchmakerData: record, Location: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameSessionId": $game_session_id, "MaximumPlayerSessionCount": $maximum_player_session_count, "Name": $name, "PlayerSessionCreationPolicy": $player_session_creation_policy, "ProtectionPolicy": $protection_policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the configuration of a game session queue, which determines how the queue processes new game session requests. To update settings, specify the queue name to be updated and provide the new settings. When updating destinations, provide a complete list of destinations. Learn more Using Multi-Region Queues (https://docs.aws.amazon.com/gamelift/latest/developerguide/queues-intro.html)
#
# POST /
# operationId: UpdateGameSessionQueue
export def "api update-game-session-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-99
  name: any
  --timeout-in-seconds: any
  --player-latency-policies: any
  --destinations: any
  --filter-configuration: any
  --priority-configuration: any
  --custom-event-data: any
  --notification-target: any
]: any -> record<GameSessionQueue: record<Name: record, GameSessionQueueArn: record, TimeoutInSeconds: record, PlayerLatencyPolicies: record, Destinations: record, FilterConfiguration: record<AllowedLocations: record>, PriorityConfiguration: record<PriorityOrder: record, LocationOrder: record>, CustomEventData: record, NotificationTarget: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "TimeoutInSeconds": $timeout_in_seconds, "PlayerLatencyPolicies": $player_latency_policies, "Destinations": $destinations, "FilterConfiguration": $filter_configuration, "PriorityConfiguration": $priority_configuration, "CustomEventData": $custom_event_data, "NotificationTarget": $notification_target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates settings for a FlexMatch matchmaking configuration. These changes affect all matches and game sessions that are created after the update. To update settings, specify the configuration name to be updated and provide the new settings. Learn more Design a FlexMatch matchmaker (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-configuration.html)
#
# POST /
# operationId: UpdateMatchmakingConfiguration
export def "api update-matchmaking-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-100
  name: any
  --description: any
  --game-session-queue-arns: any
  --request-timeout-seconds: any
  --acceptance-timeout-seconds: any
  --acceptance-required: any
  --rule-set-name: any
  --notification-target: any
  --additional-player-count: any
  --custom-event-data: any
  --game-properties: any
  --game-session-data: any
  --backfill-mode: any
  --flex-match-mode: any
]: any -> record<Configuration: record<Name: record, ConfigurationArn: record, Description: record, GameSessionQueueArns: record, RequestTimeoutSeconds: record, AcceptanceTimeoutSeconds: record, AcceptanceRequired: record, RuleSetName: record, RuleSetArn: record, NotificationTarget: record, AdditionalPlayerCount: record, CustomEventData: record, CreationTime: record, GameProperties: record, GameSessionData: record, BackfillMode: record, FlexMatchMode: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "GameSessionQueueArns": $game_session_queue_arns, "RequestTimeoutSeconds": $request_timeout_seconds, "AcceptanceTimeoutSeconds": $acceptance_timeout_seconds, "AcceptanceRequired": $acceptance_required, "RuleSetName": $rule_set_name, "NotificationTarget": $notification_target, "AdditionalPlayerCount": $additional_player_count, "CustomEventData": $custom_event_data, "GameProperties": $game_properties, "GameSessionData": $game_session_data, "BackfillMode": $backfill_mode, "FlexMatchMode": $flex_match_mode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates the current runtime configuration for the specified fleet, which tells Amazon GameLift how to launch server processes on all instances in the fleet. You can update a fleet's runtime configuration at any time after the fleet is created; it does not need to be in ACTIVE status. To update runtime configuration, specify the fleet ID and provide a RuntimeConfiguration with an updated set of server process configurations. If successful, the fleet's runtime configuration settings are updated. Each instance in the fleet regularly checks for and retrieves updated runtime configurations. Instances immediately begin complying with the new configuration by launching new server processes or not replacing existing processes when they shut down. Updating a fleet's runtime configuration never affects existing server processes. Learn more Setting up Amazon GameLift fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-intro.html)
#
# POST /
# operationId: UpdateRuntimeConfiguration
export def "api update-runtime-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-101
  fleet_id: any
  runtime_configuration: any
]: any -> record<RuntimeConfiguration: record<ServerProcesses: record, MaxConcurrentGameSessionActivations: record, GameSessionActivationTimeoutSeconds: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "RuntimeConfiguration": $runtime_configuration} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Updates Realtime script metadata and content. To update script metadata, specify the script ID and provide updated name and/or version values. To update script content, provide an updated zip file by pointing to either a local file or an Amazon S3 bucket location. You can use either method regardless of how the original script was uploaded. Use the Version parameter to track updates to the script. If the call is successful, the updated metadata is stored in the script record and a revised script is uploaded to the Amazon GameLift service. Once the script is updated and acquired by a fleet instance, the new version is used for all new game sessions. Learn more Amazon GameLift Realtime Servers (https://docs.aws.amazon.com/gamelift/latest/developerguide/realtime-intro.html) Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets)
#
# POST /
# operationId: UpdateScript
export def "api update-script" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-102
  script_id: any
  --name: any
  --version: any
  --storage-location: any
  --zip-file: any
]: any -> record<Script: record<ScriptId: record, ScriptArn: record, Name: record, Version: record, SizeOnDisk: record, CreationTime: record, StorageLocation: record<Bucket: record, Key: record, RoleArn: record, ObjectVersion: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScriptId": $script_id, "Name": $name, "Version": $version, "StorageLocation": $storage_location, "ZipFile": $zip_file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Validates the syntax of a matchmaking rule or rule set. This operation checks that the rule set is using syntactically correct JSON and that it conforms to allowed property expressions. To validate syntax, provide a rule set JSON string. Learn more Build a rule set (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-rulesets.html)
#
# POST /
# operationId: ValidateMatchmakingRuleSet
export def "api validate-matchmaking-rule-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-103
  rule_set_body: any
]: any -> record<Valid: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleSetBody": $rule_set_body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
