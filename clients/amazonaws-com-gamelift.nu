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
    "bearer" => { {scheme: $scheme, headers: {"Authorization": $"Bearer ($token_val)"}, query: "", location: "header"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://gamelift.us-east-1.amazonaws.com" "http://gamelift.us-east-2.amazonaws.com" "http://gamelift.us-west-1.amazonaws.com" "http://gamelift.us-west-2.amazonaws.com" "http://gamelift.us-gov-west-1.amazonaws.com" "http://gamelift.us-gov-east-1.amazonaws.com" "http://gamelift.ca-central-1.amazonaws.com" "http://gamelift.eu-north-1.amazonaws.com" "http://gamelift.eu-west-1.amazonaws.com" "http://gamelift.eu-west-2.amazonaws.com" "http://gamelift.eu-west-3.amazonaws.com" "http://gamelift.eu-central-1.amazonaws.com" "http://gamelift.eu-south-1.amazonaws.com" "http://gamelift.af-south-1.amazonaws.com" "http://gamelift.ap-northeast-1.amazonaws.com" "http://gamelift.ap-northeast-2.amazonaws.com" "http://gamelift.ap-northeast-3.amazonaws.com" "http://gamelift.ap-southeast-1.amazonaws.com" "http://gamelift.ap-southeast-2.amazonaws.com" "http://gamelift.ap-east-1.amazonaws.com" "http://gamelift.ap-south-1.amazonaws.com" "http://gamelift.sa-east-1.amazonaws.com" "http://gamelift.me-south-1.amazonaws.com" "https://gamelift.us-east-1.amazonaws.com" "https://gamelift.us-east-2.amazonaws.com" "https://gamelift.us-west-1.amazonaws.com" "https://gamelift.us-west-2.amazonaws.com" "https://gamelift.us-gov-west-1.amazonaws.com" "https://gamelift.us-gov-east-1.amazonaws.com" "https://gamelift.ca-central-1.amazonaws.com" "https://gamelift.eu-north-1.amazonaws.com" "https://gamelift.eu-west-1.amazonaws.com" "https://gamelift.eu-west-2.amazonaws.com" "https://gamelift.eu-west-3.amazonaws.com" "https://gamelift.eu-central-1.amazonaws.com" "https://gamelift.eu-south-1.amazonaws.com" "https://gamelift.af-south-1.amazonaws.com" "https://gamelift.ap-northeast-1.amazonaws.com" "https://gamelift.ap-northeast-2.amazonaws.com" "https://gamelift.ap-northeast-3.amazonaws.com" "https://gamelift.ap-southeast-1.amazonaws.com" "https://gamelift.ap-southeast-2.amazonaws.com" "https://gamelift.ap-east-1.amazonaws.com" "https://gamelift.ap-south-1.amazonaws.com" "https://gamelift.sa-east-1.amazonaws.com" "https://gamelift.me-south-1.amazonaws.com" "http://gamelift.cn-north-1.amazonaws.com.cn" "http://gamelift.cn-northwest-1.amazonaws.com.cn" "https://gamelift.cn-north-1.amazonaws.com.cn" "https://gamelift.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def acceptance-type-completer [] { ["ACCEPT" "REJECT"] }
def x-amz-target-completer [] { ["GameLift.AcceptMatch"] }
def x-amz-target-completer-1 [] { ["GameLift.ClaimGameServer"] }
def x-amz-target-completer-2 [] { ["GameLift.CreateAlias"] }
def operating-system-completer [] { ["AMAZON_LINUX" "AMAZON_LINUX_2" "WINDOWS_2012" "WINDOWS_2016"] }
def x-amz-target-completer-3 [] { ["GameLift.CreateBuild"] }
def ec2-instance-type-completer [] { ["c3.2xlarge" "c3.4xlarge" "c3.8xlarge" "c3.large" "c3.xlarge" "c4.2xlarge" "c4.4xlarge" "c4.8xlarge" "c4.large" "c4.xlarge" "c5.12xlarge" "c5.18xlarge" "c5.24xlarge" "c5.2xlarge" "c5.4xlarge" "c5.9xlarge" "c5.large" "c5.xlarge" "c5a.12xlarge" "c5a.16xlarge" "c5a.24xlarge" "c5a.2xlarge" "c5a.4xlarge" "c5a.8xlarge" "c5a.large" "c5a.xlarge" "c5d.12xlarge" "c5d.18xlarge" "c5d.24xlarge" "c5d.2xlarge" "c5d.4xlarge" "c5d.9xlarge" "c5d.large" "c5d.xlarge" "c6a.12xlarge" "c6a.16xlarge" "c6a.24xlarge" "c6a.2xlarge" "c6a.4xlarge" "c6a.8xlarge" "c6a.large" "c6a.xlarge" "c6i.12xlarge" "c6i.16xlarge" "c6i.24xlarge" "c6i.2xlarge" "c6i.4xlarge" "c6i.8xlarge" "c6i.large" "c6i.xlarge" "m3.2xlarge" "m3.large" "m3.medium" "m3.xlarge" "m4.10xlarge" "m4.2xlarge" "m4.4xlarge" "m4.large" "m4.xlarge" "m5.12xlarge" "m5.16xlarge" "m5.24xlarge" "m5.2xlarge" "m5.4xlarge" "m5.8xlarge" "m5.large" "m5.xlarge" "m5a.12xlarge" "m5a.16xlarge" "m5a.24xlarge" "m5a.2xlarge" "m5a.4xlarge" "m5a.8xlarge" "m5a.large" "m5a.xlarge" "r3.2xlarge" "r3.4xlarge" "r3.8xlarge" "r3.large" "r3.xlarge" "r4.16xlarge" "r4.2xlarge" "r4.4xlarge" "r4.8xlarge" "r4.large" "r4.xlarge" "r5.12xlarge" "r5.16xlarge" "r5.24xlarge" "r5.2xlarge" "r5.4xlarge" "r5.8xlarge" "r5.large" "r5.xlarge" "r5a.12xlarge" "r5a.16xlarge" "r5a.24xlarge" "r5a.2xlarge" "r5a.4xlarge" "r5a.8xlarge" "r5a.large" "r5a.xlarge" "r5d.12xlarge" "r5d.16xlarge" "r5d.24xlarge" "r5d.2xlarge" "r5d.4xlarge" "r5d.8xlarge" "r5d.large" "r5d.xlarge" "t2.large" "t2.medium" "t2.micro" "t2.small"] }
def new-game-session-protection-policy-completer [] { ["FullProtection" "NoProtection"] }
def fleet-type-completer [] { ["ON_DEMAND" "SPOT"] }
def compute-type-completer [] { ["ANYWHERE" "EC2"] }
def x-amz-target-completer-4 [] { ["GameLift.CreateFleet"] }
def x-amz-target-completer-5 [] { ["GameLift.CreateFleetLocations"] }
def balancing-strategy-completer [] { ["ON_DEMAND_ONLY" "SPOT_ONLY" "SPOT_PREFERRED"] }
def game-server-protection-policy-completer [] { ["FULL_PROTECTION" "NO_PROTECTION"] }
def x-amz-target-completer-6 [] { ["GameLift.CreateGameServerGroup"] }
def x-amz-target-completer-7 [] { ["GameLift.CreateGameSession"] }
def x-amz-target-completer-8 [] { ["GameLift.CreateGameSessionQueue"] }
def x-amz-target-completer-9 [] { ["GameLift.CreateLocation"] }
def backfill-mode-completer [] { ["AUTOMATIC" "MANUAL"] }
def flex-match-mode-completer [] { ["STANDALONE" "WITH_QUEUE"] }
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
def delete-option-completer [] { ["FORCE_DELETE" "RETAIN" "SAFE_DELETE"] }
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
def status-filter-completer [] { ["ACTIVE" "DELETED" "DELETE_REQUESTED" "DELETING" "ERROR" "UPDATE_REQUESTED" "UPDATING"] }
def x-amz-target-completer-57 [] { ["GameLift.DescribeScalingPolicies"] }
def x-amz-target-completer-58 [] { ["GameLift.DescribeScript"] }
def x-amz-target-completer-59 [] { ["GameLift.DescribeVpcPeeringAuthorizations"] }
def x-amz-target-completer-60 [] { ["GameLift.DescribeVpcPeeringConnections"] }
def x-amz-target-completer-61 [] { ["GameLift.GetComputeAccess"] }
def x-amz-target-completer-62 [] { ["GameLift.GetComputeAuthToken"] }
def x-amz-target-completer-63 [] { ["GameLift.GetGameSessionLogUrl"] }
def x-amz-target-completer-64 [] { ["GameLift.GetInstanceAccess"] }
def routing-strategy-type-completer [] { ["SIMPLE" "TERMINAL"] }
def x-amz-target-completer-65 [] { ["GameLift.ListAliases"] }
def status-completer [] { ["FAILED" "INITIALIZED" "READY"] }
def x-amz-target-completer-66 [] { ["GameLift.ListBuilds"] }
def x-amz-target-completer-67 [] { ["GameLift.ListCompute"] }
def x-amz-target-completer-68 [] { ["GameLift.ListFleets"] }
def x-amz-target-completer-69 [] { ["GameLift.ListGameServerGroups"] }
def sort-order-completer [] { ["ASCENDING" "DESCENDING"] }
def x-amz-target-completer-70 [] { ["GameLift.ListGameServers"] }
def x-amz-target-completer-71 [] { ["GameLift.ListLocations"] }
def x-amz-target-completer-72 [] { ["GameLift.ListScripts"] }
def x-amz-target-completer-73 [] { ["GameLift.ListTagsForResource"] }
def scaling-adjustment-type-completer [] { ["ChangeInCapacity" "ExactCapacity" "PercentChangeInCapacity"] }
def comparison-operator-completer [] { ["GreaterThanOrEqualToThreshold" "GreaterThanThreshold" "LessThanOrEqualToThreshold" "LessThanThreshold"] }
def metric-name-completer [] { ["ActivatingGameSessions" "ActiveGameSessions" "ActiveInstances" "AvailableGameSessions" "AvailablePlayerSessions" "ConcurrentActivatableGameSessions" "CurrentPlayerSessions" "IdleInstances" "PercentAvailableGameSessions" "PercentIdleInstances" "QueueDepth" "WaitTime"] }
def policy-type-completer [] { ["RuleBased" "TargetBased"] }
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
def utilization-status-completer [] { ["AVAILABLE" "UTILIZED"] }
def health-check-completer [] { ["HEALTHY"] }
def x-amz-target-completer-96 [] { ["GameLift.UpdateGameServer"] }
def x-amz-target-completer-97 [] { ["GameLift.UpdateGameServerGroup"] }
def player-session-creation-policy-completer [] { ["ACCEPT_ALL" "DENY_ALL"] }
def protection-policy-completer [] { ["FullProtection" "NoProtection"] }
def x-amz-target-completer-98 [] { ["GameLift.UpdateGameSession"] }
def x-amz-target-completer-99 [] { ["GameLift.UpdateGameSessionQueue"] }
def x-amz-target-completer-100 [] { ["GameLift.UpdateMatchmakingConfiguration"] }
def x-amz-target-completer-101 [] { ["GameLift.UpdateRuntimeConfiguration"] }
def x-amz-target-completer-102 [] { ["GameLift.UpdateScript"] }
def x-amz-target-completer-103 [] { ["GameLift.ValidateMatchmakingRuleSet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["accept-match" "claim-game-server" "create-alias" "create-build" "create-fleet" "create-fleet-locations" "create-game-server-group" "create-game-session" "create-game-session-queue" "create-location" "create-matchmaking-configuration" "create-matchmaking-rule-set" "create-player-session" "create-player-sessions" "create-script" "create-vpc-peering-authorization" "create-vpc-peering-connection" "delete-alias" "delete-build" "delete-fleet" "delete-fleet-locations" "delete-game-server-group" "delete-game-session-queue" "delete-location" "delete-matchmaking-configuration" "delete-matchmaking-rule-set" "delete-scaling-policy" "delete-script" "delete-vpc-peering-authorization" "delete-vpc-peering-connection" "deregister-compute" "deregister-game-server" "describe-alias" "describe-build" "describe-compute" "describe-ec2-instance-limits" "describe-fleet-attributes" "describe-fleet-capacity" "describe-fleet-events" "describe-fleet-location-attributes" "describe-fleet-location-capacity" "describe-fleet-location-utilization" "describe-fleet-port-settings" "describe-fleet-utilization" "describe-game-server" "describe-game-server-group" "describe-game-server-instances" "describe-game-session-details" "describe-game-session-placement" "describe-game-session-queues" "describe-game-sessions" "describe-instances" "describe-matchmaking" "describe-matchmaking-configurations" "describe-matchmaking-rule-sets" "describe-player-sessions" "describe-runtime-configuration" "describe-scaling-policies" "describe-script" "describe-vpc-peering-authorizations" "describe-vpc-peering-connections" "get-compute-access" "get-compute-auth-token" "get-game-session-log-url" "get-instance-access" "list-aliases" "list-builds" "list-compute" "list-fleets" "list-game-server-groups" "list-game-servers" "list-locations" "list-scripts" "list-tags-for-resource" "put-scaling-policy" "register-compute" "register-game-server" "request-upload-credentials" "resolve-alias" "resume-game-server-group" "search-game-sessions" "start-fleet-actions" "start-game-session-placement" "start-match-backfill" "start-matchmaking" "stop-fleet-actions" "stop-game-session-placement" "stop-matchmaking" "suspend-game-server-group" "tag-resource" "untag-resource" "update-alias" "update-build" "update-fleet-attributes" "update-fleet-capacity" "update-fleet-port-settings" "update-game-server" "update-game-server-group" "update-game-session" "update-game-session-queue" "update-matchmaking-configuration" "update-runtime-configuration" "update-script" "validate-matchmaking-rule-set" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "accept-match" [
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
  --x-amz-target: string@x-amz-target-completer # required
  ticket_id: string # A unique identifier for a matchmaking ticket. The ticket must be in status REQUIRES_ACCEPTANCE; otherwise this request will fail.
  player_ids: list<string> # A unique identifier for a player delivering the response. This parameter can include one or multiple player IDs.
  acceptance_type: string@acceptance-type-completer # Player response to the proposed match.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.AcceptMatch")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketId": $ticket_id, "PlayerIds": $player_ids, "AcceptanceType": $acceptance_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "claim-game-server" [
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
  --x-amz-target: string@x-amz-target-completer-1 # required
  game_server_group_name: string # A unique identifier for the game server group where the game server is running. If you are not specifying a game server to claim, this value identifies where you want Amazon GameLift FleetIQ to look for an available game server to claim.
  --game-server-id: string # A custom string that uniquely identifies the game server to claim. If this parameter is left empty, Amazon GameLift FleetIQ searches for an available game server in the specified game server group.
  --game-server-data: string # A set of custom game server properties, formatted as a single string value. This data is passed to a game client or service when it requests information on game servers.
]: any -> oneof<record<GameServer: record<GameServerGroupName: string, GameServerGroupArn: string, GameServerId: string, InstanceId: string, ConnectionInfo: string, GameServerData: string, ClaimStatus: string, UtilizationStatus: string, RegistrationTime: string, LastClaimTime: string, LastHealthCheckTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ClaimGameServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id, "GameServerData": $game_server_data} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-alias" [
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
  --x-amz-target: string@x-amz-target-completer-2 # required
  name: string # A descriptive label that is associated with an alias. Alias names do not need to be unique.
  --description: string # A human-readable description of the alias.
  routing_strategy: record # The routing configuration for a fleet alias. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets) — shape: {Type?: "SIMPLE"|"TERMINAL", FleetId?: string, Message?: string}
  --tags: list # A list of labels to assign to the new alias resource. Tags are developer-defined key-value pairs. Tagging Amazon Web Services resources are useful for resource management, access management and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. — item shape: {Key: string, Value: string}
]: any -> oneof<record<Alias: record<AliasId: string, Name: string, AliasArn: string, Description: string, RoutingStrategy: record<Type: string, FleetId: string, Message: string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateAlias")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "RoutingStrategy": $routing_strategy, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-build" [
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
  --x-amz-target: string@x-amz-target-completer-3 # required
  --name: string # A descriptive label associated with a build. Build names don't need to be unique. You can change this value later.
  --version: string # Version information associated with a build or script. Version strings don't need to be unique. You can change this value later.
  --storage-location: record # The location in Amazon S3 where build or script files are stored for access by Amazon GameLift. — shape: {Bucket?: string, Key?: string, RoleArn?: string, ObjectVersion?: string}
  --operating-system: string@operating-system-completer # The operating system that you built the game server binaries to run on. This value determines the type of fleet resources that you can use for this build. If your game build contains multiple executables, they all must run on the same operating system. If an operating system isn't specified when creating a build, Amazon GameLift uses the default value (WINDOWS_2012). This value can't be changed later.
  --tags: list # A list of labels to assign to the new build resource. Tags are developer defined key-value pairs. Tagging Amazon Web Services resources are useful for resource management, access management and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. Once the resource is created, you can use TagResource (https://docs.aws.amazon.com/gamelift/latest/apireference/API_TagResource.html), UntagResource (https://docs.aws.amazon.com/gamelift/latest/apireference/API_UntagResource.html), and ListTagsForResource (https://docs.aws.amazon.com/gamelift/latest/apireference/API_ListTagsForResource.html) to add, remove, and view tags. The maximum tag limit may be lower than stated. See the Amazon Web Services General Reference for actual tagging limits. — item shape: {Key: string, Value: string}
  --server-sdk-version: string # Data type used for server SDK version.
]: any -> oneof<record<Build: record<BuildId: string, BuildArn: string, Name: string, Version: string, Status: string, SizeOnDisk: int, OperatingSystem: string, CreationTime: string, ServerSdkVersion: string>, UploadCredentials: record<AccessKeyId: string, SecretAccessKey: string, SessionToken: string>, StorageLocation: record<Bucket: string, Key: string, RoleArn: string, ObjectVersion: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateBuild")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Version": $version, "StorageLocation": $storage_location, "OperatingSystem": $operating_system, "Tags": $tags, "ServerSdkVersion": $server_sdk_version} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-fleet" [
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
  --x-amz-target: string@x-amz-target-completer-4 # required
  name: string # A descriptive label that is associated with a fleet. Fleet names do not need to be unique.
  --description: string # A description for the fleet.
  --build-id: string # The unique identifier for a custom game server build to be deployed on fleet instances. You can use either the build ID or ARN. The build must be uploaded to Amazon GameLift and in READY status. This fleet property cannot be changed later.
  --script-id: string # The unique identifier for a Realtime configuration script to be deployed on fleet instances. You can use either the script ID or ARN. Scripts must be uploaded to Amazon GameLift prior to creating the fleet. This fleet property cannot be changed later.
  --server-launch-path: string # This parameter is no longer used. Specify a server launch path using the RuntimeConfiguration parameter. Requests that use this parameter instead continue to be valid.
  --server-launch-parameters: string # This parameter is no longer used. Specify server launch parameters using the RuntimeConfiguration parameter. Requests that use this parameter instead continue to be valid.
  --log-paths: list<string> # This parameter is no longer used. To specify where Amazon GameLift should store log files once a server process shuts down, use the Amazon GameLift server API ProcessReady() and specify one or more directory paths in logParameters. For more information, see Initialize the server process (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-initialize) in the Amazon GameLift Developer Guide.
  --ec2-instance-type: string@ec2-instance-type-completer # The Amazon GameLift-supported Amazon EC2 instance type to use for all fleet instances. Instance type determines the computing resources that will be used to host your game servers, including CPU, memory, storage, and networking capacity. See Amazon Elastic Compute Cloud Instance Types (http://aws.amazon.com/ec2/instance-types/) for detailed descriptions of Amazon EC2 instance types.
  --ec2-inbound-permissions: list # The allowed IP address ranges and port settings that allow inbound traffic to access game sessions on this fleet. If the fleet is hosting a custom game build, this property must be set before players can connect to game sessions. For Realtime Servers fleets, Amazon GameLift automatically sets TCP and UDP ranges. — item shape: {FromPort: int, ToPort: int, IpRange: string, Protocol: "TCP"|"UDP"}
  --new-game-session-protection-policy: string@new-game-session-protection-policy-completer # The status of termination protection for active game sessions on the fleet. By default, this property is set to NoProtection. You can also set game session protection for an individual game session by calling UpdateGameSession (gamelift/latest/apireference/API_UpdateGameSession.html). NoProtection - Game sessions can be terminated during active gameplay as a result of a scale-down event. FullProtection - Game sessions in ACTIVE status cannot be terminated during a scale-down event.
  --runtime-configuration: record # A collection of server process configurations that describe the set of processes to run on each instance in a fleet. Server processes run either an executable in a custom game build or a Realtime Servers script. Amazon GameLift launches the configured processes, manages their life cycle, and replaces them as needed. Each instance checks regularly for an updated runtime configuration. A Amazon GameLift instance is limited to 50 processes running concurrently. To calculate the total number of processes in a runtime configuration, add the values of the ConcurrentExecutions parameter for each server process. Learn more about Running Multiple Processes on a Fleet (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-multiprocess.html). — shape: {ServerProcesses?: list, MaxConcurrentGameSessionActivations?: int, GameSessionActivationTimeoutSeconds?: int}
  --resource-creation-limit-policy: record # A policy that puts limits on the number of game sessions that a player can create within a specified span of time. With this policy, you can control players' ability to consume available resources. The policy is evaluated when a player tries to create a new game session. On receiving a CreateGameSession request, Amazon GameLift checks that the player (identified by CreatorId) has created fewer than game session limit in the specified time period. — shape: {NewGameSessionsPerCreator?: int, PolicyPeriodInMinutes?: int}
  --metric-groups: list<string> # The name of an Amazon Web Services CloudWatch metric group to add this fleet to. A metric group is used to aggregate the metrics for multiple fleets. You can specify an existing metric group name or set a new name to create a new metric group. A fleet can be included in only one metric group at a time.
  --peer-vpc-aws-account-id: string # Used when peering your Amazon GameLift fleet with a VPC, the unique identifier for the Amazon Web Services account that owns the VPC. You can find your account ID in the Amazon Web Services Management Console under account settings.
  --peer-vpc-id: string # A unique identifier for a VPC with resources to be accessed by your Amazon GameLift fleet. The VPC must be in the same Region as your fleet. To look up a VPC ID, use the VPC Dashboard (https://console.aws.amazon.com/vpc/) in the Amazon Web Services Management Console. Learn more about VPC peering in VPC Peering with Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html).
  --fleet-type: string@fleet-type-completer # Indicates whether to use On-Demand or Spot instances for this fleet. By default, this property is set to ON_DEMAND. Learn more about when to use On-Demand versus Spot Instances (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-ec2-instances.html#gamelift-ec2-instances-spot). This property cannot be changed after the fleet is created.
  --instance-role-arn: string # A unique identifier for an IAM role that manages access to your Amazon Web Services services. With an instance role ARN set, any application that runs on an instance in this fleet can assume the role, including install scripts, server processes, and daemons (background processes). Create a role or look up a role's ARN by using the IAM dashboard (https://console.aws.amazon.com/iam/) in the Amazon Web Services Management Console. Learn more about using on-box credentials for your game servers at Access external resources from a game server (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-resources.html). This property cannot be changed after the fleet is created.
  --certificate-configuration: record # Determines whether a TLS/SSL certificate is generated for a fleet. This feature must be enabled when creating the fleet. All instances in a fleet share the same certificate. The certificate can be retrieved by calling the Amazon GameLift Server SDK (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-serversdk.html) operation GetInstanceCertificate. — shape: {CertificateType: "DISABLED"|"GENERATED"}
  --locations: list # A set of remote locations to deploy additional instances to and manage as part of the fleet. This parameter can only be used when creating fleets in Amazon Web Services Regions that support multiple locations. You can add any Amazon GameLift-supported Amazon Web Services Region as a remote location, in the form of an Amazon Web Services Region code such as us-west-2. To create a fleet with instances in the home Region only, don't use this parameter. To use this parameter, Amazon GameLift requires you to use your home location in the request. — item shape: {Location: string}
  --tags: list # A list of labels to assign to the new fleet resource. Tags are developer-defined key-value pairs. Tagging Amazon Web Services resources are useful for resource management, access management and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. — item shape: {Key: string, Value: string}
  --compute-type: string@compute-type-completer # The type of compute resource used to host your game servers. You can use your own compute resources with Amazon GameLift Anywhere or use Amazon EC2 instances with managed Amazon GameLift. By default, this property is set to EC2.
  --anywhere-configuration: record # Amazon GameLift Anywhere configuration options for your Anywhere fleets. — shape: {Cost: string}
]: any -> oneof<record<FleetAttributes: record<FleetId: string, FleetArn: string, FleetType: string, InstanceType: string, Description: string, Name: string, CreationTime: string, TerminationTime: string, Status: string, BuildId: string, BuildArn: string, ScriptId: string, ScriptArn: string, ServerLaunchPath: string, ServerLaunchParameters: string, LogPaths: list<string>, NewGameSessionProtectionPolicy: string, OperatingSystem: string, ResourceCreationLimitPolicy: record<NewGameSessionsPerCreator: int, PolicyPeriodInMinutes: int>, MetricGroups: list<string>, StoppedActions: list<string>, InstanceRoleArn: string, CertificateConfiguration: record<CertificateType: string>, ComputeType: string, AnywhereConfiguration: record<Cost: string>>, LocationStates: table<Location: string, Status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateFleet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "BuildId": $build_id, "ScriptId": $script_id, "ServerLaunchPath": $server_launch_path, "ServerLaunchParameters": $server_launch_parameters, "LogPaths": $log_paths, "EC2InstanceType": $ec2_instance_type, "EC2InboundPermissions": $ec2_inbound_permissions, "NewGameSessionProtectionPolicy": $new_game_session_protection_policy, "RuntimeConfiguration": $runtime_configuration, "ResourceCreationLimitPolicy": $resource_creation_limit_policy, "MetricGroups": $metric_groups, "PeerVpcAwsAccountId": $peer_vpc_aws_account_id, "PeerVpcId": $peer_vpc_id, "FleetType": $fleet_type, "InstanceRoleArn": $instance_role_arn, "CertificateConfiguration": $certificate_configuration, "Locations": $locations, "Tags": $tags, "ComputeType": $compute_type, "AnywhereConfiguration": $anywhere_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-fleet-locations" [
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
  --x-amz-target: string@x-amz-target-completer-5 # required
  fleet_id: string # A unique identifier for the fleet to add locations to. You can use either the fleet ID or ARN value.
  locations: list # A list of locations to deploy additional instances to and manage as part of the fleet. You can add any Amazon GameLift-supported Amazon Web Services Region as a remote location, in the form of an Amazon Web Services Region code such as us-west-2. — item shape: {Location: string}
]: any -> oneof<record<FleetId: string, FleetArn: string, LocationStates: table<Location: string, Status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateFleetLocations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Locations": $locations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-game-server-group" [
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
  --x-amz-target: string@x-amz-target-completer-6 # required
  game_server_group_name: string # An identifier for the new game server group. This value is used to generate unique ARN identifiers for the Amazon EC2 Auto Scaling group and the Amazon GameLift FleetIQ game server group. The name must be unique per Region per Amazon Web Services account.
  role_arn: string # The Amazon Resource Name (ARN (https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-arn-format.html)) for an IAM role that allows Amazon GameLift to access your Amazon EC2 Auto Scaling groups.
  min_size: int # The minimum number of instances allowed in the Amazon EC2 Auto Scaling group. During automatic scaling events, Amazon GameLift FleetIQ and Amazon EC2 do not scale down the group below this minimum. In production, this value should be set to at least 1. After the Auto Scaling group is created, update this value directly in the Auto Scaling group using the Amazon Web Services console or APIs.
  max_size: int # The maximum number of instances allowed in the Amazon EC2 Auto Scaling group. During automatic scaling events, Amazon GameLift FleetIQ and EC2 do not scale up the group above this maximum. After the Auto Scaling group is created, update this value directly in the Auto Scaling group using the Amazon Web Services console or APIs.
  launch_template: record # This data type is used with the Amazon GameLift FleetIQ and game server groups. An Amazon Elastic Compute Cloud launch template that contains configuration settings and game server code to be deployed to all instances in a game server group. The launch template is specified when creating a new game server group. — shape: {LaunchTemplateId?: string, LaunchTemplateName?: string, Version?: string}
  instance_definitions: list # The Amazon EC2 instance types and sizes to use in the Auto Scaling group. The instance definitions must specify at least two different instance types that are supported by Amazon GameLift FleetIQ. For more information on instance types, see EC2 Instance Types (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html) in the Amazon Elastic Compute Cloud User Guide. You can optionally specify capacity weighting for each instance type. If no weight value is specified for an instance type, it is set to the default value "1". For more information about capacity weighting, see Instance Weighting for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-weighting.html) in the Amazon EC2 Auto Scaling User Guide. — item shape: {InstanceType: "c4.large"|"c4.xlarge"|"c4.2xlarge"|"c4.4xlarge"|"c4.8xlarge"|"c5.large"|"c5.xlarge"|"c5.2xlarge"|"c5.4xlarge"|"c5.9xlarge"|"c5.12xlarge"|"c5.18xlarge"|"c5.24xlarge"|"c5a.large"|"c5a.xlarge"|"c5a.2xlarge"|"c5a.4xlarge"|"c5a.8xlarge"|"c5a.12xlarge"|"c5a.16xlarge"|"c5a.24xlarge"|"c6g.medium"|"c6g.large"|"c6g.xlarge"|"c6g.2xlarge"|"c6g.4xlarge"|"c6g.8xlarge"|"c6g.12xlarge"|"c6g.16xlarge"|"r4.large"|"r4.xlarge"|"r4.2xlarge"|"r4.4xlarge"|"r4.8xlarge"|"r4.16xlarge"|"r5.large"|"r5.xlarge"|"r5.2xlarge"|"r5.4xlarge"|"r5.8xlarge"|"r5.12xlarge"|"r5.16xlarge"|"r5.24xlarge"|"r5a.large"|"r5a.xlarge"|"r5a.2xlarge"|"r5a.4xlarge"|"r5a.8xlarge"|"r5a.12xlarge"|"r5a.16xlarge"|"r5a.24xlarge"|"r6g.medium"|"r6g.large"|"r6g.xlarge"|"r6g.2xlarge"|"r6g.4xlarge"|"r6g.8xlarge"|"r6g.12xlarge"|"r6g.16xlarge"|"m4.large"|"m4.xlarge"|"m4.2xlarge"|"m4.4xlarge"|"m4.10xlarge"|"m5.large"|"m5.xlarge"|"m5.2xlarge"|"m5.4xlarge"|"m5.8xlarge"|"m5.12xlarge"|"m5.16xlarge"|"m5.24xlarge"|"m5a.large"|"m5a.xlarge"|"m5a.2xlarge"|"m5a.4xlarge"|"m5a.8xlarge"|"m5a.12xlarge"|"m5a.16xlarge"|"m5a.24xlarge"|"m6g.medium"|"m6g.large"|"m6g.xlarge"|"m6g.2xlarge"|"m6g.4xlarge"|"m6g.8xlarge"|"m6g.12xlarge"|"m6g.16xlarge", ... (1 more fields)}
  --auto-scaling-policy: record # This data type is used with the Amazon GameLift FleetIQ and game server groups. Configuration settings for intelligent automatic scaling that uses target tracking. These settings are used to add an Auto Scaling policy when creating the corresponding Auto Scaling group. After the Auto Scaling group is created, all updates to Auto Scaling policies, including changing this policy and adding or removing other policies, is done directly on the Auto Scaling group. — shape: {EstimatedInstanceWarmup?: int, TargetTrackingConfiguration: record}
  --balancing-strategy: string@balancing-strategy-completer # Indicates how Amazon GameLift FleetIQ balances the use of Spot Instances and On-Demand Instances in the game server group. Method options include the following: SPOT_ONLY - Only Spot Instances are used in the game server group. If Spot Instances are unavailable or not viable for game hosting, the game server group provides no hosting capacity until Spot Instances can again be used. Until then, no new instances are started, and the existing nonviable Spot Instances are terminated (after current gameplay ends) and are not replaced. SPOT_PREFERRED - (default value) Spot Instances are used whenever available in the game server group. If Spot Instances are unavailable, the game server group continues to provide hosting capacity by falling back to On-Demand Instances. Existing nonviable Spot Instances are terminated (after current gameplay ends) and are replaced with new On-Demand Instances. ON_DEMAND_ONLY - Only On-Demand Instances are used in the game server group. No Spot Instances are used, even when available, while this balancing strategy is in force.
  --game-server-protection-policy: string@game-server-protection-policy-completer # A flag that indicates whether instances in the game server group are protected from early termination. Unprotected instances that have active game servers running might be terminated during a scale-down event, causing players to be dropped from the game. Protected instances cannot be terminated while there are active game servers running except in the event of a forced game server group deletion (see ). An exception to this is with Spot Instances, which can be terminated by Amazon Web Services regardless of protection status. This property is set to NO_PROTECTION by default.
  --vpc-subnets: list<string> # A list of virtual private cloud (VPC) subnets to use with instances in the game server group. By default, all Amazon GameLift FleetIQ-supported Availability Zones are used. You can use this parameter to specify VPCs that you've set up. This property cannot be updated after the game server group is created, and the corresponding Auto Scaling group will always use the property value that is set with this request, even if the Auto Scaling group is updated directly.
  --tags: list # A list of labels to assign to the new game server group resource. Tags are developer-defined key-value pairs. Tagging Amazon Web Services resources is useful for resource management, access management, and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. — item shape: {Key: string, Value: string}
]: any -> oneof<record<GameServerGroup: record<GameServerGroupName: string, GameServerGroupArn: string, RoleArn: string, InstanceDefinitions: list<record>, BalancingStrategy: string, GameServerProtectionPolicy: string, AutoScalingGroupArn: string, Status: string, StatusReason: string, SuspendedActions: list<string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateGameServerGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "RoleArn": $role_arn, "MinSize": $min_size, "MaxSize": $max_size, "LaunchTemplate": $launch_template, "InstanceDefinitions": $instance_definitions, "AutoScalingPolicy": $auto_scaling_policy, "BalancingStrategy": $balancing_strategy, "GameServerProtectionPolicy": $game_server_protection_policy, "VpcSubnets": $vpc_subnets, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-game-session" [
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
  --x-amz-target: string@x-amz-target-completer-7 # required
  --fleet-id: string # A unique identifier for the fleet to create a game session in. You can use either the fleet ID or ARN value. Each request must reference either a fleet ID or alias ID, but not both.
  --alias-id: string # A unique identifier for the alias associated with the fleet to create a game session in. You can use either the alias ID or ARN value. Each request must reference either a fleet ID or alias ID, but not both.
  maximum_player_session_count: int # The maximum number of players that can be connected simultaneously to the game session.
  --name: string # A descriptive label that is associated with a game session. Session names do not need to be unique.
  --game-properties: list # A set of custom properties for a game session, formatted as key:value pairs. These properties are passed to a game server process with a request to start a new game session (see Start a Game Session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession)). — item shape: {Key: string, Value: string}
  --creator-id: string # A unique identifier for a player or entity creating the game session. If you add a resource creation limit policy to a fleet, the CreateGameSession operation requires a CreatorId. Amazon GameLift limits the number of game session creation requests with the same CreatorId in a specified time period. If you your fleet doesn't have a resource creation limit policy and you provide a CreatorId in your CreateGameSession requests, Amazon GameLift limits requests to one request per CreatorId per second. To not limit CreateGameSession requests with the same CreatorId, don't provide a CreatorId in your CreateGameSession request.
  --game-session-id: string # This parameter is deprecated. Use IdempotencyToken instead. Custom string that uniquely identifies a request for a new game session. Maximum token length is 48 characters. If provided, this string is included in the new game session's ID.
  --idempotency-token: string # Custom string that uniquely identifies the new game session request. This is useful for ensuring that game session requests with the same idempotency token are processed only once. Subsequent requests with the same string return the original GameSession object, with an updated status. Maximum token length is 48 characters. If provided, this string is included in the new game session's ID. A game session ARN has the following format: arn:aws:gamelift:<region>::gamesession/<fleet ID>/<custom ID string or idempotency token>. Idempotency tokens remain in use for 30 days after a game session has ended; game session objects are retained for this time period and then deleted.
  --game-session-data: string # A set of custom game session properties, formatted as a single string value. This data is passed to a game server process with a request to start a new game session (see Start a Game Session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession)).
  --location: string # A fleet's remote location to place the new game session in. If this parameter is not set, the new game session is placed in the fleet's home Region. Specify a remote location with an Amazon Web Services Region code such as us-west-2.
]: any -> oneof<record<GameSession: record<GameSessionId: string, Name: string, FleetId: string, FleetArn: string, CreationTime: string, TerminationTime: string, CurrentPlayerSessionCount: int, MaximumPlayerSessionCount: int, Status: string, StatusReason: string, GameProperties: list<record>, IpAddress: string, DnsName: string, Port: int, PlayerSessionCreationPolicy: string, CreatorId: string, GameSessionData: string, MatchmakerData: string, Location: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateGameSession")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "AliasId": $alias_id, "MaximumPlayerSessionCount": $maximum_player_session_count, "Name": $name, "GameProperties": $game_properties, "CreatorId": $creator_id, "GameSessionId": $game_session_id, "IdempotencyToken": $idempotency_token, "GameSessionData": $game_session_data, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-game-session-queue" [
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
  --x-amz-target: string@x-amz-target-completer-8 # required
  name: string # A descriptive label that is associated with game session queue. Queue names must be unique within each Region.
  --timeout-in-seconds: int # The maximum time, in seconds, that a new game session placement request remains in the queue. When a request exceeds this time, the game session placement changes to a TIMED_OUT status.
  --player-latency-policies: list # A set of policies that act as a sliding cap on player latency. FleetIQ works to deliver low latency for most players in a game session. These policies ensure that no individual player can be placed into a game with unreasonably high latency. Use multiple policies to gradually relax latency requirements a step at a time. Multiple policies are applied based on their maximum allowed latency, starting with the lowest value. — item shape: {MaximumIndividualPlayerLatencyMilliseconds?: int, PolicyDurationSeconds?: int}
  --destinations: list # A list of fleets and/or fleet aliases that can be used to fulfill game session placement requests in the queue. Destinations are identified by either a fleet ARN or a fleet alias ARN, and are listed in order of placement preference. — item shape: {DestinationArn?: string}
  --filter-configuration: record # A list of fleet locations where a game session queue can place new game sessions. You can use a filter to temporarily turn off placements for specific locations. For queues that have multi-location fleets, you can use a filter configuration allow placement with some, but not all of these locations. — shape: {AllowedLocations?: list<string>}
  --priority-configuration: record # Custom prioritization settings for use by a game session queue when placing new game sessions with available game servers. When defined, this configuration replaces the default FleetIQ prioritization process, which is as follows: If player latency data is included in a game session request, destinations and locations are prioritized first based on lowest average latency (1), then on lowest hosting cost (2), then on destination list order (3), and finally on location (alphabetical) (4). This approach ensures that the queue's top priority is to place game sessions where average player latency is lowest, and--if latency is the same--where the hosting cost is less, etc. If player latency data is not included, destinations and locations are prioritized first on destination list order (1), and then on location (alphabetical) (2). This approach ensures that the queue's top priority is to place game sessions on the first destination fleet listed. If that fleet has multiple locations, the game session is placed on the first location (when listed alphabetically). Changing the priority order will affect how game sessions are placed. — shape: {PriorityOrder?: list<string>, LocationOrder?: list<string>}
  --custom-event-data: string # Information to be added to all events that are related to this game session queue.
  --notification-target: string # An SNS topic ARN that is set up to receive game session placement notifications. See Setting up notifications for game session placement (https://docs.aws.amazon.com/gamelift/latest/developerguide/queue-notification.html).
  --tags: list # A list of labels to assign to the new game session queue resource. Tags are developer-defined key-value pairs. Tagging Amazon Web Services resources are useful for resource management, access management and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. — item shape: {Key: string, Value: string}
]: any -> oneof<record<GameSessionQueue: record<Name: string, GameSessionQueueArn: string, TimeoutInSeconds: int, PlayerLatencyPolicies: list<record>, Destinations: list<record>, FilterConfiguration: record<AllowedLocations: list>, PriorityConfiguration: record<PriorityOrder: list, LocationOrder: list>, CustomEventData: string, NotificationTarget: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateGameSessionQueue")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "TimeoutInSeconds": $timeout_in_seconds, "PlayerLatencyPolicies": $player_latency_policies, "Destinations": $destinations, "FilterConfiguration": $filter_configuration, "PriorityConfiguration": $priority_configuration, "CustomEventData": $custom_event_data, "NotificationTarget": $notification_target, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-location" [
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
  --x-amz-target: string@x-amz-target-completer-9 # required
  location_name: string # A descriptive name for the custom location.
  --tags: list # A list of labels to assign to the new matchmaking configuration resource. Tags are developer-defined key-value pairs. Tagging Amazon Web Services resources are useful for resource management, access management and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Rareference. — item shape: {Key: string, Value: string}
]: any -> oneof<record<Location: record<LocationName: string, LocationArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateLocation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationName": $location_name, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-matchmaking-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-10 # required
  name: string # A unique identifier for the matchmaking configuration. This name is used to identify the configuration associated with a matchmaking request or ticket.
  --description: string # A human-readable description of the matchmaking configuration.
  --game-session-queue-arns: list<string> # The Amazon Resource Name (ARN (https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-arn-format.html)) that is assigned to a Amazon GameLift game session queue resource and uniquely identifies it. ARNs are unique across all Regions. Format is arn:aws:gamelift:<region>::gamesessionqueue/<queue name>. Queues can be located in any Region. Queues are used to start new Amazon GameLift-hosted game sessions for matches that are created with this matchmaking configuration. If FlexMatchMode is set to STANDALONE, do not set this parameter.
  request_timeout_seconds: int # The maximum duration, in seconds, that a matchmaking ticket can remain in process before timing out. Requests that fail due to timing out can be resubmitted as needed.
  --acceptance-timeout-seconds: int # The length of time (in seconds) to wait for players to accept a proposed match, if acceptance is required.
  --acceptance-required: oneof<nothing, bool> # A flag that determines whether a match that was created with this configuration must be accepted by the matched players. To require acceptance, set to TRUE. With this option enabled, matchmaking tickets use the status REQUIRES_ACCEPTANCE to indicate when a completed potential match is waiting for player acceptance.
  rule_set_name: string # A unique identifier for the matchmaking rule set to use with this configuration. You can use either the rule set name or ARN value. A matchmaking configuration can only use rule sets that are defined in the same Region.
  --notification-target: string # An SNS topic ARN that is set up to receive matchmaking notifications. See Setting up notifications for matchmaking (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-notification.html) for more information.
  --additional-player-count: int # The number of player slots in a match to keep open for future players. For example, if the configuration's rule set specifies a match for a single 12-person team, and the additional player count is set to 2, only 10 players are selected for the match. This parameter is not used if FlexMatchMode is set to STANDALONE.
  --custom-event-data: string # Information to be added to all events related to this matchmaking configuration.
  --game-properties: list # A set of custom properties for a game session, formatted as key:value pairs. These properties are passed to a game server process with a request to start a new game session (see Start a Game Session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession)). This information is added to the new GameSession object that is created for a successful match. This parameter is not used if FlexMatchMode is set to STANDALONE. — item shape: {Key: string, Value: string}
  --game-session-data: string # A set of custom game session properties, formatted as a single string value. This data is passed to a game server process with a request to start a new game session (see Start a Game Session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession)). This information is added to the new GameSession object that is created for a successful match. This parameter is not used if FlexMatchMode is set to STANDALONE.
  --backfill-mode: string@backfill-mode-completer # The method used to backfill game sessions that are created with this matchmaking configuration. Specify MANUAL when your game manages backfill requests manually or does not use the match backfill feature. Specify AUTOMATIC to have Amazon GameLift create a backfill request whenever a game session has one or more open slots. Learn more about manual and automatic backfill in Backfill Existing Games with FlexMatch (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-backfill.html). Automatic backfill is not available when FlexMatchMode is set to STANDALONE.
  --flex-match-mode: string@flex-match-mode-completer # Indicates whether this matchmaking configuration is being used with Amazon GameLift hosting or as a standalone matchmaking solution. STANDALONE - FlexMatch forms matches and returns match information, including players and team assignments, in a MatchmakingSucceeded (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-events.html#match-events-matchmakingsucceeded) event. WITH_QUEUE - FlexMatch forms matches and uses the specified Amazon GameLift queue to start a game session for the match.
  --tags: list # A list of labels to assign to the new matchmaking configuration resource. Tags are developer-defined key-value pairs. Tagging Amazon Web Services resources are useful for resource management, access management and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. — item shape: {Key: string, Value: string}
]: any -> oneof<record<Configuration: record<Name: string, ConfigurationArn: string, Description: string, GameSessionQueueArns: list<string>, RequestTimeoutSeconds: int, AcceptanceTimeoutSeconds: int, AcceptanceRequired: bool, RuleSetName: string, RuleSetArn: string, NotificationTarget: string, AdditionalPlayerCount: int, CustomEventData: string, CreationTime: string, GameProperties: list<record>, GameSessionData: string, BackfillMode: string, FlexMatchMode: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateMatchmakingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "GameSessionQueueArns": $game_session_queue_arns, "RequestTimeoutSeconds": $request_timeout_seconds, "AcceptanceTimeoutSeconds": $acceptance_timeout_seconds, "AcceptanceRequired": $acceptance_required, "RuleSetName": $rule_set_name, "NotificationTarget": $notification_target, "AdditionalPlayerCount": $additional_player_count, "CustomEventData": $custom_event_data, "GameProperties": $game_properties, "GameSessionData": $game_session_data, "BackfillMode": $backfill_mode, "FlexMatchMode": $flex_match_mode, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "AcceptanceRequired") == null) { error make --unspanned { msg: "required body field 'AcceptanceRequired' missing: pass --acceptance-required or pipe a record" } }
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-matchmaking-rule-set" [
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
  --x-amz-target: string@x-amz-target-completer-11 # required
  name: string # A unique identifier for the matchmaking rule set. A matchmaking configuration identifies the rule set it uses by this name value. Note that the rule set name is different from the optional name field in the rule set body.
  rule_set_body: string # A collection of matchmaking rules, formatted as a JSON string. Comments are not allowed in JSON, but most elements support a description field.
  --tags: list # A list of labels to assign to the new matchmaking rule set resource. Tags are developer-defined key-value pairs. Tagging Amazon Web Services resources are useful for resource management, access management and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. — item shape: {Key: string, Value: string}
]: any -> oneof<record<RuleSet: record<RuleSetName: string, RuleSetArn: string, RuleSetBody: string, CreationTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateMatchmakingRuleSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "RuleSetBody": $rule_set_body, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-player-session" [
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
  --x-amz-target: string@x-amz-target-completer-12 # required
  game_session_id: string # A unique identifier for the game session to add a player to.
  player_id: string # A unique identifier for a player. Player IDs are developer-defined.
  --player-data: string # Developer-defined information related to a player. Amazon GameLift does not use this data, so it can be formatted as needed for use in the game.
]: any -> oneof<record<PlayerSession: record<PlayerSessionId: string, PlayerId: string, GameSessionId: string, FleetId: string, FleetArn: string, CreationTime: string, TerminationTime: string, Status: string, IpAddress: string, DnsName: string, Port: int, PlayerData: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreatePlayerSession")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameSessionId": $game_session_id, "PlayerId": $player_id, "PlayerData": $player_data} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-player-sessions" [
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
  --x-amz-target: string@x-amz-target-completer-13 # required
  game_session_id: string # A unique identifier for the game session to add players to.
  player_ids: list<string> # List of unique identifiers for the players to be added.
  --player-data-map: record # Map of string pairs, each specifying a player ID and a set of developer-defined information related to the player. Amazon GameLift does not use this data, so it can be formatted as needed for use in the game. Any player data strings for player IDs that are not included in the PlayerIds parameter are ignored.
]: any -> oneof<record<PlayerSessions: table<PlayerSessionId: string, PlayerId: string, GameSessionId: string, FleetId: string, FleetArn: string, CreationTime: string, TerminationTime: string, Status: string, IpAddress: string, DnsName: string, Port: int, PlayerData: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreatePlayerSessions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameSessionId": $game_session_id, "PlayerIds": $player_ids, "PlayerDataMap": $player_data_map} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-script" [
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
  --x-amz-target: string@x-amz-target-completer-14 # required
  --name: string # A descriptive label that is associated with a script. Script names don't need to be unique. You can use UpdateScript (https://docs.aws.amazon.com/gamelift/latest/apireference/API_UpdateScript.html) to change this value later.
  --version: string # Version information associated with a build or script. Version strings don't need to be unique. You can use UpdateScript (https://docs.aws.amazon.com/gamelift/latest/apireference/API_UpdateScript.html) to change this value later.
  --storage-location: record # The location in Amazon S3 where build or script files are stored for access by Amazon GameLift. — shape: {Bucket?: string, Key?: string, RoleArn?: string, ObjectVersion?: string}
  --zip-file: string # A data object containing your Realtime scripts and dependencies as a zip file. The zip file can have one or multiple files. Maximum size of a zip file is 5 MB. When using the Amazon Web Services CLI tool to create a script, this parameter is set to the zip file name. It must be prepended with the string "fileb://" to indicate that the file data is a binary object. For example: --zip-file fileb://myRealtimeScript.zip.
  --tags: list # A list of labels to assign to the new script resource. Tags are developer-defined key-value pairs. Tagging Amazon Web Services resources are useful for resource management, access management and cost allocation. For more information, see Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) in the Amazon Web Services General Reference. Once the resource is created, you can use TagResource (https://docs.aws.amazon.com/gamelift/latest/apireference/API_TagResource.html), UntagResource (https://docs.aws.amazon.com/gamelift/latest/apireference/API_UntagResource.html), and ListTagsForResource (https://docs.aws.amazon.com/gamelift/latest/apireference/API_ListTagsForResource.html) to add, remove, and view tags. The maximum tag limit may be lower than stated. See the Amazon Web Services General Reference for actual tagging limits. — item shape: {Key: string, Value: string}
]: any -> oneof<record<Script: record<ScriptId: string, ScriptArn: string, Name: string, Version: string, SizeOnDisk: int, CreationTime: string, StorageLocation: record<Bucket: string, Key: string, RoleArn: string, ObjectVersion: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateScript")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Version": $version, "StorageLocation": $storage_location, "ZipFile": $zip_file, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-vpc-peering-authorization" [
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
  --x-amz-target: string@x-amz-target-completer-15 # required
  game_lift_aws_account_id: string # A unique identifier for the Amazon Web Services account that you use to manage your Amazon GameLift fleet. You can find your Account ID in the Amazon Web Services Management Console under account settings.
  peer_vpc_id: string # A unique identifier for a VPC with resources to be accessed by your Amazon GameLift fleet. The VPC must be in the same Region as your fleet. To look up a VPC ID, use the VPC Dashboard (https://console.aws.amazon.com/vpc/) in the Amazon Web Services Management Console. Learn more about VPC peering in VPC Peering with Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html).
]: any -> oneof<record<VpcPeeringAuthorization: record<GameLiftAwsAccountId: string, PeerVpcAwsAccountId: string, PeerVpcId: string, CreationTime: string, ExpirationTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateVpcPeeringAuthorization")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameLiftAwsAccountId": $game_lift_aws_account_id, "PeerVpcId": $peer_vpc_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "create-vpc-peering-connection" [
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
  --x-amz-target: string@x-amz-target-completer-16 # required
  fleet_id: string # A unique identifier for the fleet. You can use either the fleet ID or ARN value. This tells Amazon GameLift which GameLift VPC to peer with.
  peer_vpc_aws_account_id: string # A unique identifier for the Amazon Web Services account with the VPC that you want to peer your Amazon GameLift fleet with. You can find your Account ID in the Amazon Web Services Management Console under account settings.
  peer_vpc_id: string # A unique identifier for a VPC with resources to be accessed by your Amazon GameLift fleet. The VPC must be in the same Region as your fleet. To look up a VPC ID, use the VPC Dashboard (https://console.aws.amazon.com/vpc/) in the Amazon Web Services Management Console. Learn more about VPC peering in VPC Peering with Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html).
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.CreateVpcPeeringConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "PeerVpcAwsAccountId": $peer_vpc_aws_account_id, "PeerVpcId": $peer_vpc_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-alias" [
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
  --x-amz-target: string@x-amz-target-completer-17 # required
  alias_id: string # A unique identifier of the alias that you want to delete. You can use either the alias ID or ARN value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteAlias")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AliasId": $alias_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-build" [
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
  --x-amz-target: string@x-amz-target-completer-18 # required
  build_id: string # A unique identifier for the build to delete. You can use either the build ID or ARN value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteBuild")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BuildId": $build_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-fleet" [
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
  --x-amz-target: string@x-amz-target-completer-19 # required
  fleet_id: string # A unique identifier for the fleet to be deleted. You can use either the fleet ID or ARN value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteFleet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-fleet-locations" [
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
  --x-amz-target: string@x-amz-target-completer-20 # required
  fleet_id: string # A unique identifier for the fleet to delete locations for. You can use either the fleet ID or ARN value.
  locations: list<string> # The list of fleet locations to delete. Specify locations in the form of an Amazon Web Services Region code, such as us-west-2.
]: any -> oneof<record<FleetId: string, FleetArn: string, LocationStates: table<Location: string, Status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteFleetLocations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Locations": $locations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-game-server-group" [
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
  --x-amz-target: string@x-amz-target-completer-21 # required
  game_server_group_name: string # A unique identifier for the game server group. Use either the name or ARN value.
  --delete-option: string@delete-option-completer # The type of delete to perform. Options include the following: SAFE_DELETE – (default) Terminates the game server group and Amazon EC2 Auto Scaling group only when it has no game servers that are in UTILIZED status. FORCE_DELETE – Terminates the game server group, including all active game servers regardless of their utilization status, and the Amazon EC2 Auto Scaling group. RETAIN – Does a safe delete of the game server group but retains the Amazon EC2 Auto Scaling group as is.
]: any -> oneof<record<GameServerGroup: record<GameServerGroupName: string, GameServerGroupArn: string, RoleArn: string, InstanceDefinitions: list<record>, BalancingStrategy: string, GameServerProtectionPolicy: string, AutoScalingGroupArn: string, Status: string, StatusReason: string, SuspendedActions: list<string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteGameServerGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "DeleteOption": $delete_option} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-game-session-queue" [
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
  --x-amz-target: string@x-amz-target-completer-22 # required
  name: string # A descriptive label that is associated with game session queue. Queue names must be unique within each Region. You can use either the queue ID or ARN value.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteGameSessionQueue")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-location" [
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
  --x-amz-target: string@x-amz-target-completer-23 # required
  location_name: string # The location name of the custom location to be deleted.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteLocation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LocationName": $location_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-matchmaking-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-24 # required
  name: string # A unique identifier for the matchmaking configuration. You can use either the configuration name or ARN value.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteMatchmakingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-matchmaking-rule-set" [
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
  --x-amz-target: string@x-amz-target-completer-25 # required
  name: string # A unique identifier for the matchmaking rule set to be deleted. (Note: The rule set name is different from the optional "name" field in the rule set body.) You can use either the rule set name or ARN value.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteMatchmakingRuleSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-scaling-policy" [
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
  --x-amz-target: string@x-amz-target-completer-26 # required
  name: string # A descriptive label that is associated with a fleet's scaling policy. Policy names do not need to be unique.
  fleet_id: string # A unique identifier for the fleet to be deleted. You can use either the fleet ID or ARN value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteScalingPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "FleetId": $fleet_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-script" [
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
  --x-amz-target: string@x-amz-target-completer-27 # required
  script_id: string # A unique identifier for the Realtime script to delete. You can use either the script ID or ARN value.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteScript")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScriptId": $script_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-vpc-peering-authorization" [
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
  --x-amz-target: string@x-amz-target-completer-28 # required
  game_lift_aws_account_id: string # A unique identifier for the Amazon Web Services account that you use to manage your Amazon GameLift fleet. You can find your Account ID in the Amazon Web Services Management Console under account settings.
  peer_vpc_id: string # A unique identifier for a VPC with resources to be accessed by your Amazon GameLift fleet. The VPC must be in the same Region as your fleet. To look up a VPC ID, use the VPC Dashboard (https://console.aws.amazon.com/vpc/) in the Amazon Web Services Management Console. Learn more about VPC peering in VPC Peering with Amazon GameLift Fleets (https://docs.aws.amazon.com/gamelift/latest/developerguide/vpc-peering.html).
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteVpcPeeringAuthorization")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameLiftAwsAccountId": $game_lift_aws_account_id, "PeerVpcId": $peer_vpc_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "delete-vpc-peering-connection" [
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
  --x-amz-target: string@x-amz-target-completer-29 # required
  fleet_id: string # A unique identifier for the fleet. This fleet specified must match the fleet referenced in the VPC peering connection record. You can use either the fleet ID or ARN value.
  vpc_peering_connection_id: string # A unique identifier for a VPC peering connection.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeleteVpcPeeringConnection")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "VpcPeeringConnectionId": $vpc_peering_connection_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "deregister-compute" [
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
  --x-amz-target: string@x-amz-target-completer-30 # required
  fleet_id: string # >A unique identifier for the fleet the compute resource is registered to.
  compute_name: string # The name of the compute resource you want to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeregisterCompute")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "deregister-game-server" [
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
  --x-amz-target: string@x-amz-target-completer-31 # required
  game_server_group_name: string # A unique identifier for the game server group where the game server is running.
  game_server_id: string # A custom string that uniquely identifies the game server to deregister.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DeregisterGameServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-alias" [
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
  --x-amz-target: string@x-amz-target-completer-32 # required
  alias_id: string # The unique identifier for the fleet alias that you want to retrieve. You can use either the alias ID or ARN value.
]: any -> oneof<record<Alias: record<AliasId: string, Name: string, AliasArn: string, Description: string, RoutingStrategy: record<Type: string, FleetId: string, Message: string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeAlias")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AliasId": $alias_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-build" [
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
  --x-amz-target: string@x-amz-target-completer-33 # required
  build_id: string # A unique identifier for the build to retrieve properties for. You can use either the build ID or ARN value.
]: any -> oneof<record<Build: record<BuildId: string, BuildArn: string, Name: string, Version: string, Status: string, SizeOnDisk: int, OperatingSystem: string, CreationTime: string, ServerSdkVersion: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeBuild")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BuildId": $build_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-compute" [
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
  --x-amz-target: string@x-amz-target-completer-34 # required
  fleet_id: string # A unique identifier for the fleet the compute is registered to.
  compute_name: string # A descriptive label that is associated with the compute resource registered to your fleet.
]: any -> oneof<record<Compute: record<FleetId: string, FleetArn: string, ComputeName: string, ComputeArn: string, IpAddress: string, DnsName: string, ComputeStatus: string, Location: string, CreationTime: string, OperatingSystem: string, Type: string, GameLiftServiceSdkEndpoint: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeCompute")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-ec2-instance-limits" [
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
  --x-amz-target: string@x-amz-target-completer-35 # required
  --ec2-instance-type: string@ec2-instance-type-completer # Name of an Amazon EC2 instance type that is supported in Amazon GameLift. A fleet instance type determines the computing resources of each instance in the fleet, including CPU, memory, storage, and networking capacity. Do not specify a value for this parameter to retrieve limits for all instance types.
  --location: string # The name of a remote location to request instance limits for, in the form of an Amazon Web Services Region code such as us-west-2.
]: any -> oneof<record<EC2InstanceLimits: table<EC2InstanceType: string, CurrentInstances: int, InstanceLimit: int, Location: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeEC2InstanceLimits")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"EC2InstanceType": $ec2_instance_type, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-fleet-attributes" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  --fleet-ids: list<string> # A list of unique fleet identifiers to retrieve attributes for. You can use either the fleet ID or ARN value. To retrieve attributes for all current fleets, do not include this parameter.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. This parameter is ignored when the request specifies one or a list of fleet IDs. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. This parameter is ignored when the request specifies one or a list of fleet IDs. (spec name: NextToken)
]: any -> oneof<record<FleetAttributes: table<FleetId: string, FleetArn: string, FleetType: string, InstanceType: string, Description: string, Name: string, CreationTime: string, TerminationTime: string, Status: string, BuildId: string, BuildArn: string, ScriptId: string, ScriptArn: string, ServerLaunchPath: string, ServerLaunchParameters: string, LogPaths: list, NewGameSessionProtectionPolicy: string, OperatingSystem: string, ResourceCreationLimitPolicy: record, MetricGroups: list, StoppedActions: list, InstanceRoleArn: string, CertificateConfiguration: record, ComputeType: string, AnywhereConfiguration: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeFleetAttributes")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetIds": $fleet_ids, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-fleet-capacity" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  --fleet-ids: list<string> # A unique identifier for the fleet to retrieve capacity information for. You can use either the fleet ID or ARN value. Leave this parameter empty to retrieve capacity information for all fleets.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. This parameter is ignored when the request specifies one or a list of fleet IDs. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. This parameter is ignored when the request specifies one or a list of fleet IDs. (spec name: NextToken)
]: any -> oneof<record<FleetCapacity: table<FleetId: string, FleetArn: string, InstanceType: string, InstanceCounts: record, Location: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeFleetCapacity")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetIds": $fleet_ids, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-fleet-events" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  fleet_id: string # A unique identifier for the fleet to get event logs for. You can use either the fleet ID or ARN value.
  --start-time: string # The earliest date to retrieve event logs for. If no start time is specified, this call returns entries starting from when the fleet was created to the specified end time. Format is a number expressed in Unix time as milliseconds (ex: "1469498468.057"). (format: date-time)
  --end-time: string # The most recent date to retrieve event logs for. If no end time is specified, this call returns entries from the specified start time up to the present. Format is a number expressed in Unix time as milliseconds (ex: "1469498468.057"). (format: date-time)
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<Events: table<EventId: string, ResourceId: string, EventCode: string, Message: string, EventTime: string, PreSignedLogUrl: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeFleetEvents")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "StartTime": $start_time, "EndTime": $end_time, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-fleet-location-attributes" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  fleet_id: string # A unique identifier for the fleet to retrieve remote locations for. You can use either the fleet ID or ARN value.
  --locations: list<string> # A list of fleet locations to retrieve information for. Specify locations in the form of an Amazon Web Services Region code, such as us-west-2.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. This limit is not currently enforced. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<FleetId: string, FleetArn: string, LocationAttributes: table<LocationState: record, StoppedActions: list, UpdateStatus: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeFleetLocationAttributes")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "Locations": $locations, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-fleet-location-capacity" [
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
  --x-amz-target: string@x-amz-target-completer-40 # required
  fleet_id: string # A unique identifier for the fleet to request location capacity for. You can use either the fleet ID or ARN value.
  location: string # The fleet location to retrieve capacity information for. Specify a location in the form of an Amazon Web Services Region code, such as us-west-2.
]: any -> oneof<record<FleetCapacity: record<FleetId: string, FleetArn: string, InstanceType: string, InstanceCounts: record<DESIRED: int, MINIMUM: int, MAXIMUM: int, PENDING: int, ACTIVE: int, IDLE: int, TERMINATING: int>, Location: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeFleetLocationCapacity")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-fleet-location-utilization" [
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
  --x-amz-target: string@x-amz-target-completer-41 # required
  fleet_id: string # A unique identifier for the fleet to request location utilization for. You can use either the fleet ID or ARN value.
  location: string # The fleet location to retrieve utilization information for. Specify a location in the form of an Amazon Web Services Region code, such as us-west-2.
]: any -> oneof<record<FleetUtilization: record<FleetId: string, FleetArn: string, ActiveServerProcessCount: int, ActiveGameSessionCount: int, CurrentPlayerSessionCount: int, MaximumPlayerSessionCount: int, Location: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeFleetLocationUtilization")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-fleet-port-settings" [
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
  --x-amz-target: string@x-amz-target-completer-42 # required
  fleet_id: string # A unique identifier for the fleet to retrieve port settings for. You can use either the fleet ID or ARN value.
  --location: string # A remote location to check for status of port setting updates. Use the Amazon Web Services Region code format, such as us-west-2.
]: any -> oneof<record<FleetId: string, FleetArn: string, InboundPermissions: table<FromPort: int, ToPort: int, IpRange: string, Protocol: string>, UpdateStatus: string, Location: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeFleetPortSettings")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-fleet-utilization" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  --fleet-ids: list<string> # A unique identifier for the fleet to retrieve utilization data for. You can use either the fleet ID or ARN value. To retrieve attributes for all current fleets, do not include this parameter.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. This parameter is ignored when the request specifies one or a list of fleet IDs. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. This parameter is ignored when the request specifies one or a list of fleet IDs. (spec name: NextToken)
]: any -> oneof<record<FleetUtilization: table<FleetId: string, FleetArn: string, ActiveServerProcessCount: int, ActiveGameSessionCount: int, CurrentPlayerSessionCount: int, MaximumPlayerSessionCount: int, Location: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeFleetUtilization")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetIds": $fleet_ids, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-game-server" [
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
  --x-amz-target: string@x-amz-target-completer-44 # required
  game_server_group_name: string # A unique identifier for the game server group where the game server is running.
  game_server_id: string # A custom string that uniquely identifies the game server information to be retrieved.
]: any -> oneof<record<GameServer: record<GameServerGroupName: string, GameServerGroupArn: string, GameServerId: string, InstanceId: string, ConnectionInfo: string, GameServerData: string, ClaimStatus: string, UtilizationStatus: string, RegistrationTime: string, LastClaimTime: string, LastHealthCheckTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeGameServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-game-server-group" [
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
  --x-amz-target: string@x-amz-target-completer-45 # required
  game_server_group_name: string # A unique identifier for the game server group. Use either the name or ARN value.
]: any -> oneof<record<GameServerGroup: record<GameServerGroupName: string, GameServerGroupArn: string, RoleArn: string, InstanceDefinitions: list<record>, BalancingStrategy: string, GameServerProtectionPolicy: string, AutoScalingGroupArn: string, Status: string, StatusReason: string, SuspendedActions: list<string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeGameServerGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-game-server-instances" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  game_server_group_name: string # A unique identifier for the game server group. Use either the name or ARN value.
  --instance-ids: list<string> # The Amazon EC2 instance IDs that you want to retrieve status on. Amazon EC2 instance IDs use a 17-character format, for example: i-1234567890abcdef0. To retrieve all instances in the game server group, leave this parameter empty.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<GameServerInstances: table<GameServerGroupName: string, GameServerGroupArn: string, InstanceId: string, InstanceStatus: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeGameServerInstances")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "InstanceIds": $instance_ids, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-game-session-details" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  --fleet-id: string # A unique identifier for the fleet to retrieve all game sessions active on the fleet. You can use either the fleet ID or ARN value.
  --game-session-id: string # A unique identifier for the game session to retrieve.
  --alias-id: string # A unique identifier for the alias associated with the fleet to retrieve all game sessions for. You can use either the alias ID or ARN value.
  --location: string # A fleet location to get game session details for. You can specify a fleet's home Region or a remote location. Use the Amazon Web Services Region code format, such as us-west-2.
  --status-filter: string # Game session status to filter results on. Possible game session statuses include ACTIVE, TERMINATED, ACTIVATING and TERMINATING (the last two are transitory).
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<GameSessionDetails: table<GameSession: record, ProtectionPolicy: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeGameSessionDetails")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "GameSessionId": $game_session_id, "AliasId": $alias_id, "Location": $location, "StatusFilter": $status_filter, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-game-session-placement" [
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
  --x-amz-target: string@x-amz-target-completer-48 # required
  placement_id: string # A unique identifier for a game session placement to retrieve.
]: any -> oneof<record<GameSessionPlacement: record<PlacementId: string, GameSessionQueueName: string, Status: string, GameProperties: list<record>, MaximumPlayerSessionCount: int, GameSessionName: string, GameSessionId: string, GameSessionArn: string, GameSessionRegion: string, PlayerLatencies: list<record>, StartTime: string, EndTime: string, IpAddress: string, DnsName: string, Port: int, PlacedPlayerSessions: list<record>, GameSessionData: string, MatchmakerData: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeGameSessionPlacement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PlacementId": $placement_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-game-session-queues" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  --names: list<string> # A list of queue names to retrieve information for. You can use either the queue ID or ARN value. To request settings for all queues, leave this parameter empty.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. You can request up to 50 results. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<GameSessionQueues: table<Name: string, GameSessionQueueArn: string, TimeoutInSeconds: int, PlayerLatencyPolicies: list, Destinations: list, FilterConfiguration: record, PriorityConfiguration: record, CustomEventData: string, NotificationTarget: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeGameSessionQueues")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Names": $names, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-game-sessions" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --fleet-id: string # A unique identifier for the fleet to retrieve game sessions for. You can use either the fleet ID or ARN value.
  --game-session-id: string # A unique identifier for the game session to retrieve.
  --alias-id: string # A unique identifier for the alias associated with the fleet to retrieve game sessions for. You can use either the alias ID or ARN value.
  --location: string # A fleet location to get game sessions for. You can specify a fleet's home Region or a remote location. Use the Amazon Web Services Region code format, such as us-west-2.
  --status-filter: string # Game session status to filter results on. You can filter on the following states: ACTIVE, TERMINATED, ACTIVATING, and TERMINATING. The last two are transitory and used for only very brief periods of time.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<GameSessions: table<GameSessionId: string, Name: string, FleetId: string, FleetArn: string, CreationTime: string, TerminationTime: string, CurrentPlayerSessionCount: int, MaximumPlayerSessionCount: int, Status: string, StatusReason: string, GameProperties: list, IpAddress: string, DnsName: string, Port: int, PlayerSessionCreationPolicy: string, CreatorId: string, GameSessionData: string, MatchmakerData: string, Location: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeGameSessions")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "GameSessionId": $game_session_id, "AliasId": $alias_id, "Location": $location, "StatusFilter": $status_filter, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-instances" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  fleet_id: string # A unique identifier for the fleet to retrieve instance information for. You can use either the fleet ID or ARN value.
  --instance-id: string # A unique identifier for an instance to retrieve. Specify an instance ID or leave blank to retrieve all instances in the fleet.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
  --location: string # The name of a location to retrieve instance information for, in the form of an Amazon Web Services Region code such as us-west-2.
]: any -> oneof<record<Instances: table<FleetId: string, FleetArn: string, InstanceId: string, IpAddress: string, DnsName: string, OperatingSystem: string, Type: string, Status: string, CreationTime: string, Location: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeInstances")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "InstanceId": $instance_id, "Limit": $body_limit, "NextToken": $body_next_token, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-matchmaking" [
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
  --x-amz-target: string@x-amz-target-completer-52 # required
  ticket_ids: list<string> # A unique identifier for a matchmaking ticket. You can include up to 10 ID values.
]: any -> oneof<record<TicketList: table<TicketId: string, ConfigurationName: string, ConfigurationArn: string, Status: string, StatusReason: string, StatusMessage: string, StartTime: string, EndTime: string, Players: list, GameSessionConnectionInfo: record, EstimatedWaitTime: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeMatchmaking")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketIds": $ticket_ids} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-matchmaking-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  --names: list<string> # A unique identifier for the matchmaking configuration(s) to retrieve. You can use either the configuration name or ARN value. To request all existing configurations, leave this parameter empty.
  --rule-set-name: string # A unique identifier for the matchmaking rule set. You can use either the rule set name or ARN value. Use this parameter to retrieve all matchmaking configurations that use this rule set.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. This parameter is limited to 10. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<Configurations: table<Name: string, ConfigurationArn: string, Description: string, GameSessionQueueArns: list, RequestTimeoutSeconds: int, AcceptanceTimeoutSeconds: int, AcceptanceRequired: bool, RuleSetName: string, RuleSetArn: string, NotificationTarget: string, AdditionalPlayerCount: int, CustomEventData: string, CreationTime: string, GameProperties: list, GameSessionData: string, BackfillMode: string, FlexMatchMode: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeMatchmakingConfigurations")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Names": $names, "RuleSetName": $rule_set_name, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-matchmaking-rule-sets" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --names: list<string> # A list of one or more matchmaking rule set names to retrieve details for. (Note: The rule set name is different from the optional "name" field in the rule set body.) You can use either the rule set name or ARN value.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<RuleSets: table<RuleSetName: string, RuleSetArn: string, RuleSetBody: string, CreationTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeMatchmakingRuleSets")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Names": $names, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-player-sessions" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  --game-session-id: string # A unique identifier for the game session to retrieve player sessions for.
  --player-id: string # A unique identifier for a player to retrieve player sessions for.
  --player-session-id: string # A unique identifier for a player session to retrieve.
  --player-session-status-filter: string # Player session status to filter results on. Note that when a PlayerSessionId or PlayerId is provided in a DescribePlayerSessions request, then the PlayerSessionStatusFilter has no effect on the response. Possible player session statuses include the following: RESERVED -- The player session request has been received, but the player has not yet connected to the server process and/or been validated. ACTIVE -- The player has been validated by the server process and is currently connected. COMPLETED -- The player connection has been dropped. TIMEDOUT -- A player session request was received, but the player did not connect and/or was not validated within the timeout limit (60 seconds).
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. If a player session ID is specified, this parameter is ignored. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. If a player session ID is specified, this parameter is ignored. (spec name: NextToken)
]: any -> oneof<record<PlayerSessions: table<PlayerSessionId: string, PlayerId: string, GameSessionId: string, FleetId: string, FleetArn: string, CreationTime: string, TerminationTime: string, Status: string, IpAddress: string, DnsName: string, Port: int, PlayerData: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribePlayerSessions")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"GameSessionId": $game_session_id, "PlayerId": $player_id, "PlayerSessionId": $player_session_id, "PlayerSessionStatusFilter": $player_session_status_filter, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-runtime-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-56 # required
  fleet_id: string # A unique identifier for the fleet to get the runtime configuration for. You can use either the fleet ID or ARN value.
]: any -> oneof<record<RuntimeConfiguration: record<ServerProcesses: list<record>, MaxConcurrentGameSessionActivations: int, GameSessionActivationTimeoutSeconds: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeRuntimeConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-scaling-policies" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  fleet_id: string # A unique identifier for the fleet for which to retrieve scaling policies. You can use either the fleet ID or ARN value.
  --status-filter: string@status-filter-completer # Scaling policy status to filter results on. A scaling policy is only in force when in an ACTIVE status. ACTIVE -- The scaling policy is currently in force. UPDATEREQUESTED -- A request to update the scaling policy has been received. UPDATING -- A change is being made to the scaling policy. DELETEREQUESTED -- A request to delete the scaling policy has been received. DELETING -- The scaling policy is being deleted. DELETED -- The scaling policy has been deleted. ERROR -- An error occurred in creating the policy. It should be removed and recreated.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
  --location: string # The fleet location. If you don't specify this value, the response contains the scaling policies of every location in the fleet.
]: any -> oneof<record<ScalingPolicies: table<FleetId: string, FleetArn: string, Name: string, Status: string, ScalingAdjustment: int, ScalingAdjustmentType: string, ComparisonOperator: string, Threshold: float, EvaluationPeriods: int, MetricName: string, PolicyType: string, TargetConfiguration: record, UpdateStatus: string, Location: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeScalingPolicies")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "StatusFilter": $status_filter, "Limit": $body_limit, "NextToken": $body_next_token, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-script" [
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  script_id: string # A unique identifier for the Realtime script to retrieve properties for. You can use either the script ID or ARN value.
]: any -> oneof<record<Script: record<ScriptId: string, ScriptArn: string, Name: string, Version: string, SizeOnDisk: int, CreationTime: string, StorageLocation: record<Bucket: string, Key: string, RoleArn: string, ObjectVersion: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeScript")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScriptId": $script_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-vpc-peering-authorizations" [
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
  --x-amz-target: string@x-amz-target-completer-59 # required
  --body: record
]: any -> oneof<record<VpcPeeringAuthorizations: table<GameLiftAwsAccountId: string, PeerVpcAwsAccountId: string, PeerVpcId: string, CreationTime: string, ExpirationTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeVpcPeeringAuthorizations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "describe-vpc-peering-connections" [
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
  --x-amz-target: string@x-amz-target-completer-60 # required
  --fleet-id: string # A unique identifier for the fleet. You can use either the fleet ID or ARN value.
]: any -> oneof<record<VpcPeeringConnections: table<FleetId: string, FleetArn: string, IpV4CidrBlock: string, VpcPeeringConnectionId: string, Status: record, PeerVpcId: string, GameLiftVpcId: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.DescribeVpcPeeringConnections")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-compute-access" [
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
  --x-amz-target: string@x-amz-target-completer-61 # required
  fleet_id: string # A unique identifier for the fleet that the compute resource is registered to.
  compute_name: string # The name of the compute resource you are requesting credentials for.
]: any -> oneof<record<FleetId: string, FleetArn: string, ComputeName: string, ComputeArn: string, Credentials: record<AccessKeyId: string, SecretAccessKey: string, SessionToken: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.GetComputeAccess")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-compute-auth-token" [
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
  --x-amz-target: string@x-amz-target-completer-62 # required
  fleet_id: string # A unique identifier for the fleet that the compute is registered to.
  compute_name: string # The name of the compute resource you are requesting the authentication token for.
]: any -> oneof<record<FleetId: string, FleetArn: string, ComputeName: string, ComputeArn: string, AuthToken: string, ExpirationTimestamp: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.GetComputeAuthToken")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-game-session-log-url" [
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  game_session_id: string # A unique identifier for the game session to get logs for.
]: any -> oneof<record<PreSignedUrl: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.GetGameSessionLogUrl")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameSessionId": $game_session_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "get-instance-access" [
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  fleet_id: string # A unique identifier for the fleet that contains the instance you want access to. You can use either the fleet ID or ARN value. The fleet can be in any of the following statuses: ACTIVATING, ACTIVE, or ERROR. Fleets with an ERROR status may be accessible for a short time before they are deleted.
  instance_id: string # A unique identifier for the instance you want to get access to. You can access an instance in any status.
]: any -> oneof<record<InstanceAccess: record<FleetId: string, InstanceId: string, IpAddress: string, OperatingSystem: string, Credentials: record<UserName: string, Secret: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.GetInstanceAccess")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "InstanceId": $instance_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-aliases" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  --routing-strategy-type: string@routing-strategy-type-completer # The routing type to filter results on. Use this parameter to retrieve only aliases with a certain routing type. To retrieve all aliases, leave this parameter empty. Possible routing types include the following: SIMPLE -- The alias resolves to one specific fleet. Use this type when routing to active fleets. TERMINAL -- The alias does not resolve to a fleet but instead can be used to display a message to the user. A terminal alias throws a TerminalRoutingStrategyException with the RoutingStrategy (https://docs.aws.amazon.com/gamelift/latest/apireference/API_RoutingStrategy.html) message embedded.
  --name: string # A descriptive label that is associated with an alias. Alias names do not need to be unique.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<Aliases: table<AliasId: string, Name: string, AliasArn: string, Description: string, RoutingStrategy: record, CreationTime: string, LastUpdatedTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListAliases")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"RoutingStrategyType": $routing_strategy_type, "Name": $name, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-builds" [
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  --status: string@status-completer # Build status to filter results by. To retrieve all builds, leave this parameter empty. Possible build statuses include the following: INITIALIZED -- A new build has been defined, but no files have been uploaded. You cannot create fleets for builds that are in this status. When a build is successfully created, the build status is set to this value. READY -- The game build has been successfully uploaded. You can now create new fleets for this build. FAILED -- The game build upload failed. You cannot create new fleets for this build.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, don't specify a value. (spec name: NextToken)
]: any -> oneof<record<Builds: table<BuildId: string, BuildArn: string, Name: string, Version: string, Status: string, SizeOnDisk: int, OperatingSystem: string, CreationTime: string, ServerSdkVersion: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListBuilds")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Status": $status, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-compute" [
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  fleet_id: string # A unique identifier for the fleet the compute resources are registered to.
  --location: string # The name of the custom location that the compute resources are assigned to.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<ComputeList: table<FleetId: string, FleetArn: string, ComputeName: string, ComputeArn: string, IpAddress: string, DnsName: string, ComputeStatus: string, Location: string, CreationTime: string, OperatingSystem: string, Type: string, GameLiftServiceSdkEndpoint: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListCompute")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "Location": $location, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-fleets" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  --build-id: string # A unique identifier for the build to request fleets for. Use this parameter to return only fleets using a specified build. Use either the build ID or ARN value.
  --script-id: string # A unique identifier for the Realtime script to request fleets for. Use this parameter to return only fleets using a specified script. Use either the script ID or ARN value.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<FleetIds: list<string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListFleets")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"BuildId": $build_id, "ScriptId": $script_id, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-game-server-groups" [
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
  --x-amz-target: string@x-amz-target-completer-69 # required
  --body-limit: int # The game server groups' limit. (spec name: Limit)
  --body-next-token: string # Specify the pagination token from a previous request to retrieve the next page of results. (spec name: NextToken)
]: any -> oneof<record<GameServerGroups: table<GameServerGroupName: string, GameServerGroupArn: string, RoleArn: string, InstanceDefinitions: list, BalancingStrategy: string, GameServerProtectionPolicy: string, AutoScalingGroupArn: string, Status: string, StatusReason: string, SuspendedActions: list, CreationTime: string, LastUpdatedTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListGameServerGroups")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-game-servers" [
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
  --x-amz-target: string@x-amz-target-completer-70 # required
  game_server_group_name: string # An identifier for the game server group to retrieve a list of game servers from. Use either the name or ARN value.
  --sort-order: string@sort-order-completer # Indicates how to sort the returned data based on game server registration timestamp. Use ASCENDING to retrieve oldest game servers first, or use DESCENDING to retrieve newest game servers first. If this parameter is left empty, game servers are returned in no particular order.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<GameServers: table<GameServerGroupName: string, GameServerGroupArn: string, GameServerId: string, InstanceId: string, ConnectionInfo: string, GameServerData: string, ClaimStatus: string, UtilizationStatus: string, RegistrationTime: string, LastClaimTime: string, LastHealthCheckTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListGameServers")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "SortOrder": $sort_order, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-locations" [
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
  --x-amz-target: string@x-amz-target-completer-71 # required
  --filters: list<string> # Filters the list for AWS or CUSTOM locations.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<Locations: table<LocationName: string, LocationArn: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListLocations")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-scripts" [
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
  --x-amz-target: string@x-amz-target-completer-72 # required
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, don't specify a value. (spec name: NextToken)
]: any -> oneof<record<Scripts: table<ScriptId: string, ScriptArn: string, Name: string, Version: string, SizeOnDisk: int, CreationTime: string, StorageLocation: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListScripts")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "list-tags-for-resource" [
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
  --x-amz-target: string@x-amz-target-completer-73 # required
  resource_arn: string # The Amazon Resource Name (ARN (https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-arn-format.html)) that uniquely identifies the Amazon GameLift resource that you want to retrieve tags for. Amazon GameLift includes resource ARNs in the data object for the resource. You can retrieve the ARN by calling a List or Describe operation for the resource type.
]: any -> oneof<record<Tags: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "put-scaling-policy" [
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
  --x-amz-target: string@x-amz-target-completer-74 # required
  name: string # A descriptive label that is associated with a fleet's scaling policy. Policy names do not need to be unique. A fleet can have only one scaling policy with the same name.
  fleet_id: string # A unique identifier for the fleet to apply this policy to. You can use either the fleet ID or ARN value. The fleet cannot be in any of the following statuses: ERROR or DELETING.
  --scaling-adjustment: int # Amount of adjustment to make, based on the scaling adjustment type.
  --scaling-adjustment-type: string@scaling-adjustment-type-completer # The type of adjustment to make to a fleet's instance count: ChangeInCapacity -- add (or subtract) the scaling adjustment value from the current instance count. Positive values scale up while negative values scale down. ExactCapacity -- set the instance count to the scaling adjustment value. PercentChangeInCapacity -- increase or reduce the current instance count by the scaling adjustment, read as a percentage. Positive values scale up while negative values scale down; for example, a value of "-10" scales the fleet down by 10%.
  --threshold: float # Metric value used to trigger a scaling event. (format: double)
  --comparison-operator: string@comparison-operator-completer # Comparison operator to use when measuring the metric against the threshold value.
  --evaluation-periods: int # Length of time (in minutes) the metric must be at or beyond the threshold before a scaling event is triggered.
  metric_name: string@metric-name-completer # Name of the Amazon GameLift-defined metric that is used to trigger a scaling adjustment. For detailed descriptions of fleet metrics, see Monitor Amazon GameLift with Amazon CloudWatch (https://docs.aws.amazon.com/gamelift/latest/developerguide/monitoring-cloudwatch.html). ActivatingGameSessions -- Game sessions in the process of being created. ActiveGameSessions -- Game sessions that are currently running. ActiveInstances -- Fleet instances that are currently running at least one game session. AvailableGameSessions -- Additional game sessions that fleet could host simultaneously, given current capacity. AvailablePlayerSessions -- Empty player slots in currently active game sessions. This includes game sessions that are not currently accepting players. Reserved player slots are not included. CurrentPlayerSessions -- Player slots in active game sessions that are being used by a player or are reserved for a player. IdleInstances -- Active instances that are currently hosting zero game sessions. PercentAvailableGameSessions -- Unused percentage of the total number of game sessions that a fleet could host simultaneously, given current capacity. Use this metric for a target-based scaling policy. PercentIdleInstances -- Percentage of the total number of active instances that are hosting zero game sessions. QueueDepth -- Pending game session placement requests, in any queue, where the current fleet is the top-priority destination. WaitTime -- Current wait time for pending game session placement requests, in any queue, where the current fleet is the top-priority destination.
  --policy-type: string@policy-type-completer # The type of scaling policy to create. For a target-based policy, set the parameter MetricName to 'PercentAvailableGameSessions' and specify a TargetConfiguration. For a rule-based policy set the following parameters: MetricName, ComparisonOperator, Threshold, EvaluationPeriods, ScalingAdjustmentType, and ScalingAdjustment.
  --target-configuration: record # Settings for a target-based scaling policy. A target-based policy tracks a particular fleet metric specifies a target value for the metric. As player usage changes, the policy triggers Amazon GameLift to adjust capacity so that the metric returns to the target value. The target configuration specifies settings as needed for the target based policy, including the target value. — shape: {TargetValue: float}
]: any -> oneof<record<Name: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.PutScalingPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "FleetId": $fleet_id, "ScalingAdjustment": $scaling_adjustment, "ScalingAdjustmentType": $scaling_adjustment_type, "Threshold": $threshold, "ComparisonOperator": $comparison_operator, "EvaluationPeriods": $evaluation_periods, "MetricName": $metric_name, "PolicyType": $policy_type, "TargetConfiguration": $target_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "register-compute" [
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
  --x-amz-target: string@x-amz-target-completer-75 # required
  fleet_id: string # A unique identifier for the fleet to register the compute to. You can use either the fleet ID or ARN value.
  compute_name: string # A descriptive label that is associated with the compute resource registered to your fleet.
  --certificate-path: string # The path to the TLS certificate on your compute resource. The path and certificate are not validated by Amazon GameLift.
  --dns-name: string # The DNS name of the compute resource. Amazon GameLift requires the DNS name or IP address to manage your compute resource.
  --ip-address: string # The IP address of the compute resource. Amazon GameLift requires the DNS name or IP address to manage your compute resource.
  --location: string # The name of the custom location you added to the fleet you are registering this compute resource to.
]: any -> oneof<record<Compute: record<FleetId: string, FleetArn: string, ComputeName: string, ComputeArn: string, IpAddress: string, DnsName: string, ComputeStatus: string, Location: string, CreationTime: string, OperatingSystem: string, Type: string, GameLiftServiceSdkEndpoint: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.RegisterCompute")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "ComputeName": $compute_name, "CertificatePath": $certificate_path, "DnsName": $dns_name, "IpAddress": $ip_address, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "register-game-server" [
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
  --x-amz-target: string@x-amz-target-completer-76 # required
  game_server_group_name: string # A unique identifier for the game server group where the game server is running.
  game_server_id: string # A custom string that uniquely identifies the game server to register. Game server IDs are developer-defined and must be unique across all game server groups in your Amazon Web Services account.
  instance_id: string # The unique identifier for the instance where the game server is running. This ID is available in the instance metadata. EC2 instance IDs use a 17-character format, for example: i-1234567890abcdef0.
  --connection-info: string # Information that is needed to make inbound client connections to the game server. This might include the IP address and port, DNS name, and other information.
  --game-server-data: string # A set of custom game server properties, formatted as a single string value. This data is passed to a game client or service when it requests information on game servers.
]: any -> oneof<record<GameServer: record<GameServerGroupName: string, GameServerGroupArn: string, GameServerId: string, InstanceId: string, ConnectionInfo: string, GameServerData: string, ClaimStatus: string, UtilizationStatus: string, RegistrationTime: string, LastClaimTime: string, LastHealthCheckTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.RegisterGameServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id, "InstanceId": $instance_id, "ConnectionInfo": $connection_info, "GameServerData": $game_server_data} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "request-upload-credentials" [
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
  --x-amz-target: string@x-amz-target-completer-77 # required
  build_id: string # A unique identifier for the build to get credentials for. You can use either the build ID or ARN value.
]: any -> oneof<record<UploadCredentials: record<AccessKeyId: string, SecretAccessKey: string, SessionToken: string>, StorageLocation: record<Bucket: string, Key: string, RoleArn: string, ObjectVersion: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.RequestUploadCredentials")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BuildId": $build_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "resolve-alias" [
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
  --x-amz-target: string@x-amz-target-completer-78 # required
  alias_id: string # The unique identifier of the alias that you want to retrieve a fleet ID for. You can use either the alias ID or ARN value.
]: any -> oneof<record<FleetId: string, FleetArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ResolveAlias")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AliasId": $alias_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "resume-game-server-group" [
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
  --x-amz-target: string@x-amz-target-completer-79 # required
  game_server_group_name: string # A unique identifier for the game server group. Use either the name or ARN value.
  resume_actions: list<string> # The activity to resume for this game server group.
]: any -> oneof<record<GameServerGroup: record<GameServerGroupName: string, GameServerGroupArn: string, RoleArn: string, InstanceDefinitions: list<record>, BalancingStrategy: string, GameServerProtectionPolicy: string, AutoScalingGroupArn: string, Status: string, StatusReason: string, SuspendedActions: list<string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ResumeGameServerGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "ResumeActions": $resume_actions} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "search-game-sessions" [
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
  --x-amz-target: string@x-amz-target-completer-80 # required
  --fleet-id: string # A unique identifier for the fleet to search for active game sessions. You can use either the fleet ID or ARN value. Each request must reference either a fleet ID or alias ID, but not both.
  --alias-id: string # A unique identifier for the alias associated with the fleet to search for active game sessions. You can use either the alias ID or ARN value. Each request must reference either a fleet ID or alias ID, but not both.
  --location: string # A fleet location to search for game sessions. You can specify a fleet's home Region or a remote location. Use the Amazon Web Services Region code format, such as us-west-2.
  --filter-expression: string # String containing the search criteria for the session search. If no filter expression is included, the request returns results for all game sessions in the fleet that are in ACTIVE status. A filter expression can contain one or multiple conditions. Each condition consists of the following: Operand -- Name of a game session attribute. Valid values are gameSessionName, gameSessionId, gameSessionProperties, maximumSessions, creationTimeMillis, playerSessionCount, hasAvailablePlayerSessions. Comparator -- Valid comparators are: =, <>, <, >, <=, >=. Value -- Value to be searched for. Values may be numbers, boolean values (true/false) or strings depending on the operand. String values are case sensitive and must be enclosed in single quotes. Special characters must be escaped. Boolean and string values can only be used with the comparators = and <>. For example, the following filter expression searches on gameSessionName: "FilterExpression": "gameSessionName = 'Matt\\'s Awesome Game 1'". To chain multiple conditions in a single expression, use the logical keywords AND, OR, and NOT and parentheses as needed. For example: x AND y AND NOT z, NOT (x OR y). Session search evaluates conditions from left to right using the following precedence rules: =, <>, <, >, <=, >= Parentheses NOT AND OR For example, this filter expression retrieves game sessions hosting at least ten players that have an open player slot: "maximumSessions>=10 AND hasAvailablePlayerSessions=true".
  --sort-expression: string # Instructions on how to sort the search results. If no sort expression is included, the request returns results in random order. A sort expression consists of the following elements: Operand -- Name of a game session attribute. Valid values are gameSessionName, gameSessionId, gameSessionProperties, maximumSessions, creationTimeMillis, playerSessionCount, hasAvailablePlayerSessions. Order -- Valid sort orders are ASC (ascending) and DESC (descending). For example, this sort expression returns the oldest active sessions first: "SortExpression": "creationTimeMillis ASC". Results with a null value for the sort operand are returned at the end of the list.
  --body-limit: int # The maximum number of results to return. Use this parameter with NextToken to get results as a set of sequential pages. The maximum number of results returned is 20, even if this value is not set or is set higher than 20. (spec name: Limit)
  --body-next-token: string # A token that indicates the start of the next sequential page of results. Use the token that is returned with a previous call to this operation. To start at the beginning of the result set, do not specify a value. (spec name: NextToken)
]: any -> oneof<record<GameSessions: table<GameSessionId: string, Name: string, FleetId: string, FleetArn: string, CreationTime: string, TerminationTime: string, CurrentPlayerSessionCount: int, MaximumPlayerSessionCount: int, Status: string, StatusReason: string, GameProperties: list, IpAddress: string, DnsName: string, Port: int, PlayerSessionCreationPolicy: string, CreatorId: string, GameSessionData: string, MatchmakerData: string, Location: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.SearchGameSessions")
  let qp = [(serialize-qp "Limit" $limit "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"FleetId": $fleet_id, "AliasId": $alias_id, "Location": $location, "FilterExpression": $filter_expression, "SortExpression": $sort_expression, "Limit": $body_limit, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "start-fleet-actions" [
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
  --x-amz-target: string@x-amz-target-completer-81 # required
  fleet_id: string # A unique identifier for the fleet to restart actions on. You can use either the fleet ID or ARN value.
  actions: list<string> # List of actions to restart on the fleet.
  --location: string # The fleet location to restart fleet actions for. Specify a location in the form of an Amazon Web Services Region code, such as us-west-2.
]: any -> oneof<record<FleetId: string, FleetArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.StartFleetActions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Actions": $actions, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "start-game-session-placement" [
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
  --x-amz-target: string@x-amz-target-completer-82 # required
  placement_id: string # A unique identifier to assign to the new game session placement. This value is developer-defined. The value must be unique across all Regions and cannot be reused.
  game_session_queue_name: string # Name of the queue to use to place the new game session. You can use either the queue name or ARN value.
  --game-properties: list # A set of custom properties for a game session, formatted as key:value pairs. These properties are passed to a game server process with a request to start a new game session (see Start a Game Session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession)). — item shape: {Key: string, Value: string}
  maximum_player_session_count: int # The maximum number of players that can be connected simultaneously to the game session.
  --game-session-name: string # A descriptive label that is associated with a game session. Session names do not need to be unique.
  --player-latencies: list # A set of values, expressed in milliseconds, that indicates the amount of latency that a player experiences when connected to Amazon Web Services Regions. This information is used to try to place the new game session where it can offer the best possible gameplay experience for the players. — item shape: {PlayerId?: string, RegionIdentifier?: string, LatencyInMilliseconds?: float}
  --desired-player-sessions: list # Set of information on each player to create a player session for. — item shape: {PlayerId?: string, PlayerData?: string}
  --game-session-data: string # A set of custom game session properties, formatted as a single string value. This data is passed to a game server process in the GameSession object with a request to start a new game session (see Start a Game Session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession)).
]: any -> oneof<record<GameSessionPlacement: record<PlacementId: string, GameSessionQueueName: string, Status: string, GameProperties: list<record>, MaximumPlayerSessionCount: int, GameSessionName: string, GameSessionId: string, GameSessionArn: string, GameSessionRegion: string, PlayerLatencies: list<record>, StartTime: string, EndTime: string, IpAddress: string, DnsName: string, Port: int, PlacedPlayerSessions: list<record>, GameSessionData: string, MatchmakerData: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.StartGameSessionPlacement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PlacementId": $placement_id, "GameSessionQueueName": $game_session_queue_name, "GameProperties": $game_properties, "MaximumPlayerSessionCount": $maximum_player_session_count, "GameSessionName": $game_session_name, "PlayerLatencies": $player_latencies, "DesiredPlayerSessions": $desired_player_sessions, "GameSessionData": $game_session_data} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "start-match-backfill" [
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
  --x-amz-target: string@x-amz-target-completer-83 # required
  --ticket-id: string # A unique identifier for a matchmaking ticket. If no ticket ID is specified here, Amazon GameLift will generate one in the form of a UUID. Use this identifier to track the match backfill ticket status and retrieve match results.
  configuration_name: string # Name of the matchmaker to use for this request. You can use either the configuration name or ARN value. The ARN of the matchmaker that was used with the original game session is listed in the GameSession object, MatchmakerData property.
  --game-session-arn: string # A unique identifier for the game session. Use the game session ID. When using FlexMatch as a standalone matchmaking solution, this parameter is not needed.
  players: list # Match information on all players that are currently assigned to the game session. This information is used by the matchmaker to find new players and add them to the existing game. You can include up to 199 Players in a StartMatchBackfill request. PlayerID, PlayerAttributes, Team -- This information is maintained in the GameSession object, MatchmakerData property, for all players who are currently assigned to the game session. The matchmaker data is in JSON syntax, formatted as a string. For more details, see Match Data (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-server.html#match-server-data). The backfill request must specify the team membership for every player. Do not specify team if you are not using backfill. LatencyInMs -- If the matchmaker uses player latency, include a latency value, in milliseconds, for the Region that the game session is currently in. Do not include latency values for any other Region. — item shape: {PlayerId?: string, PlayerAttributes?: record, Team?: string, LatencyInMs?: record}
]: any -> oneof<record<MatchmakingTicket: record<TicketId: string, ConfigurationName: string, ConfigurationArn: string, Status: string, StatusReason: string, StatusMessage: string, StartTime: string, EndTime: string, Players: list<record>, GameSessionConnectionInfo: record<GameSessionArn: string, IpAddress: string, DnsName: string, Port: int, MatchedPlayerSessions: list>, EstimatedWaitTime: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.StartMatchBackfill")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketId": $ticket_id, "ConfigurationName": $configuration_name, "GameSessionArn": $game_session_arn, "Players": $players} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "start-matchmaking" [
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
  --x-amz-target: string@x-amz-target-completer-84 # required
  --ticket-id: string # A unique identifier for a matchmaking ticket. If no ticket ID is specified here, Amazon GameLift will generate one in the form of a UUID. Use this identifier to track the matchmaking ticket status and retrieve match results.
  configuration_name: string # Name of the matchmaking configuration to use for this request. Matchmaking configurations must exist in the same Region as this request. You can use either the configuration name or ARN value.
  players: list # Information on each player to be matched. This information must include a player ID, and may contain player attributes and latency data to be used in the matchmaking process. After a successful match, Player objects contain the name of the team the player is assigned to. You can include up to 10 Players in a StartMatchmaking request. — item shape: {PlayerId?: string, PlayerAttributes?: record, Team?: string, LatencyInMs?: record}
]: any -> oneof<record<MatchmakingTicket: record<TicketId: string, ConfigurationName: string, ConfigurationArn: string, Status: string, StatusReason: string, StatusMessage: string, StartTime: string, EndTime: string, Players: list<record>, GameSessionConnectionInfo: record<GameSessionArn: string, IpAddress: string, DnsName: string, Port: int, MatchedPlayerSessions: list>, EstimatedWaitTime: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.StartMatchmaking")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketId": $ticket_id, "ConfigurationName": $configuration_name, "Players": $players} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "stop-fleet-actions" [
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
  --x-amz-target: string@x-amz-target-completer-85 # required
  fleet_id: string # A unique identifier for the fleet to stop actions on. You can use either the fleet ID or ARN value.
  actions: list<string> # List of actions to suspend on the fleet.
  --location: string # The fleet location to stop fleet actions for. Specify a location in the form of an Amazon Web Services Region code, such as us-west-2.
]: any -> oneof<record<FleetId: string, FleetArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.StopFleetActions")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Actions": $actions, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "stop-game-session-placement" [
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
  --x-amz-target: string@x-amz-target-completer-86 # required
  placement_id: string # A unique identifier for a game session placement to stop.
]: any -> oneof<record<GameSessionPlacement: record<PlacementId: string, GameSessionQueueName: string, Status: string, GameProperties: list<record>, MaximumPlayerSessionCount: int, GameSessionName: string, GameSessionId: string, GameSessionArn: string, GameSessionRegion: string, PlayerLatencies: list<record>, StartTime: string, EndTime: string, IpAddress: string, DnsName: string, Port: int, PlacedPlayerSessions: list<record>, GameSessionData: string, MatchmakerData: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.StopGameSessionPlacement")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PlacementId": $placement_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "stop-matchmaking" [
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
  --x-amz-target: string@x-amz-target-completer-87 # required
  ticket_id: string # A unique identifier for a matchmaking ticket.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.StopMatchmaking")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TicketId": $ticket_id} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "suspend-game-server-group" [
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
  --x-amz-target: string@x-amz-target-completer-88 # required
  game_server_group_name: string # A unique identifier for the game server group. Use either the name or ARN value.
  suspend_actions: list<string> # The activity to suspend for this game server group.
]: any -> oneof<record<GameServerGroup: record<GameServerGroupName: string, GameServerGroupArn: string, RoleArn: string, InstanceDefinitions: list<record>, BalancingStrategy: string, GameServerProtectionPolicy: string, AutoScalingGroupArn: string, Status: string, StatusReason: string, SuspendedActions: list<string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.SuspendGameServerGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "SuspendActions": $suspend_actions} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "tag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-89 # required
  resource_arn: string # The Amazon Resource Name (ARN (https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-arn-format.html)) that uniquely identifies the Amazon GameLift resource that you want to assign tags to. Amazon GameLift includes resource ARNs in the data object for the resource. You can retrieve the ARN by calling a List or Describe operation for the resource type.
  tags: list # A list of one or more tags to assign to the specified Amazon GameLift resource. Tags are developer-defined and structured as key-value pairs. The maximum tag limit may be lower than stated. See Tagging Amazon Web Services Resources (https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html) for tagging limits. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.TagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "untag-resource" [
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
  --x-amz-target: string@x-amz-target-completer-90 # required
  resource_arn: string # The Amazon Resource Name (ARN (https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-arn-format.html)) that uniquely identifies the Amazon GameLift resource that you want to remove tags from. Amazon GameLift includes resource ARNs in the data object for the resource. You can retrieve the ARN by calling a List or Describe operation for the resource type.
  tag_keys: list<string> # A list of one or more tag keys to remove from the specified Amazon GameLift resource.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UntagResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceARN": $resource_arn, "TagKeys": $tag_keys} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-alias" [
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
  --x-amz-target: string@x-amz-target-completer-91 # required
  alias_id: string # A unique identifier for the alias that you want to update. You can use either the alias ID or ARN value.
  --name: string # A descriptive label that is associated with an alias. Alias names do not need to be unique.
  --description: string # A human-readable description of the alias.
  --routing-strategy: record # The routing configuration for a fleet alias. Related actions All APIs by task (https://docs.aws.amazon.com/gamelift/latest/developerguide/reference-awssdk.html#reference-awssdk-resources-fleets) — shape: {Type?: "SIMPLE"|"TERMINAL", FleetId?: string, Message?: string}
]: any -> oneof<record<Alias: record<AliasId: string, Name: string, AliasArn: string, Description: string, RoutingStrategy: record<Type: string, FleetId: string, Message: string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateAlias")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AliasId": $alias_id, "Name": $name, "Description": $description, "RoutingStrategy": $routing_strategy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-build" [
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
  --x-amz-target: string@x-amz-target-completer-92 # required
  build_id: string # A unique identifier for the build to update. You can use either the build ID or ARN value.
  --name: string # A descriptive label associated with a build. Build names don't need to be unique.
  --version: string # Version information associated with a build or script. Version strings don't need to be unique.
]: any -> oneof<record<Build: record<BuildId: string, BuildArn: string, Name: string, Version: string, Status: string, SizeOnDisk: int, OperatingSystem: string, CreationTime: string, ServerSdkVersion: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateBuild")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BuildId": $build_id, "Name": $name, "Version": $version} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-fleet-attributes" [
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
  --x-amz-target: string@x-amz-target-completer-93 # required
  fleet_id: string # A unique identifier for the fleet to update attribute metadata for. You can use either the fleet ID or ARN value.
  --name: string # A descriptive label that is associated with a fleet. Fleet names do not need to be unique.
  --description: string # A human-readable description of a fleet.
  --new-game-session-protection-policy: string@new-game-session-protection-policy-completer # The game session protection policy to apply to all new instances created in this fleet. Instances that already exist are not affected. You can set protection for individual instances using UpdateGameSession (https://docs.aws.amazon.com/gamelift/latest/apireference/API_UpdateGameSession.html) . NoProtection -- The game session can be terminated during a scale-down event. FullProtection -- If the game session is in an ACTIVE status, it cannot be terminated during a scale-down event.
  --resource-creation-limit-policy: record # A policy that puts limits on the number of game sessions that a player can create within a specified span of time. With this policy, you can control players' ability to consume available resources. The policy is evaluated when a player tries to create a new game session. On receiving a CreateGameSession request, Amazon GameLift checks that the player (identified by CreatorId) has created fewer than game session limit in the specified time period. — shape: {NewGameSessionsPerCreator?: int, PolicyPeriodInMinutes?: int}
  --metric-groups: list<string> # The name of a metric group to add this fleet to. Use a metric group in Amazon CloudWatch to aggregate the metrics from multiple fleets. Provide an existing metric group name, or create a new metric group by providing a new name. A fleet can only be in one metric group at a time.
  --anywhere-configuration: record # Amazon GameLift Anywhere configuration options for your Anywhere fleets. — shape: {Cost: string}
]: any -> oneof<record<FleetId: string, FleetArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateFleetAttributes")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "Name": $name, "Description": $description, "NewGameSessionProtectionPolicy": $new_game_session_protection_policy, "ResourceCreationLimitPolicy": $resource_creation_limit_policy, "MetricGroups": $metric_groups, "AnywhereConfiguration": $anywhere_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-fleet-capacity" [
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
  --x-amz-target: string@x-amz-target-completer-94 # required
  fleet_id: string # A unique identifier for the fleet to update capacity settings for. You can use either the fleet ID or ARN value.
  --desired-instances: int # The number of Amazon EC2 instances you want to maintain in the specified fleet location. This value must fall between the minimum and maximum size limits.
  --min-size: int # The minimum number of instances that are allowed in the specified fleet location. If this parameter is not set, the default is 0.
  --max-size: int # The maximum number of instances that are allowed in the specified fleet location. If this parameter is not set, the default is 1.
  --location: string # The name of a remote location to update fleet capacity settings for, in the form of an Amazon Web Services Region code such as us-west-2.
]: any -> oneof<record<FleetId: string, FleetArn: string, Location: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateFleetCapacity")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "DesiredInstances": $desired_instances, "MinSize": $min_size, "MaxSize": $max_size, "Location": $location} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-fleet-port-settings" [
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
  --x-amz-target: string@x-amz-target-completer-95 # required
  fleet_id: string # A unique identifier for the fleet to update port settings for. You can use either the fleet ID or ARN value.
  --inbound-permission-authorizations: list # A collection of port settings to be added to the fleet resource. — item shape: {FromPort: int, ToPort: int, IpRange: string, Protocol: "TCP"|"UDP"}
  --inbound-permission-revocations: list # A collection of port settings to be removed from the fleet resource. — item shape: {FromPort: int, ToPort: int, IpRange: string, Protocol: "TCP"|"UDP"}
]: any -> oneof<record<FleetId: string, FleetArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateFleetPortSettings")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "InboundPermissionAuthorizations": $inbound_permission_authorizations, "InboundPermissionRevocations": $inbound_permission_revocations} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-game-server" [
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
  --x-amz-target: string@x-amz-target-completer-96 # required
  game_server_group_name: string # A unique identifier for the game server group where the game server is running.
  game_server_id: string # A custom string that uniquely identifies the game server to update.
  --game-server-data: string # A set of custom game server properties, formatted as a single string value. This data is passed to a game client or service when it requests information on game servers.
  --utilization-status: string@utilization-status-completer # Indicates whether the game server is available or is currently hosting gameplay.
  --health-check: string@health-check-completer # Indicates health status of the game server. A request that includes this parameter updates the game server's LastHealthCheckTime timestamp.
]: any -> oneof<record<GameServer: record<GameServerGroupName: string, GameServerGroupArn: string, GameServerId: string, InstanceId: string, ConnectionInfo: string, GameServerData: string, ClaimStatus: string, UtilizationStatus: string, RegistrationTime: string, LastClaimTime: string, LastHealthCheckTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateGameServer")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "GameServerId": $game_server_id, "GameServerData": $game_server_data, "UtilizationStatus": $utilization_status, "HealthCheck": $health_check} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-game-server-group" [
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
  --x-amz-target: string@x-amz-target-completer-97 # required
  game_server_group_name: string # A unique identifier for the game server group. Use either the name or ARN value.
  --role-arn: string # The Amazon Resource Name (ARN (https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-arn-format.html)) for an IAM role that allows Amazon GameLift to access your Amazon EC2 Auto Scaling groups.
  --instance-definitions: list # An updated list of Amazon EC2 instance types to use in the Auto Scaling group. The instance definitions must specify at least two different instance types that are supported by Amazon GameLift FleetIQ. This updated list replaces the entire current list of instance definitions for the game server group. For more information on instance types, see EC2 Instance Types (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html) in the Amazon EC2 User Guide. You can optionally specify capacity weighting for each instance type. If no weight value is specified for an instance type, it is set to the default value "1". For more information about capacity weighting, see Instance Weighting for Amazon EC2 Auto Scaling (https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-weighting.html) in the Amazon EC2 Auto Scaling User Guide. — item shape: {InstanceType: "c4.large"|"c4.xlarge"|"c4.2xlarge"|"c4.4xlarge"|"c4.8xlarge"|"c5.large"|"c5.xlarge"|"c5.2xlarge"|"c5.4xlarge"|"c5.9xlarge"|"c5.12xlarge"|"c5.18xlarge"|"c5.24xlarge"|"c5a.large"|"c5a.xlarge"|"c5a.2xlarge"|"c5a.4xlarge"|"c5a.8xlarge"|"c5a.12xlarge"|"c5a.16xlarge"|"c5a.24xlarge"|"c6g.medium"|"c6g.large"|"c6g.xlarge"|"c6g.2xlarge"|"c6g.4xlarge"|"c6g.8xlarge"|"c6g.12xlarge"|"c6g.16xlarge"|"r4.large"|"r4.xlarge"|"r4.2xlarge"|"r4.4xlarge"|"r4.8xlarge"|"r4.16xlarge"|"r5.large"|"r5.xlarge"|"r5.2xlarge"|"r5.4xlarge"|"r5.8xlarge"|"r5.12xlarge"|"r5.16xlarge"|"r5.24xlarge"|"r5a.large"|"r5a.xlarge"|"r5a.2xlarge"|"r5a.4xlarge"|"r5a.8xlarge"|"r5a.12xlarge"|"r5a.16xlarge"|"r5a.24xlarge"|"r6g.medium"|"r6g.large"|"r6g.xlarge"|"r6g.2xlarge"|"r6g.4xlarge"|"r6g.8xlarge"|"r6g.12xlarge"|"r6g.16xlarge"|"m4.large"|"m4.xlarge"|"m4.2xlarge"|"m4.4xlarge"|"m4.10xlarge"|"m5.large"|"m5.xlarge"|"m5.2xlarge"|"m5.4xlarge"|"m5.8xlarge"|"m5.12xlarge"|"m5.16xlarge"|"m5.24xlarge"|"m5a.large"|"m5a.xlarge"|"m5a.2xlarge"|"m5a.4xlarge"|"m5a.8xlarge"|"m5a.12xlarge"|"m5a.16xlarge"|"m5a.24xlarge"|"m6g.medium"|"m6g.large"|"m6g.xlarge"|"m6g.2xlarge"|"m6g.4xlarge"|"m6g.8xlarge"|"m6g.12xlarge"|"m6g.16xlarge", ... (1 more fields)}
  --game-server-protection-policy: string@game-server-protection-policy-completer # A flag that indicates whether instances in the game server group are protected from early termination. Unprotected instances that have active game servers running might be terminated during a scale-down event, causing players to be dropped from the game. Protected instances cannot be terminated while there are active game servers running except in the event of a forced game server group deletion (see ). An exception to this is with Spot Instances, which can be terminated by Amazon Web Services regardless of protection status. This property is set to NO_PROTECTION by default.
  --balancing-strategy: string@balancing-strategy-completer # Indicates how Amazon GameLift FleetIQ balances the use of Spot Instances and On-Demand Instances in the game server group. Method options include the following: SPOT_ONLY - Only Spot Instances are used in the game server group. If Spot Instances are unavailable or not viable for game hosting, the game server group provides no hosting capacity until Spot Instances can again be used. Until then, no new instances are started, and the existing nonviable Spot Instances are terminated (after current gameplay ends) and are not replaced. SPOT_PREFERRED - (default value) Spot Instances are used whenever available in the game server group. If Spot Instances are unavailable, the game server group continues to provide hosting capacity by falling back to On-Demand Instances. Existing nonviable Spot Instances are terminated (after current gameplay ends) and are replaced with new On-Demand Instances. ON_DEMAND_ONLY - Only On-Demand Instances are used in the game server group. No Spot Instances are used, even when available, while this balancing strategy is in force.
]: any -> oneof<record<GameServerGroup: record<GameServerGroupName: string, GameServerGroupArn: string, RoleArn: string, InstanceDefinitions: list<record>, BalancingStrategy: string, GameServerProtectionPolicy: string, AutoScalingGroupArn: string, Status: string, StatusReason: string, SuspendedActions: list<string>, CreationTime: string, LastUpdatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateGameServerGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameServerGroupName": $game_server_group_name, "RoleArn": $role_arn, "InstanceDefinitions": $instance_definitions, "GameServerProtectionPolicy": $game_server_protection_policy, "BalancingStrategy": $balancing_strategy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-game-session" [
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
  --x-amz-target: string@x-amz-target-completer-98 # required
  game_session_id: string # A unique identifier for the game session to update.
  --maximum-player-session-count: int # The maximum number of players that can be connected simultaneously to the game session.
  --name: string # A descriptive label that is associated with a game session. Session names do not need to be unique.
  --player-session-creation-policy: string@player-session-creation-policy-completer # A policy that determines whether the game session is accepting new players.
  --protection-policy: string@protection-policy-completer # Game session protection policy to apply to this game session only. NoProtection -- The game session can be terminated during a scale-down event. FullProtection -- If the game session is in an ACTIVE status, it cannot be terminated during a scale-down event.
]: any -> oneof<record<GameSession: record<GameSessionId: string, Name: string, FleetId: string, FleetArn: string, CreationTime: string, TerminationTime: string, CurrentPlayerSessionCount: int, MaximumPlayerSessionCount: int, Status: string, StatusReason: string, GameProperties: list<record>, IpAddress: string, DnsName: string, Port: int, PlayerSessionCreationPolicy: string, CreatorId: string, GameSessionData: string, MatchmakerData: string, Location: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateGameSession")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GameSessionId": $game_session_id, "MaximumPlayerSessionCount": $maximum_player_session_count, "Name": $name, "PlayerSessionCreationPolicy": $player_session_creation_policy, "ProtectionPolicy": $protection_policy} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-game-session-queue" [
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
  --x-amz-target: string@x-amz-target-completer-99 # required
  name: string # A descriptive label that is associated with game session queue. Queue names must be unique within each Region. You can use either the queue ID or ARN value.
  --timeout-in-seconds: int # The maximum time, in seconds, that a new game session placement request remains in the queue. When a request exceeds this time, the game session placement changes to a TIMED_OUT status.
  --player-latency-policies: list # A set of policies that act as a sliding cap on player latency. FleetIQ works to deliver low latency for most players in a game session. These policies ensure that no individual player can be placed into a game with unreasonably high latency. Use multiple policies to gradually relax latency requirements a step at a time. Multiple policies are applied based on their maximum allowed latency, starting with the lowest value. When updating policies, provide a complete collection of policies. — item shape: {MaximumIndividualPlayerLatencyMilliseconds?: int, PolicyDurationSeconds?: int}
  --destinations: list # A list of fleets and/or fleet aliases that can be used to fulfill game session placement requests in the queue. Destinations are identified by either a fleet ARN or a fleet alias ARN, and are listed in order of placement preference. When updating this list, provide a complete list of destinations. — item shape: {DestinationArn?: string}
  --filter-configuration: record # A list of fleet locations where a game session queue can place new game sessions. You can use a filter to temporarily turn off placements for specific locations. For queues that have multi-location fleets, you can use a filter configuration allow placement with some, but not all of these locations. — shape: {AllowedLocations?: list<string>}
  --priority-configuration: record # Custom prioritization settings for use by a game session queue when placing new game sessions with available game servers. When defined, this configuration replaces the default FleetIQ prioritization process, which is as follows: If player latency data is included in a game session request, destinations and locations are prioritized first based on lowest average latency (1), then on lowest hosting cost (2), then on destination list order (3), and finally on location (alphabetical) (4). This approach ensures that the queue's top priority is to place game sessions where average player latency is lowest, and--if latency is the same--where the hosting cost is less, etc. If player latency data is not included, destinations and locations are prioritized first on destination list order (1), and then on location (alphabetical) (2). This approach ensures that the queue's top priority is to place game sessions on the first destination fleet listed. If that fleet has multiple locations, the game session is placed on the first location (when listed alphabetically). Changing the priority order will affect how game sessions are placed. — shape: {PriorityOrder?: list<string>, LocationOrder?: list<string>}
  --custom-event-data: string # Information to be added to all events that are related to this game session queue.
  --notification-target: string # An SNS topic ARN that is set up to receive game session placement notifications. See Setting up notifications for game session placement (https://docs.aws.amazon.com/gamelift/latest/developerguide/queue-notification.html).
]: any -> oneof<record<GameSessionQueue: record<Name: string, GameSessionQueueArn: string, TimeoutInSeconds: int, PlayerLatencyPolicies: list<record>, Destinations: list<record>, FilterConfiguration: record<AllowedLocations: list>, PriorityConfiguration: record<PriorityOrder: list, LocationOrder: list>, CustomEventData: string, NotificationTarget: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateGameSessionQueue")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "TimeoutInSeconds": $timeout_in_seconds, "PlayerLatencyPolicies": $player_latency_policies, "Destinations": $destinations, "FilterConfiguration": $filter_configuration, "PriorityConfiguration": $priority_configuration, "CustomEventData": $custom_event_data, "NotificationTarget": $notification_target} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-matchmaking-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-100 # required
  name: string # A unique identifier for the matchmaking configuration to update. You can use either the configuration name or ARN value.
  --description: string # A description for the matchmaking configuration.
  --game-session-queue-arns: list<string> # The Amazon Resource Name (ARN (https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-arn-format.html)) that is assigned to a Amazon GameLift game session queue resource and uniquely identifies it. ARNs are unique across all Regions. Format is arn:aws:gamelift:<region>::gamesessionqueue/<queue name>. Queues can be located in any Region. Queues are used to start new Amazon GameLift-hosted game sessions for matches that are created with this matchmaking configuration. If FlexMatchMode is set to STANDALONE, do not set this parameter.
  --request-timeout-seconds: int # The maximum duration, in seconds, that a matchmaking ticket can remain in process before timing out. Requests that fail due to timing out can be resubmitted as needed.
  --acceptance-timeout-seconds: int # The length of time (in seconds) to wait for players to accept a proposed match, if acceptance is required.
  --acceptance-required: oneof<nothing, bool> # A flag that indicates whether a match that was created with this configuration must be accepted by the matched players. To require acceptance, set to TRUE. With this option enabled, matchmaking tickets use the status REQUIRES_ACCEPTANCE to indicate when a completed potential match is waiting for player acceptance.
  --rule-set-name: string # A unique identifier for the matchmaking rule set to use with this configuration. You can use either the rule set name or ARN value. A matchmaking configuration can only use rule sets that are defined in the same Region.
  --notification-target: string # An SNS topic ARN that is set up to receive matchmaking notifications. See Setting up notifications for matchmaking (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-notification.html) for more information.
  --additional-player-count: int # The number of player slots in a match to keep open for future players. For example, if the configuration's rule set specifies a match for a single 12-person team, and the additional player count is set to 2, only 10 players are selected for the match. This parameter is not used if FlexMatchMode is set to STANDALONE.
  --custom-event-data: string # Information to add to all events related to the matchmaking configuration.
  --game-properties: list # A set of custom properties for a game session, formatted as key:value pairs. These properties are passed to a game server process with a request to start a new game session (see Start a Game Session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession)). This information is added to the new GameSession object that is created for a successful match. This parameter is not used if FlexMatchMode is set to STANDALONE. — item shape: {Key: string, Value: string}
  --game-session-data: string # A set of custom game session properties, formatted as a single string value. This data is passed to a game server process with a request to start a new game session (see Start a Game Session (https://docs.aws.amazon.com/gamelift/latest/developerguide/gamelift-sdk-server-api.html#gamelift-sdk-server-startsession)). This information is added to the game session that is created for a successful match. This parameter is not used if FlexMatchMode is set to STANDALONE.
  --backfill-mode: string@backfill-mode-completer # The method that is used to backfill game sessions created with this matchmaking configuration. Specify MANUAL when your game manages backfill requests manually or does not use the match backfill feature. Specify AUTOMATIC to have GameLift create a match backfill request whenever a game session has one or more open slots. Learn more about manual and automatic backfill in Backfill Existing Games with FlexMatch (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-backfill.html). Automatic backfill is not available when FlexMatchMode is set to STANDALONE.
  --flex-match-mode: string@flex-match-mode-completer # Indicates whether this matchmaking configuration is being used with Amazon GameLift hosting or as a standalone matchmaking solution. STANDALONE - FlexMatch forms matches and returns match information, including players and team assignments, in a MatchmakingSucceeded (https://docs.aws.amazon.com/gamelift/latest/flexmatchguide/match-events.html#match-events-matchmakingsucceeded) event. WITH_QUEUE - FlexMatch forms matches and uses the specified Amazon GameLift queue to start a game session for the match.
]: any -> oneof<record<Configuration: record<Name: string, ConfigurationArn: string, Description: string, GameSessionQueueArns: list<string>, RequestTimeoutSeconds: int, AcceptanceTimeoutSeconds: int, AcceptanceRequired: bool, RuleSetName: string, RuleSetArn: string, NotificationTarget: string, AdditionalPlayerCount: int, CustomEventData: string, CreationTime: string, GameProperties: list<record>, GameSessionData: string, BackfillMode: string, FlexMatchMode: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateMatchmakingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "GameSessionQueueArns": $game_session_queue_arns, "RequestTimeoutSeconds": $request_timeout_seconds, "AcceptanceTimeoutSeconds": $acceptance_timeout_seconds, "AcceptanceRequired": $acceptance_required, "RuleSetName": $rule_set_name, "NotificationTarget": $notification_target, "AdditionalPlayerCount": $additional_player_count, "CustomEventData": $custom_event_data, "GameProperties": $game_properties, "GameSessionData": $game_session_data, "BackfillMode": $backfill_mode, "FlexMatchMode": $flex_match_mode} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-runtime-configuration" [
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
  --x-amz-target: string@x-amz-target-completer-101 # required
  fleet_id: string # A unique identifier for the fleet to update runtime configuration for. You can use either the fleet ID or ARN value.
  runtime_configuration: record # A collection of server process configurations that describe the set of processes to run on each instance in a fleet. Server processes run either an executable in a custom game build or a Realtime Servers script. Amazon GameLift launches the configured processes, manages their life cycle, and replaces them as needed. Each instance checks regularly for an updated runtime configuration. A Amazon GameLift instance is limited to 50 processes running concurrently. To calculate the total number of processes in a runtime configuration, add the values of the ConcurrentExecutions parameter for each server process. Learn more about Running Multiple Processes on a Fleet (https://docs.aws.amazon.com/gamelift/latest/developerguide/fleets-multiprocess.html). — shape: {ServerProcesses?: list, MaxConcurrentGameSessionActivations?: int, GameSessionActivationTimeoutSeconds?: int}
]: any -> oneof<record<RuntimeConfiguration: record<ServerProcesses: list<record>, MaxConcurrentGameSessionActivations: int, GameSessionActivationTimeoutSeconds: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateRuntimeConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"FleetId": $fleet_id, "RuntimeConfiguration": $runtime_configuration} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "update-script" [
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
  --x-amz-target: string@x-amz-target-completer-102 # required
  script_id: string # A unique identifier for the Realtime script to update. You can use either the script ID or ARN value.
  --name: string # A descriptive label that is associated with a script. Script names don't need to be unique.
  --version: string # Version information associated with a build or script. Version strings don't need to be unique.
  --storage-location: record # The location in Amazon S3 where build or script files are stored for access by Amazon GameLift. — shape: {Bucket?: string, Key?: string, RoleArn?: string, ObjectVersion?: string}
  --zip-file: string # A data object containing your Realtime scripts and dependencies as a zip file. The zip file can have one or multiple files. Maximum size of a zip file is 5 MB. When using the Amazon Web Services CLI tool to create a script, this parameter is set to the zip file name. It must be prepended with the string "fileb://" to indicate that the file data is a binary object. For example: --zip-file fileb://myRealtimeScript.zip.
]: any -> oneof<record<Script: record<ScriptId: string, ScriptArn: string, Name: string, Version: string, SizeOnDisk: int, CreationTime: string, StorageLocation: record<Bucket: string, Key: string, RoleArn: string, ObjectVersion: string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.UpdateScript")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScriptId": $script_id, "Name": $name, "Version": $version, "StorageLocation": $storage_location, "ZipFile": $zip_file} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
export def "validate-matchmaking-rule-set" [
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
  --x-amz-target: string@x-amz-target-completer-103 # required
  rule_set_body: string # A collection of matchmaking rules to validate, formatted as a JSON string.
]: any -> oneof<record<Valid: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "GameLift.ValidateMatchmakingRuleSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleSetBody": $rule_set_body} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
