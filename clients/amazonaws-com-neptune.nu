# Auto-generated client for Amazon Neptune v2014-10-31
# Source: https://api.apis.guru/v2/specs/amazonaws.com/neptune/2014-10-31/openapi.json
# Auth: --token flag or $env.AMAZON_NEPTUNE_TOKEN

const BASE_URL = "http://rds.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_NEPTUNE_TOKEN | default "" }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://rds.us-east-1.amazonaws.com" "http://rds.us-east-2.amazonaws.com" "http://rds.us-west-1.amazonaws.com" "http://rds.us-west-2.amazonaws.com" "http://rds.us-gov-west-1.amazonaws.com" "http://rds.us-gov-east-1.amazonaws.com" "http://rds.ca-central-1.amazonaws.com" "http://rds.eu-north-1.amazonaws.com" "http://rds.eu-west-1.amazonaws.com" "http://rds.eu-west-2.amazonaws.com" "http://rds.eu-west-3.amazonaws.com" "http://rds.eu-central-1.amazonaws.com" "http://rds.eu-south-1.amazonaws.com" "http://rds.af-south-1.amazonaws.com" "http://rds.ap-northeast-1.amazonaws.com" "http://rds.ap-northeast-2.amazonaws.com" "http://rds.ap-northeast-3.amazonaws.com" "http://rds.ap-southeast-1.amazonaws.com" "http://rds.ap-southeast-2.amazonaws.com" "http://rds.ap-east-1.amazonaws.com" "http://rds.ap-south-1.amazonaws.com" "http://rds.sa-east-1.amazonaws.com" "http://rds.me-south-1.amazonaws.com" "https://rds.us-east-1.amazonaws.com" "https://rds.us-east-2.amazonaws.com" "https://rds.us-west-1.amazonaws.com" "https://rds.us-west-2.amazonaws.com" "https://rds.us-gov-west-1.amazonaws.com" "https://rds.us-gov-east-1.amazonaws.com" "https://rds.ca-central-1.amazonaws.com" "https://rds.eu-north-1.amazonaws.com" "https://rds.eu-west-1.amazonaws.com" "https://rds.eu-west-2.amazonaws.com" "https://rds.eu-west-3.amazonaws.com" "https://rds.eu-central-1.amazonaws.com" "https://rds.eu-south-1.amazonaws.com" "https://rds.af-south-1.amazonaws.com" "https://rds.ap-northeast-1.amazonaws.com" "https://rds.ap-northeast-2.amazonaws.com" "https://rds.ap-northeast-3.amazonaws.com" "https://rds.ap-southeast-1.amazonaws.com" "https://rds.ap-southeast-2.amazonaws.com" "https://rds.ap-east-1.amazonaws.com" "https://rds.ap-south-1.amazonaws.com" "https://rds.sa-east-1.amazonaws.com" "https://rds.me-south-1.amazonaws.com" "http://rds.amazonaws.com" "https://rds.amazonaws.com" "http://rds.cn-north-1.amazonaws.com.cn" "http://rds.cn-northwest-1.amazonaws.com.cn" "https://rds.cn-north-1.amazonaws.com.cn" "https://rds.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["AddRoleToDBCluster"] }
def version-completer [] { ["2014-10-31"] }
def action-completer-1 [] { ["AddSourceIdentifierToSubscription"] }
def action-completer-2 [] { ["AddTagsToResource"] }
def action-completer-3 [] { ["ApplyPendingMaintenanceAction"] }
def action-completer-4 [] { ["CopyDBClusterParameterGroup"] }
def action-completer-5 [] { ["CopyDBClusterSnapshot"] }
def action-completer-6 [] { ["CopyDBParameterGroup"] }
def action-completer-7 [] { ["CreateDBCluster"] }
def action-completer-8 [] { ["CreateDBClusterEndpoint"] }
def action-completer-9 [] { ["CreateDBClusterParameterGroup"] }
def action-completer-10 [] { ["CreateDBClusterSnapshot"] }
def action-completer-11 [] { ["CreateDBInstance"] }
def action-completer-12 [] { ["CreateDBParameterGroup"] }
def action-completer-13 [] { ["CreateDBSubnetGroup"] }
def action-completer-14 [] { ["CreateEventSubscription"] }
def action-completer-15 [] { ["CreateGlobalCluster"] }
def action-completer-16 [] { ["DeleteDBCluster"] }
def action-completer-17 [] { ["DeleteDBClusterEndpoint"] }
def action-completer-18 [] { ["DeleteDBClusterParameterGroup"] }
def action-completer-19 [] { ["DeleteDBClusterSnapshot"] }
def action-completer-20 [] { ["DeleteDBInstance"] }
def action-completer-21 [] { ["DeleteDBParameterGroup"] }
def action-completer-22 [] { ["DeleteDBSubnetGroup"] }
def action-completer-23 [] { ["DeleteEventSubscription"] }
def action-completer-24 [] { ["DeleteGlobalCluster"] }
def action-completer-25 [] { ["DescribeDBClusterEndpoints"] }
def action-completer-26 [] { ["DescribeDBClusterParameterGroups"] }
def action-completer-27 [] { ["DescribeDBClusterParameters"] }
def action-completer-28 [] { ["DescribeDBClusterSnapshotAttributes"] }
def action-completer-29 [] { ["DescribeDBClusterSnapshots"] }
def action-completer-30 [] { ["DescribeDBClusters"] }
def action-completer-31 [] { ["DescribeDBEngineVersions"] }
def action-completer-32 [] { ["DescribeDBInstances"] }
def action-completer-33 [] { ["DescribeDBParameterGroups"] }
def action-completer-34 [] { ["DescribeDBParameters"] }
def action-completer-35 [] { ["DescribeDBSubnetGroups"] }
def action-completer-36 [] { ["DescribeEngineDefaultClusterParameters"] }
def action-completer-37 [] { ["DescribeEngineDefaultParameters"] }
def action-completer-38 [] { ["DescribeEventCategories"] }
def action-completer-39 [] { ["DescribeEventSubscriptions"] }
def source-type-completer [] { ["db-cluster" "db-cluster-snapshot" "db-instance" "db-parameter-group" "db-security-group" "db-snapshot"] }
def action-completer-40 [] { ["DescribeEvents"] }
def action-completer-41 [] { ["DescribeGlobalClusters"] }
def action-completer-42 [] { ["DescribeOrderableDBInstanceOptions"] }
def action-completer-43 [] { ["DescribePendingMaintenanceActions"] }
def action-completer-44 [] { ["DescribeValidDBInstanceModifications"] }
def action-completer-45 [] { ["FailoverDBCluster"] }
def action-completer-46 [] { ["FailoverGlobalCluster"] }
def action-completer-47 [] { ["ListTagsForResource"] }
def action-completer-48 [] { ["ModifyDBCluster"] }
def action-completer-49 [] { ["ModifyDBClusterEndpoint"] }
def action-completer-50 [] { ["ModifyDBClusterParameterGroup"] }
def action-completer-51 [] { ["ModifyDBClusterSnapshotAttribute"] }
def action-completer-52 [] { ["ModifyDBInstance"] }
def action-completer-53 [] { ["ModifyDBParameterGroup"] }
def action-completer-54 [] { ["ModifyDBSubnetGroup"] }
def action-completer-55 [] { ["ModifyEventSubscription"] }
def action-completer-56 [] { ["ModifyGlobalCluster"] }
def action-completer-57 [] { ["PromoteReadReplicaDBCluster"] }
def action-completer-58 [] { ["RebootDBInstance"] }
def action-completer-59 [] { ["RemoveFromGlobalCluster"] }
def action-completer-60 [] { ["RemoveRoleFromDBCluster"] }
def action-completer-61 [] { ["RemoveSourceIdentifierFromSubscription"] }
def action-completer-62 [] { ["RemoveTagsFromResource"] }
def action-completer-63 [] { ["ResetDBClusterParameterGroup"] }
def action-completer-64 [] { ["ResetDBParameterGroup"] }
def action-completer-65 [] { ["RestoreDBClusterFromSnapshot"] }
def action-completer-66 [] { ["RestoreDBClusterToPointInTime"] }
def action-completer-67 [] { ["StartDBCluster"] }
def action-completer-68 [] { ["StopDBCluster"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["get-add-role-to-db-cluster" "post-add-role-to-db-cluster" "get-add-source-identifier-to-subscription" "post-add-source-identifier-to-subscription" "get-add-tags-to-resource" "post-add-tags-to-resource" "get-apply-pending-maintenance-action" "post-apply-pending-maintenance-action" "get-copy-db-cluster-parameter-group" "post-copy-db-cluster-parameter-group" "get-copy-db-cluster-snapshot" "post-copy-db-cluster-snapshot" "get-copy-db-parameter-group" "post-copy-db-parameter-group" "get-create-db-cluster" "post-create-db-cluster" "get-create-db-cluster-endpoint" "post-create-db-cluster-endpoint" "get-create-db-cluster-parameter-group" "post-create-db-cluster-parameter-group" "get-create-db-cluster-snapshot" "post-create-db-cluster-snapshot" "get-create-db-instance" "post-create-db-instance" "get-create-db-parameter-group" "post-create-db-parameter-group" "get-create-db-subnet-group" "post-create-db-subnet-group" "get-create-event-subscription" "post-create-event-subscription" "get-create-global-cluster" "post-create-global-cluster" "get-delete-db-cluster" "post-delete-db-cluster" "get-delete-db-cluster-endpoint" "post-delete-db-cluster-endpoint" "get-delete-db-cluster-parameter-group" "post-delete-db-cluster-parameter-group" "get-delete-db-cluster-snapshot" "post-delete-db-cluster-snapshot" "get-delete-db-instance" "post-delete-db-instance" "get-delete-db-parameter-group" "post-delete-db-parameter-group" "get-delete-db-subnet-group" "post-delete-db-subnet-group" "get-delete-event-subscription" "post-delete-event-subscription" "get-delete-global-cluster" "post-delete-global-cluster" "get-describe-db-cluster-endpoints" "post-describe-db-cluster-endpoints" "get-describe-db-cluster-parameter-groups" "post-describe-db-cluster-parameter-groups" "get-describe-db-cluster-parameters" "post-describe-db-cluster-parameters" "get-describe-db-cluster-snapshot-attributes" "post-describe-db-cluster-snapshot-attributes" "get-describe-db-cluster-snapshots" "post-describe-db-cluster-snapshots" "get-describe-db-clusters" "post-describe-db-clusters" "get-describe-db-engine-versions" "post-describe-db-engine-versions" "get-describe-db-instances" "post-describe-db-instances" "get-describe-db-parameter-groups" "post-describe-db-parameter-groups" "get-describe-db-parameters" "post-describe-db-parameters" "get-describe-db-subnet-groups" "post-describe-db-subnet-groups" "get-describe-engine-default-cluster-parameters" "post-describe-engine-default-cluster-parameters" "get-describe-engine-default-parameters" "post-describe-engine-default-parameters" "get-describe-event-categories" "post-describe-event-categories" "get-describe-event-subscriptions" "post-describe-event-subscriptions" "get-describe-events" "post-describe-events" "get-describe-global-clusters" "post-describe-global-clusters" "get-describe-orderable-db-instance-options" "post-describe-orderable-db-instance-options" "get-describe-pending-maintenance-actions" "post-describe-pending-maintenance-actions" "get-describe-valid-db-instance-modifications" "post-describe-valid-db-instance-modifications" "get-failover-db-cluster" "post-failover-db-cluster" "get-failover-global-cluster" "post-failover-global-cluster" "get-list-tags-for-resource" "post-list-tags-for-resource" "get-modify-db-cluster" "post-modify-db-cluster" "get-modify-db-cluster-endpoint" "post-modify-db-cluster-endpoint" "get-modify-db-cluster-parameter-group" "post-modify-db-cluster-parameter-group" "get-modify-db-cluster-snapshot-attribute" "post-modify-db-cluster-snapshot-attribute" "get-modify-db-instance" "post-modify-db-instance" "get-modify-db-parameter-group" "post-modify-db-parameter-group" "get-modify-db-subnet-group" "post-modify-db-subnet-group" "get-modify-event-subscription" "post-modify-event-subscription" "get-modify-global-cluster" "post-modify-global-cluster" "get-promote-read-replica-db-cluster" "post-promote-read-replica-db-cluster" "get-reboot-db-instance" "post-reboot-db-instance" "get-remove-from-global-cluster" "post-remove-from-global-cluster" "get-remove-role-from-db-cluster" "post-remove-role-from-db-cluster" "get-remove-source-identifier-from-subscription" "post-remove-source-identifier-from-subscription" "get-remove-tags-from-resource" "post-remove-tags-from-resource" "get-reset-db-cluster-parameter-group" "post-reset-db-cluster-parameter-group" "get-reset-db-parameter-group" "post-reset-db-parameter-group" "get-restore-db-cluster-from-snapshot" "post-restore-db-cluster-from-snapshot" "get-restore-db-cluster-to-point-in-time" "post-restore-db-cluster-to-point-in-time" "get-start-db-cluster" "post-start-db-cluster" "get-stop-db-cluster" "post-stop-db-cluster" "commands"] | sort) } | get name | first)
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

# Associates an Identity and Access Management (IAM) role with an Neptune DB cluster.
#
# GET /
# operationId: GET_AddRoleToDBCluster
export def "get-add-role-to-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The name of the DB cluster to associate the IAM role with. (required)
  --role-arn: string # The Amazon Resource Name (ARN) of the IAM role to associate with the Neptune DB cluster, for example arn:aws:iam::123456789012:role/NeptuneAccessRole. (required)
  --feature-name: string # The name of the feature for the Neptune DB cluster that the IAM role is to be associated with. For the list of supported feature names, see DBEngineVersion (neptune/latest/userguide/api-other-apis.html#DBEngineVersion).
  --action: string@action-completer # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  if ($role_arn == null) { error make --unspanned { msg: "required query parameter 'RoleArn' missing: pass --role-arn" } }
  let action = ($action | default "AddRoleToDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "RoleArn" $role_arn "scalar") (serialize-qp "FeatureName" $feature_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "RoleArn": $role_arn, "FeatureName": $feature_name, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Associates an Identity and Access Management (IAM) role with an Neptune DB cluster.
#
# POST /
# operationId: POST_AddRoleToDBCluster
export def "post-add-role-to-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "AddRoleToDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Adds a source identifier to an existing event notification subscription.
#
# GET /
# operationId: GET_AddSourceIdentifierToSubscription
export def "get-add-source-identifier-to-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the event notification subscription you want to add a source identifier to. (required)
  --source-identifier: string # The identifier of the event source to be added. Constraints: If the source type is a DB instance, then a DBInstanceIdentifier must be supplied. If the source type is a DB security group, a DBSecurityGroupName must be supplied. If the source type is a DB parameter group, a DBParameterGroupName must be supplied. If the source type is a DB snapshot, a DBSnapshotIdentifier must be supplied. (required)
  --action: string@action-completer-1 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_name == null) { error make --unspanned { msg: "required query parameter 'SubscriptionName' missing: pass --subscription-name" } }
  if ($source_identifier == null) { error make --unspanned { msg: "required query parameter 'SourceIdentifier' missing: pass --source-identifier" } }
  let action = ($action | default "AddSourceIdentifierToSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "SourceIdentifier" $source_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SubscriptionName": $subscription_name, "SourceIdentifier": $source_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds a source identifier to an existing event notification subscription.
#
# POST /
# operationId: POST_AddSourceIdentifierToSubscription
export def "post-add-source-identifier-to-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "AddSourceIdentifierToSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Adds metadata tags to an Amazon Neptune resource. These tags can also be used with cost allocation reporting to track cost associated with Amazon Neptune resources, or used in a Condition statement in an IAM policy for Amazon Neptune.
#
# GET /
# operationId: GET_AddTagsToResource
export def "get-add-tags-to-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon Neptune resource that the tags are added to. This value is an Amazon Resource Name (ARN). For information about creating an ARN, see Constructing an Amazon Resource Name (ARN) (https://docs.aws.amazon.com/neptune/latest/UserGuide/tagging.ARN.html#tagging.ARN.Constructing). (required)
  --tags: list # The tags to be assigned to the Amazon Neptune resource. (required)
  --action: string@action-completer-2 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name == null) { error make --unspanned { msg: "required query parameter 'ResourceName' missing: pass --resource-name" } }
  if ($tags == null) { error make --unspanned { msg: "required query parameter 'Tags' missing: pass --tags" } }
  let action = ($action | default "AddTagsToResource")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "ResourceName" $resource_name "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ResourceName": $resource_name, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds metadata tags to an Amazon Neptune resource. These tags can also be used with cost allocation reporting to track cost associated with Amazon Neptune resources, or used in a Condition statement in an IAM policy for Amazon Neptune.
#
# POST /
# operationId: POST_AddTagsToResource
export def "post-add-tags-to-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-2 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "AddTagsToResource")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Applies a pending maintenance action to a resource (for example, to a DB instance).
#
# GET /
# operationId: GET_ApplyPendingMaintenanceAction
export def "get-apply-pending-maintenance-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-identifier: string # The Amazon Resource Name (ARN) of the resource that the pending maintenance action applies to. For information about creating an ARN, see Constructing an Amazon Resource Name (ARN) (https://docs.aws.amazon.com/neptune/latest/UserGuide/tagging.ARN.html#tagging.ARN.Constructing). (required)
  --apply-action: string # The pending maintenance action to apply to this resource. Valid values: system-update, db-upgrade (required)
  --opt-in-type: string # A value that specifies the type of opt-in request, or undoes an opt-in request. An opt-in request of type immediate can't be undone. Valid values: immediate - Apply the maintenance action immediately. next-maintenance - Apply the maintenance action during the next maintenance window for the resource. undo-opt-in - Cancel any existing next-maintenance opt-in requests. (required)
  --action: string@action-completer-3 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<ResourcePendingMaintenanceActions: record<ResourceIdentifier: string, PendingMaintenanceActionDetails: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_identifier == null) { error make --unspanned { msg: "required query parameter 'ResourceIdentifier' missing: pass --resource-identifier" } }
  if ($apply_action == null) { error make --unspanned { msg: "required query parameter 'ApplyAction' missing: pass --apply-action" } }
  if ($opt_in_type == null) { error make --unspanned { msg: "required query parameter 'OptInType' missing: pass --opt-in-type" } }
  let action = ($action | default "ApplyPendingMaintenanceAction")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "ResourceIdentifier" $resource_identifier "scalar") (serialize-qp "ApplyAction" $apply_action "scalar") (serialize-qp "OptInType" $opt_in_type "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ResourceIdentifier": $resource_identifier, "ApplyAction": $apply_action, "OptInType": $opt_in_type, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Applies a pending maintenance action to a resource (for example, to a DB instance).
#
# POST /
# operationId: POST_ApplyPendingMaintenanceAction
export def "post-apply-pending-maintenance-action" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-3 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<ResourcePendingMaintenanceActions: record<ResourceIdentifier: string, PendingMaintenanceActionDetails: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ApplyPendingMaintenanceAction")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Copies the specified DB cluster parameter group.
#
# GET /
# operationId: GET_CopyDBClusterParameterGroup
export def "get-copy-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-db-cluster-parameter-group-identifier: string # The identifier or Amazon Resource Name (ARN) for the source DB cluster parameter group. For information about creating an ARN, see Constructing an Amazon Resource Name (ARN) (https://docs.aws.amazon.com/neptune/latest/UserGuide/tagging.ARN.html#tagging.ARN.Constructing). Constraints: Must specify a valid DB cluster parameter group. If the source DB cluster parameter group is in the same Amazon Region as the copy, specify a valid DB parameter group identifier, for example my-db-cluster-param-group, or a valid ARN. If the source DB parameter group is in a different Amazon Region than the copy, specify a valid DB cluster parameter group ARN, for example arn:aws:rds:us-east-1:123456789012:cluster-pg:custom-cluster-group1. (required)
  --target-db-cluster-parameter-group-identifier: string # The identifier for the copied DB cluster parameter group. Constraints: Cannot be null, empty, or blank Must contain from 1 to 255 letters, numbers, or hyphens First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens Example: my-cluster-param-group1 (required)
  --target-db-cluster-parameter-group-description: string # A description for the copied DB cluster parameter group. (required)
  --tags: list # The tags to be assigned to the copied DB cluster parameter group.
  --action: string@action-completer-4 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterParameterGroup: record<DBClusterParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBClusterParameterGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_db_cluster_parameter_group_identifier == null) { error make --unspanned { msg: "required query parameter 'SourceDBClusterParameterGroupIdentifier' missing: pass --source-db-cluster-parameter-group-identifier" } }
  if ($target_db_cluster_parameter_group_identifier == null) { error make --unspanned { msg: "required query parameter 'TargetDBClusterParameterGroupIdentifier' missing: pass --target-db-cluster-parameter-group-identifier" } }
  if ($target_db_cluster_parameter_group_description == null) { error make --unspanned { msg: "required query parameter 'TargetDBClusterParameterGroupDescription' missing: pass --target-db-cluster-parameter-group-description" } }
  let action = ($action | default "CopyDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SourceDBClusterParameterGroupIdentifier" $source_db_cluster_parameter_group_identifier "scalar") (serialize-qp "TargetDBClusterParameterGroupIdentifier" $target_db_cluster_parameter_group_identifier "scalar") (serialize-qp "TargetDBClusterParameterGroupDescription" $target_db_cluster_parameter_group_description "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SourceDBClusterParameterGroupIdentifier": $source_db_cluster_parameter_group_identifier, "TargetDBClusterParameterGroupIdentifier": $target_db_cluster_parameter_group_identifier, "TargetDBClusterParameterGroupDescription": $target_db_cluster_parameter_group_description, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Copies the specified DB cluster parameter group.
#
# POST /
# operationId: POST_CopyDBClusterParameterGroup
export def "post-copy-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-4 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterParameterGroup: record<DBClusterParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBClusterParameterGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CopyDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Copies a snapshot of a DB cluster. To copy a DB cluster snapshot from a shared manual DB cluster snapshot, SourceDBClusterSnapshotIdentifier must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.
#
# GET /
# operationId: GET_CopyDBClusterSnapshot
export def "get-copy-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-db-cluster-snapshot-identifier: string # The identifier of the DB cluster snapshot to copy. This parameter is not case-sensitive. Constraints: Must specify a valid system snapshot in the "available" state. Specify a valid DB snapshot identifier. Example: my-cluster-snapshot1 (required)
  --target-db-cluster-snapshot-identifier: string # The identifier of the new DB cluster snapshot to create from the source DB cluster snapshot. This parameter is not case-sensitive. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-cluster-snapshot2 (required)
  --kms-key-id: string # The Amazon Amazon KMS key ID for an encrypted DB cluster snapshot. The KMS key ID is the Amazon Resource Name (ARN), KMS key identifier, or the KMS key alias for the KMS encryption key. If you copy an encrypted DB cluster snapshot from your Amazon account, you can specify a value for KmsKeyId to encrypt the copy with a new KMS encryption key. If you don't specify a value for KmsKeyId, then the copy of the DB cluster snapshot is encrypted with the same KMS key as the source DB cluster snapshot. If you copy an encrypted DB cluster snapshot that is shared from another Amazon account, then you must specify a value for KmsKeyId. KMS encryption keys are specific to the Amazon Region that they are created in, and you can't use encryption keys from one Amazon Region in another Amazon Region. You cannot encrypt an unencrypted DB cluster snapshot when you copy it. If you try to copy an unencrypted DB cluster snapshot and specify a value for the KmsKeyId parameter, an error is returned.
  --pre-signed-url: string # Not currently supported.
  --copy-tags: oneof<nothing, bool> # True to copy all tags from the source DB cluster snapshot to the target DB cluster snapshot, and otherwise false. The default is false.
  --tags: list # The tags to assign to the new DB cluster snapshot copy.
  --action: string@action-completer-5 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterSnapshot: record<AvailabilityZones: list<string>, DBClusterSnapshotIdentifier: string, DBClusterIdentifier: string, SnapshotCreateTime: string, Engine: string, AllocatedStorage: int, Status: string, Port: int, VpcId: string, ClusterCreateTime: string, MasterUsername: string, EngineVersion: string, LicenseModel: string, SnapshotType: string, PercentProgress: int, StorageEncrypted: bool, KmsKeyId: string, DBClusterSnapshotArn: string, SourceDBClusterSnapshotArn: string, IAMDatabaseAuthenticationEnabled: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_db_cluster_snapshot_identifier == null) { error make --unspanned { msg: "required query parameter 'SourceDBClusterSnapshotIdentifier' missing: pass --source-db-cluster-snapshot-identifier" } }
  if ($target_db_cluster_snapshot_identifier == null) { error make --unspanned { msg: "required query parameter 'TargetDBClusterSnapshotIdentifier' missing: pass --target-db-cluster-snapshot-identifier" } }
  let action = ($action | default "CopyDBClusterSnapshot")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SourceDBClusterSnapshotIdentifier" $source_db_cluster_snapshot_identifier "scalar") (serialize-qp "TargetDBClusterSnapshotIdentifier" $target_db_cluster_snapshot_identifier "scalar") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "PreSignedUrl" $pre_signed_url "scalar") (serialize-qp "CopyTags" $copy_tags "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SourceDBClusterSnapshotIdentifier": $source_db_cluster_snapshot_identifier, "TargetDBClusterSnapshotIdentifier": $target_db_cluster_snapshot_identifier, "KmsKeyId": $kms_key_id, "PreSignedUrl": $pre_signed_url, "CopyTags": $copy_tags, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Copies a snapshot of a DB cluster. To copy a DB cluster snapshot from a shared manual DB cluster snapshot, SourceDBClusterSnapshotIdentifier must be the Amazon Resource Name (ARN) of the shared DB cluster snapshot.
#
# POST /
# operationId: POST_CopyDBClusterSnapshot
export def "post-copy-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-5 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterSnapshot: record<AvailabilityZones: list<string>, DBClusterSnapshotIdentifier: string, DBClusterIdentifier: string, SnapshotCreateTime: string, Engine: string, AllocatedStorage: int, Status: string, Port: int, VpcId: string, ClusterCreateTime: string, MasterUsername: string, EngineVersion: string, LicenseModel: string, SnapshotType: string, PercentProgress: int, StorageEncrypted: bool, KmsKeyId: string, DBClusterSnapshotArn: string, SourceDBClusterSnapshotArn: string, IAMDatabaseAuthenticationEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CopyDBClusterSnapshot")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Copies the specified DB parameter group.
#
# GET /
# operationId: GET_CopyDBParameterGroup
export def "get-copy-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-db-parameter-group-identifier: string # The identifier or ARN for the source DB parameter group. For information about creating an ARN, see Constructing an Amazon Resource Name (ARN) (https://docs.aws.amazon.com/neptune/latest/UserGuide/tagging.ARN.html#tagging.ARN.Constructing). Constraints: Must specify a valid DB parameter group. Must specify a valid DB parameter group identifier, for example my-db-param-group, or a valid ARN. (required)
  --target-db-parameter-group-identifier: string # The identifier for the copied DB parameter group. Constraints: Cannot be null, empty, or blank. Must contain from 1 to 255 letters, numbers, or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-db-parameter-group (required)
  --target-db-parameter-group-description: string # A description for the copied DB parameter group. (required)
  --tags: list # The tags to be assigned to the copied DB parameter group.
  --action: string@action-completer-6 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBParameterGroup: record<DBParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBParameterGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($source_db_parameter_group_identifier == null) { error make --unspanned { msg: "required query parameter 'SourceDBParameterGroupIdentifier' missing: pass --source-db-parameter-group-identifier" } }
  if ($target_db_parameter_group_identifier == null) { error make --unspanned { msg: "required query parameter 'TargetDBParameterGroupIdentifier' missing: pass --target-db-parameter-group-identifier" } }
  if ($target_db_parameter_group_description == null) { error make --unspanned { msg: "required query parameter 'TargetDBParameterGroupDescription' missing: pass --target-db-parameter-group-description" } }
  let action = ($action | default "CopyDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SourceDBParameterGroupIdentifier" $source_db_parameter_group_identifier "scalar") (serialize-qp "TargetDBParameterGroupIdentifier" $target_db_parameter_group_identifier "scalar") (serialize-qp "TargetDBParameterGroupDescription" $target_db_parameter_group_description "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SourceDBParameterGroupIdentifier": $source_db_parameter_group_identifier, "TargetDBParameterGroupIdentifier": $target_db_parameter_group_identifier, "TargetDBParameterGroupDescription": $target_db_parameter_group_description, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Copies the specified DB parameter group.
#
# POST /
# operationId: POST_CopyDBParameterGroup
export def "post-copy-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-6 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBParameterGroup: record<DBParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBParameterGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CopyDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new Amazon Neptune DB cluster. You can use the ReplicationSourceIdentifier parameter to create the DB cluster as a Read Replica of another DB cluster or Amazon Neptune DB instance. Note that when you create a new cluster using CreateDBCluster directly, deletion protection is disabled by default (when you create a new production cluster in the console, deletion protection is enabled by default). You can only delete a DB cluster if its DeletionProtection field is set to false.
#
# GET /
# operationId: GET_CreateDBCluster
export def "get-create-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability-zones: list # A list of EC2 Availability Zones that instances in the DB cluster can be created in.
  --backup-retention-period: int # The number of days for which automated backups are retained. You must specify a minimum value of 1. Default: 1 Constraints: Must be a value from 1 to 35
  --character-set-name: string # (Not supported by Neptune)
  --copy-tags-to-snapshot: oneof<nothing, bool> # If set to true, tags are copied to any snapshot of the DB cluster that is created.
  --database-name: string # The name for your database of up to 64 alpha-numeric characters. If you do not provide a name, Amazon Neptune will not create a database in the DB cluster you are creating.
  --db-cluster-identifier: string # The DB cluster identifier. This parameter is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-cluster1 (required)
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group to associate with this DB cluster. If this argument is omitted, the default is used. Constraints: If supplied, must match the name of an existing DBClusterParameterGroup.
  --vpc-security-group-ids: list # A list of EC2 VPC security groups to associate with this DB cluster.
  --db-subnet-group-name: string # A DB subnet group to associate with this DB cluster. Constraints: Must match the name of an existing DBSubnetGroup. Must not be default. Example: mySubnetgroup
  --engine: string # The name of the database engine to be used for this DB cluster. Valid Values: neptune (required)
  --engine-version: string # The version number of the database engine to use for the new DB cluster. Example: 1.0.2.1
  --port: int # The port number on which the instances in the DB cluster accept connections. Default: 8182
  --master-username: string # Not supported by Neptune.
  --master-user-password: string # Not supported by Neptune.
  --option-group-name: string # (Not supported by Neptune)
  --preferred-backup-window: string # The daily time range during which automated backups are created if automated backups are enabled using the BackupRetentionPeriod parameter. The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Region. To see the time blocks available, see Adjusting the Preferred Maintenance Window (https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AdjustingTheMaintenanceWindow.html) in the Amazon Neptune User Guide. Constraints: Must be in the format hh24:mi-hh24:mi. Must be in Universal Coordinated Time (UTC). Must not conflict with the preferred maintenance window. Must be at least 30 minutes.
  --preferred-maintenance-window: string # The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC). Format: ddd:hh24:mi-ddd:hh24:mi The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Region, occurring on a random day of the week. To see the time blocks available, see Adjusting the Preferred Maintenance Window (https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/AdjustingTheMaintenanceWindow.html) in the Amazon Neptune User Guide. Valid Days: Mon, Tue, Wed, Thu, Fri, Sat, Sun. Constraints: Minimum 30-minute window.
  --replication-source-identifier: string # The Amazon Resource Name (ARN) of the source DB instance or DB cluster if this DB cluster is created as a Read Replica.
  --tags: list # The tags to assign to the new DB cluster.
  --storage-encrypted: oneof<nothing, bool> # Specifies whether the DB cluster is encrypted.
  --kms-key-id: string # The Amazon KMS key identifier for an encrypted DB cluster. The KMS key identifier is the Amazon Resource Name (ARN) for the KMS encryption key. If you are creating a DB cluster with the same Amazon account that owns the KMS encryption key used to encrypt the new DB cluster, then you can use the KMS key alias instead of the ARN for the KMS encryption key. If an encryption key is not specified in KmsKeyId: If ReplicationSourceIdentifier identifies an encrypted source, then Amazon Neptune will use the encryption key used to encrypt the source. Otherwise, Amazon Neptune will use your default encryption key. If the StorageEncrypted parameter is true and ReplicationSourceIdentifier is not specified, then Amazon Neptune will use your default encryption key. Amazon KMS creates the default encryption key for your Amazon account. Your Amazon account has a different default encryption key for each Amazon Region. If you create a Read Replica of an encrypted DB cluster in another Amazon Region, you must set KmsKeyId to a KMS key ID that is valid in the destination Amazon Region. This key is used to encrypt the Read Replica in that Amazon Region.
  --pre-signed-url: string # This parameter is not currently supported.
  --enable-iam-database-authentication: oneof<nothing, bool> # If set to true, enables Amazon Identity and Access Management (IAM) authentication for the entire DB cluster (this cannot be set at an instance level). Default: false.
  --enable-cloudwatch-logs-exports: list # The list of log types that need to be enabled for exporting to CloudWatch Logs.
  --deletion-protection: oneof<nothing, bool> # A value that indicates whether the DB cluster has deletion protection enabled. The database can't be deleted when deletion protection is enabled. By default, deletion protection is enabled.
  --serverless-v2-scaling-configuration: record
  --global-cluster-identifier: string # The ID of the Neptune global database to which this new DB cluster should be added.
  --action: string@action-completer-7 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  if ($engine == null) { error make --unspanned { msg: "required query parameter 'Engine' missing: pass --engine" } }
  let action = ($action | default "CreateDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "AvailabilityZones" $availability_zones "multi") (serialize-qp "BackupRetentionPeriod" $backup_retention_period "scalar") (serialize-qp "CharacterSetName" $character_set_name "scalar") (serialize-qp "CopyTagsToSnapshot" $copy_tags_to_snapshot "scalar") (serialize-qp "DatabaseName" $database_name "scalar") (serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "Engine" $engine "scalar") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "Port" $port "scalar") (serialize-qp "MasterUsername" $master_username "scalar") (serialize-qp "MasterUserPassword" $master_user_password "scalar") (serialize-qp "OptionGroupName" $option_group_name "scalar") (serialize-qp "PreferredBackupWindow" $preferred_backup_window "scalar") (serialize-qp "PreferredMaintenanceWindow" $preferred_maintenance_window "scalar") (serialize-qp "ReplicationSourceIdentifier" $replication_source_identifier "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "StorageEncrypted" $storage_encrypted "scalar") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "PreSignedUrl" $pre_signed_url "scalar") (serialize-qp "EnableIAMDatabaseAuthentication" $enable_iam_database_authentication "scalar") (serialize-qp "EnableCloudwatchLogsExports" $enable_cloudwatch_logs_exports "multi") (serialize-qp "DeletionProtection" $deletion_protection "scalar") (serialize-qp "ServerlessV2ScalingConfiguration" $serverless_v2_scaling_configuration "multi") (serialize-qp "GlobalClusterIdentifier" $global_cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"AvailabilityZones": $availability_zones, "BackupRetentionPeriod": $backup_retention_period, "CharacterSetName": $character_set_name, "CopyTagsToSnapshot": $copy_tags_to_snapshot, "DatabaseName": $database_name, "DBClusterIdentifier": $db_cluster_identifier, "DBClusterParameterGroupName": $db_cluster_parameter_group_name, "VpcSecurityGroupIds": $vpc_security_group_ids, "DBSubnetGroupName": $db_subnet_group_name, "Engine": $engine, "EngineVersion": $engine_version, "Port": $port, "MasterUsername": $master_username, "MasterUserPassword": $master_user_password, "OptionGroupName": $option_group_name, "PreferredBackupWindow": $preferred_backup_window, "PreferredMaintenanceWindow": $preferred_maintenance_window, "ReplicationSourceIdentifier": $replication_source_identifier, "Tags": $tags, "StorageEncrypted": $storage_encrypted, "KmsKeyId": $kms_key_id, "PreSignedUrl": $pre_signed_url, "EnableIAMDatabaseAuthentication": $enable_iam_database_authentication, "EnableCloudwatchLogsExports": $enable_cloudwatch_logs_exports, "DeletionProtection": $deletion_protection, "ServerlessV2ScalingConfiguration": $serverless_v2_scaling_configuration, "GlobalClusterIdentifier": $global_cluster_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new Amazon Neptune DB cluster. You can use the ReplicationSourceIdentifier parameter to create the DB cluster as a Read Replica of another DB cluster or Amazon Neptune DB instance. Note that when you create a new cluster using CreateDBCluster directly, deletion protection is disabled by default (when you create a new production cluster in the console, deletion protection is enabled by default). You can only delete a DB cluster if its DeletionProtection field is set to false.
#
# POST /
# operationId: POST_CreateDBCluster
export def "post-create-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-7 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new custom endpoint and associates it with an Amazon Neptune DB cluster.
#
# GET /
# operationId: GET_CreateDBClusterEndpoint
export def "get-create-db-cluster-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The DB cluster identifier of the DB cluster associated with the endpoint. This parameter is stored as a lowercase string. (required)
  --db-cluster-endpoint-identifier: string # The identifier to use for the new endpoint. This parameter is stored as a lowercase string. (required)
  --endpoint-type: string # The type of the endpoint. One of: READER, WRITER, ANY. (required)
  --static-members: list # List of DB instance identifiers that are part of the custom endpoint group.
  --excluded-members: list # List of DB instance identifiers that aren't part of the custom endpoint group. All other eligible instances are reachable through the custom endpoint. Only relevant if the list of static members is empty.
  --tags: list # The tags to be assigned to the Amazon Neptune resource.
  --action: string@action-completer-8 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterEndpointIdentifier: string, DBClusterIdentifier: string, DBClusterEndpointResourceIdentifier: string, Endpoint: string, Status: string, EndpointType: string, CustomEndpointType: string, StaticMembers: list<string>, ExcludedMembers: list<string>, DBClusterEndpointArn: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  if ($db_cluster_endpoint_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterEndpointIdentifier' missing: pass --db-cluster-endpoint-identifier" } }
  if ($endpoint_type == null) { error make --unspanned { msg: "required query parameter 'EndpointType' missing: pass --endpoint-type" } }
  let action = ($action | default "CreateDBClusterEndpoint")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "DBClusterEndpointIdentifier" $db_cluster_endpoint_identifier "scalar") (serialize-qp "EndpointType" $endpoint_type "scalar") (serialize-qp "StaticMembers" $static_members "multi") (serialize-qp "ExcludedMembers" $excluded_members "multi") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "DBClusterEndpointIdentifier": $db_cluster_endpoint_identifier, "EndpointType": $endpoint_type, "StaticMembers": $static_members, "ExcludedMembers": $excluded_members, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new custom endpoint and associates it with an Amazon Neptune DB cluster.
#
# POST /
# operationId: POST_CreateDBClusterEndpoint
export def "post-create-db-cluster-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-8 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterEndpointIdentifier: string, DBClusterIdentifier: string, DBClusterEndpointResourceIdentifier: string, Endpoint: string, Status: string, EndpointType: string, CustomEndpointType: string, StaticMembers: list<string>, ExcludedMembers: list<string>, DBClusterEndpointArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateDBClusterEndpoint")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new DB cluster parameter group. Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster. A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after creating it using ModifyDBClusterParameterGroup. Once you've created a DB cluster parameter group, you need to associate it with your DB cluster using ModifyDBCluster. When you associate a new DB cluster parameter group with a running DB cluster, you need to reboot the DB instances in the DB cluster without failover for the new DB cluster parameter group and associated settings to take effect. After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon Neptune to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the character_set_database parameter. You can use the Parameter Groups option of the Amazon Neptune console (https://console.aws.amazon.com/rds/) or the DescribeDBClusterParameters command to verify that your DB cluster parameter group has been created or modified.
#
# GET /
# operationId: GET_CreateDBClusterParameterGroup
export def "get-create-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group. Constraints: Must match the name of an existing DBClusterParameterGroup. This value is stored as a lowercase string. (required)
  --db-parameter-group-family: string # The DB cluster parameter group family name. A DB cluster parameter group can be associated with one and only one DB cluster parameter group family, and can be applied only to a DB cluster running a database engine and engine version compatible with that DB cluster parameter group family. (required)
  --description: string # The description for the DB cluster parameter group. (required)
  --tags: list # The tags to be assigned to the new DB cluster parameter group.
  --action: string@action-completer-9 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterParameterGroup: record<DBClusterParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBClusterParameterGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBClusterParameterGroupName' missing: pass --db-cluster-parameter-group-name" } }
  if ($db_parameter_group_family == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupFamily' missing: pass --db-parameter-group-family" } }
  if ($description == null) { error make --unspanned { msg: "required query parameter 'Description' missing: pass --description" } }
  let action = ($action | default "CreateDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "DBParameterGroupFamily" $db_parameter_group_family "scalar") (serialize-qp "Description" $description "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterParameterGroupName": $db_cluster_parameter_group_name, "DBParameterGroupFamily": $db_parameter_group_family, "Description": $description, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new DB cluster parameter group. Parameters in a DB cluster parameter group apply to all of the instances in a DB cluster. A DB cluster parameter group is initially created with the default parameters for the database engine used by instances in the DB cluster. To provide custom values for any of the parameters, you must modify the group after creating it using ModifyDBClusterParameterGroup. Once you've created a DB cluster parameter group, you need to associate it with your DB cluster using ModifyDBCluster. When you associate a new DB cluster parameter group with a running DB cluster, you need to reboot the DB instances in the DB cluster without failover for the new DB cluster parameter group and associated settings to take effect. After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon Neptune to fully complete the create action before the DB cluster parameter group is used as the default for a new DB cluster. This is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the character_set_database parameter. You can use the Parameter Groups option of the Amazon Neptune console (https://console.aws.amazon.com/rds/) or the DescribeDBClusterParameters command to verify that your DB cluster parameter group has been created or modified.
#
# POST /
# operationId: POST_CreateDBClusterParameterGroup
export def "post-create-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-9 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterParameterGroup: record<DBClusterParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBClusterParameterGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a snapshot of a DB cluster.
#
# GET /
# operationId: GET_CreateDBClusterSnapshot
export def "get-create-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-snapshot-identifier: string # The identifier of the DB cluster snapshot. This parameter is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: my-cluster1-snapshot1 (required)
  --db-cluster-identifier: string # The identifier of the DB cluster to create a snapshot for. This parameter is not case-sensitive. Constraints: Must match the identifier of an existing DBCluster. Example: my-cluster1 (required)
  --tags: list # The tags to be assigned to the DB cluster snapshot.
  --action: string@action-completer-10 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterSnapshot: record<AvailabilityZones: list<string>, DBClusterSnapshotIdentifier: string, DBClusterIdentifier: string, SnapshotCreateTime: string, Engine: string, AllocatedStorage: int, Status: string, Port: int, VpcId: string, ClusterCreateTime: string, MasterUsername: string, EngineVersion: string, LicenseModel: string, SnapshotType: string, PercentProgress: int, StorageEncrypted: bool, KmsKeyId: string, DBClusterSnapshotArn: string, SourceDBClusterSnapshotArn: string, IAMDatabaseAuthenticationEnabled: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_snapshot_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterSnapshotIdentifier' missing: pass --db-cluster-snapshot-identifier" } }
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  let action = ($action | default "CreateDBClusterSnapshot")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterSnapshotIdentifier" $db_cluster_snapshot_identifier "scalar") (serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterSnapshotIdentifier": $db_cluster_snapshot_identifier, "DBClusterIdentifier": $db_cluster_identifier, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a snapshot of a DB cluster.
#
# POST /
# operationId: POST_CreateDBClusterSnapshot
export def "post-create-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-10 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterSnapshot: record<AvailabilityZones: list<string>, DBClusterSnapshotIdentifier: string, DBClusterIdentifier: string, SnapshotCreateTime: string, Engine: string, AllocatedStorage: int, Status: string, Port: int, VpcId: string, ClusterCreateTime: string, MasterUsername: string, EngineVersion: string, LicenseModel: string, SnapshotType: string, PercentProgress: int, StorageEncrypted: bool, KmsKeyId: string, DBClusterSnapshotArn: string, SourceDBClusterSnapshotArn: string, IAMDatabaseAuthenticationEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateDBClusterSnapshot")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new DB instance.
#
# GET /
# operationId: GET_CreateDBInstance
export def "get-create-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-name: string # Not supported.
  --db-instance-identifier: string # The DB instance identifier. This parameter is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. First character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: mydbinstance (required)
  --allocated-storage: int # Not supported by Neptune.
  --db-instance-class: string # The compute and memory capacity of the DB instance, for example, db.m4.large. Not all DB instance classes are available in all Amazon Regions. (required)
  --engine: string # The name of the database engine to be used for this instance. Valid Values: neptune (required)
  --master-username: string # Not supported by Neptune.
  --master-user-password: string # Not supported by Neptune.
  --db-security-groups: list # A list of DB security groups to associate with this DB instance. Default: The default DB security group for the database engine.
  --vpc-security-group-ids: list # A list of EC2 VPC security groups to associate with this DB instance. Not applicable. The associated list of EC2 VPC security groups is managed by the DB cluster. For more information, see CreateDBCluster. Default: The default EC2 VPC security group for the DB subnet group's VPC.
  --availability-zone: string # The EC2 Availability Zone that the DB instance is created in Default: A random, system-chosen Availability Zone in the endpoint's Amazon Region. Example: us-east-1d Constraint: The AvailabilityZone parameter can't be specified if the MultiAZ parameter is set to true. The specified Availability Zone must be in the same Amazon Region as the current endpoint.
  --db-subnet-group-name: string # A DB subnet group to associate with this DB instance. If there is no DB subnet group, then it is a non-VPC DB instance.
  --preferred-maintenance-window: string # The time range each week during which system maintenance can occur, in Universal Coordinated Time (UTC). Format: ddd:hh24:mi-ddd:hh24:mi The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Region, occurring on a random day of the week. Valid Days: Mon, Tue, Wed, Thu, Fri, Sat, Sun. Constraints: Minimum 30-minute window.
  --db-parameter-group-name: string # The name of the DB parameter group to associate with this DB instance. If this argument is omitted, the default DBParameterGroup for the specified engine is used. Constraints: Must be 1 to 255 letters, numbers, or hyphens. First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens
  --backup-retention-period: int # The number of days for which automated backups are retained. Not applicable. The retention period for automated backups is managed by the DB cluster. For more information, see CreateDBCluster. Default: 1 Constraints: Must be a value from 0 to 35 Cannot be set to 0 if the DB instance is a source to Read Replicas
  --preferred-backup-window: string # The daily time range during which automated backups are created. Not applicable. The daily time range for creating automated backups is managed by the DB cluster. For more information, see CreateDBCluster.
  --port: int # The port number on which the database accepts connections. Not applicable. The port is managed by the DB cluster. For more information, see CreateDBCluster. Default: 8182 Type: Integer
  --multi-az: oneof<nothing, bool> # Specifies if the DB instance is a Multi-AZ deployment. You can't set the AvailabilityZone parameter if the MultiAZ parameter is set to true.
  --engine-version: string # The version number of the database engine to use. Currently, setting this parameter has no effect.
  --auto-minor-version-upgrade: oneof<nothing, bool> # Indicates that minor engine upgrades are applied automatically to the DB instance during the maintenance window. Default: true
  --license-model: string # License model information for this DB instance. Valid values: license-included | bring-your-own-license | general-public-license
  --iops: int # The amount of Provisioned IOPS (input/output operations per second) to be initially allocated for the DB instance.
  --option-group-name: string # (Not supported by Neptune)
  --character-set-name: string # (Not supported by Neptune)
  --publicly-accessible: oneof<nothing, bool> # This flag should no longer be used.
  --tags: list # The tags to assign to the new instance.
  --db-cluster-identifier: string # The identifier of the DB cluster that the instance will belong to. For information on creating a DB cluster, see CreateDBCluster. Type: String (required)
  --storage-type: string # Specifies the storage type to be associated with the DB instance. Not applicable. Storage is managed by the DB Cluster.
  --tde-credential-arn: string # The ARN from the key store with which to associate the instance for TDE encryption.
  --tde-credential-password: string # The password for the given ARN from the key store in order to access the device.
  --storage-encrypted: oneof<nothing, bool> # Specifies whether the DB instance is encrypted. Not applicable. The encryption for DB instances is managed by the DB cluster. For more information, see CreateDBCluster. Default: false
  --kms-key-id: string # The Amazon KMS key identifier for an encrypted DB instance. The KMS key identifier is the Amazon Resource Name (ARN) for the KMS encryption key. If you are creating a DB instance with the same Amazon account that owns the KMS encryption key used to encrypt the new DB instance, then you can use the KMS key alias instead of the ARN for the KM encryption key. Not applicable. The KMS key identifier is managed by the DB cluster. For more information, see CreateDBCluster. If the StorageEncrypted parameter is true, and you do not specify a value for the KmsKeyId parameter, then Amazon Neptune will use your default encryption key. Amazon KMS creates the default encryption key for your Amazon account. Your Amazon account has a different default encryption key for each Amazon Region.
  --domain: string # Specify the Active Directory Domain to create the instance in.
  --copy-tags-to-snapshot: oneof<nothing, bool> # True to copy all tags from the DB instance to snapshots of the DB instance, and otherwise false. The default is false.
  --monitoring-interval: int # The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. If MonitoringRoleArn is specified, then you must also set MonitoringInterval to a value other than 0. Valid Values: 0, 1, 5, 10, 15, 30, 60
  --monitoring-role-arn: string # The ARN for the IAM role that permits Neptune to send enhanced monitoring metrics to Amazon CloudWatch Logs. For example, arn:aws:iam:123456789012:role/emaccess. If MonitoringInterval is set to a value other than 0, then you must supply a MonitoringRoleArn value.
  --domain-iam-role-name: string # Specify the name of the IAM role to be used when making API calls to the Directory Service.
  --promotion-tier: int # A value that specifies the order in which an Read Replica is promoted to the primary instance after a failure of the existing primary instance. Default: 1 Valid Values: 0 - 15
  --timezone: string # The time zone of the DB instance.
  --enable-iam-database-authentication: oneof<nothing, bool> # Not supported by Neptune (ignored).
  --enable-performance-insights: oneof<nothing, bool> # (Not supported by Neptune)
  --performance-insights-kms-key-id: string # (Not supported by Neptune)
  --enable-cloudwatch-logs-exports: list # The list of log types that need to be enabled for exporting to CloudWatch Logs.
  --deletion-protection: oneof<nothing, bool> # A value that indicates whether the DB instance has deletion protection enabled. The database can't be deleted when deletion protection is enabled. By default, deletion protection is disabled. See Deleting a DB Instance (https://docs.aws.amazon.com/neptune/latest/userguide/manage-console-instances-delete.html). DB instances in a DB cluster can be deleted even when deletion protection is enabled in their parent DB cluster.
  --action: string@action-completer-11 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBInstance: record<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record<Address: string, Port: int, HostedZoneId: string>, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list<record>, VpcSecurityGroups: list<record>, DBParameterGroups: list<record>, AvailabilityZone: string, DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<DBInstanceClass: string, AllocatedStorage: int, MasterUserPassword: string, Port: int, BackupRetentionPeriod: int, MultiAZ: bool, EngineVersion: string, LicenseModel: string, Iops: int, DBInstanceIdentifier: string, StorageType: string, CACertificateIdentifier: string, DBSubnetGroupName: string, PendingCloudwatchLogsExports: record>, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list<string>, ReadReplicaDBClusterIdentifiers: list<string>, LicenseModel: string, Iops: int, OptionGroupMemberships: list<record>, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list<record>, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list<record>, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list<string>, DeletionProtection: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_instance_identifier == null) { error make --unspanned { msg: "required query parameter 'DBInstanceIdentifier' missing: pass --db-instance-identifier" } }
  if ($db_instance_class == null) { error make --unspanned { msg: "required query parameter 'DBInstanceClass' missing: pass --db-instance-class" } }
  if ($engine == null) { error make --unspanned { msg: "required query parameter 'Engine' missing: pass --engine" } }
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  let action = ($action | default "CreateDBInstance")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBName" $db_name "scalar") (serialize-qp "DBInstanceIdentifier" $db_instance_identifier "scalar") (serialize-qp "AllocatedStorage" $allocated_storage "scalar") (serialize-qp "DBInstanceClass" $db_instance_class "scalar") (serialize-qp "Engine" $engine "scalar") (serialize-qp "MasterUsername" $master_username "scalar") (serialize-qp "MasterUserPassword" $master_user_password "scalar") (serialize-qp "DBSecurityGroups" $db_security_groups "multi") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "AvailabilityZone" $availability_zone "scalar") (serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "PreferredMaintenanceWindow" $preferred_maintenance_window "scalar") (serialize-qp "DBParameterGroupName" $db_parameter_group_name "scalar") (serialize-qp "BackupRetentionPeriod" $backup_retention_period "scalar") (serialize-qp "PreferredBackupWindow" $preferred_backup_window "scalar") (serialize-qp "Port" $port "scalar") (serialize-qp "MultiAZ" $multi_az "scalar") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "AutoMinorVersionUpgrade" $auto_minor_version_upgrade "scalar") (serialize-qp "LicenseModel" $license_model "scalar") (serialize-qp "Iops" $iops "scalar") (serialize-qp "OptionGroupName" $option_group_name "scalar") (serialize-qp "CharacterSetName" $character_set_name "scalar") (serialize-qp "PubliclyAccessible" $publicly_accessible "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "StorageType" $storage_type "scalar") (serialize-qp "TdeCredentialArn" $tde_credential_arn "scalar") (serialize-qp "TdeCredentialPassword" $tde_credential_password "scalar") (serialize-qp "StorageEncrypted" $storage_encrypted "scalar") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "Domain" $domain "scalar") (serialize-qp "CopyTagsToSnapshot" $copy_tags_to_snapshot "scalar") (serialize-qp "MonitoringInterval" $monitoring_interval "scalar") (serialize-qp "MonitoringRoleArn" $monitoring_role_arn "scalar") (serialize-qp "DomainIAMRoleName" $domain_iam_role_name "scalar") (serialize-qp "PromotionTier" $promotion_tier "scalar") (serialize-qp "Timezone" $timezone "scalar") (serialize-qp "EnableIAMDatabaseAuthentication" $enable_iam_database_authentication "scalar") (serialize-qp "EnablePerformanceInsights" $enable_performance_insights "scalar") (serialize-qp "PerformanceInsightsKMSKeyId" $performance_insights_kms_key_id "scalar") (serialize-qp "EnableCloudwatchLogsExports" $enable_cloudwatch_logs_exports "multi") (serialize-qp "DeletionProtection" $deletion_protection "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBName": $db_name, "DBInstanceIdentifier": $db_instance_identifier, "AllocatedStorage": $allocated_storage, "DBInstanceClass": $db_instance_class, "Engine": $engine, "MasterUsername": $master_username, "MasterUserPassword": $master_user_password, "DBSecurityGroups": $db_security_groups, "VpcSecurityGroupIds": $vpc_security_group_ids, "AvailabilityZone": $availability_zone, "DBSubnetGroupName": $db_subnet_group_name, "PreferredMaintenanceWindow": $preferred_maintenance_window, "DBParameterGroupName": $db_parameter_group_name, "BackupRetentionPeriod": $backup_retention_period, "PreferredBackupWindow": $preferred_backup_window, "Port": $port, "MultiAZ": $multi_az, "EngineVersion": $engine_version, "AutoMinorVersionUpgrade": $auto_minor_version_upgrade, "LicenseModel": $license_model, "Iops": $iops, "OptionGroupName": $option_group_name, "CharacterSetName": $character_set_name, "PubliclyAccessible": $publicly_accessible, "Tags": $tags, "DBClusterIdentifier": $db_cluster_identifier, "StorageType": $storage_type, "TdeCredentialArn": $tde_credential_arn, "TdeCredentialPassword": $tde_credential_password, "StorageEncrypted": $storage_encrypted, "KmsKeyId": $kms_key_id, "Domain": $domain, "CopyTagsToSnapshot": $copy_tags_to_snapshot, "MonitoringInterval": $monitoring_interval, "MonitoringRoleArn": $monitoring_role_arn, "DomainIAMRoleName": $domain_iam_role_name, "PromotionTier": $promotion_tier, "Timezone": $timezone, "EnableIAMDatabaseAuthentication": $enable_iam_database_authentication, "EnablePerformanceInsights": $enable_performance_insights, "PerformanceInsightsKMSKeyId": $performance_insights_kms_key_id, "EnableCloudwatchLogsExports": $enable_cloudwatch_logs_exports, "DeletionProtection": $deletion_protection, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new DB instance.
#
# POST /
# operationId: POST_CreateDBInstance
export def "post-create-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-11 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBInstance: record<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record<Address: string, Port: int, HostedZoneId: string>, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list<record>, VpcSecurityGroups: list<record>, DBParameterGroups: list<record>, AvailabilityZone: string, DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<DBInstanceClass: string, AllocatedStorage: int, MasterUserPassword: string, Port: int, BackupRetentionPeriod: int, MultiAZ: bool, EngineVersion: string, LicenseModel: string, Iops: int, DBInstanceIdentifier: string, StorageType: string, CACertificateIdentifier: string, DBSubnetGroupName: string, PendingCloudwatchLogsExports: record>, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list<string>, ReadReplicaDBClusterIdentifiers: list<string>, LicenseModel: string, Iops: int, OptionGroupMemberships: list<record>, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list<record>, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list<record>, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list<string>, DeletionProtection: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateDBInstance")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new DB parameter group. A DB parameter group is initially created with the default parameters for the database engine used by the DB instance. To provide custom values for any of the parameters, you must modify the group after creating it using ModifyDBParameterGroup. Once you've created a DB parameter group, you need to associate it with your DB instance using ModifyDBInstance. When you associate a new DB parameter group with a running DB instance, you need to reboot the DB instance without failover for the new DB parameter group and associated settings to take effect. After you create a DB parameter group, you should wait at least 5 minutes before creating your first DB instance that uses that DB parameter group as the default parameter group. This allows Amazon Neptune to fully complete the create action before the parameter group is used as the default for a new DB instance. This is especially important for parameters that are critical when creating the default database for a DB instance, such as the character set for the default database defined by the character_set_database parameter. You can use the Parameter Groups option of the Amazon Neptune console or the DescribeDBParameters command to verify that your DB parameter group has been created or modified.
#
# GET /
# operationId: GET_CreateDBParameterGroup
export def "get-create-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-name: string # The name of the DB parameter group. Constraints: Must be 1 to 255 letters, numbers, or hyphens. First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens This value is stored as a lowercase string. (required)
  --db-parameter-group-family: string # The DB parameter group family name. A DB parameter group can be associated with one and only one DB parameter group family, and can be applied only to a DB instance running a database engine and engine version compatible with that DB parameter group family. (required)
  --description: string # The description for the DB parameter group. (required)
  --tags: list # The tags to be assigned to the new DB parameter group.
  --action: string@action-completer-12 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBParameterGroup: record<DBParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBParameterGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupName' missing: pass --db-parameter-group-name" } }
  if ($db_parameter_group_family == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupFamily' missing: pass --db-parameter-group-family" } }
  if ($description == null) { error make --unspanned { msg: "required query parameter 'Description' missing: pass --description" } }
  let action = ($action | default "CreateDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBParameterGroupName" $db_parameter_group_name "scalar") (serialize-qp "DBParameterGroupFamily" $db_parameter_group_family "scalar") (serialize-qp "Description" $description "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBParameterGroupName": $db_parameter_group_name, "DBParameterGroupFamily": $db_parameter_group_family, "Description": $description, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new DB parameter group. A DB parameter group is initially created with the default parameters for the database engine used by the DB instance. To provide custom values for any of the parameters, you must modify the group after creating it using ModifyDBParameterGroup. Once you've created a DB parameter group, you need to associate it with your DB instance using ModifyDBInstance. When you associate a new DB parameter group with a running DB instance, you need to reboot the DB instance without failover for the new DB parameter group and associated settings to take effect. After you create a DB parameter group, you should wait at least 5 minutes before creating your first DB instance that uses that DB parameter group as the default parameter group. This allows Amazon Neptune to fully complete the create action before the parameter group is used as the default for a new DB instance. This is especially important for parameters that are critical when creating the default database for a DB instance, such as the character set for the default database defined by the character_set_database parameter. You can use the Parameter Groups option of the Amazon Neptune console or the DescribeDBParameters command to verify that your DB parameter group has been created or modified.
#
# POST /
# operationId: POST_CreateDBParameterGroup
export def "post-create-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-12 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBParameterGroup: record<DBParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBParameterGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two AZs in the Amazon Region.
#
# GET /
# operationId: GET_CreateDBSubnetGroup
export def "get-create-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-subnet-group-name: string # The name for the DB subnet group. This value is stored as a lowercase string. Constraints: Must contain no more than 255 letters, numbers, periods, underscores, spaces, or hyphens. Must not be default. Example: mySubnetgroup (required)
  --db-subnet-group-description: string # The description for the DB subnet group. (required)
  --subnet-ids: list # The EC2 Subnet IDs for the DB subnet group. (required)
  --tags: list # The tags to be assigned to the new DB subnet group.
  --action: string@action-completer-13 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, DBSubnetGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_subnet_group_name == null) { error make --unspanned { msg: "required query parameter 'DBSubnetGroupName' missing: pass --db-subnet-group-name" } }
  if ($db_subnet_group_description == null) { error make --unspanned { msg: "required query parameter 'DBSubnetGroupDescription' missing: pass --db-subnet-group-description" } }
  if ($subnet_ids == null) { error make --unspanned { msg: "required query parameter 'SubnetIds' missing: pass --subnet-ids" } }
  let action = ($action | default "CreateDBSubnetGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "DBSubnetGroupDescription" $db_subnet_group_description "scalar") (serialize-qp "SubnetIds" $subnet_ids "multi") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBSubnetGroupName": $db_subnet_group_name, "DBSubnetGroupDescription": $db_subnet_group_description, "SubnetIds": $subnet_ids, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new DB subnet group. DB subnet groups must contain at least one subnet in at least two AZs in the Amazon Region.
#
# POST /
# operationId: POST_CreateDBSubnetGroup
export def "post-create-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-13 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, DBSubnetGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateDBSubnetGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates an event notification subscription. This action requires a topic ARN (Amazon Resource Name) created by either the Neptune console, the SNS console, or the SNS API. To obtain an ARN with SNS, you must create a topic in Amazon SNS and subscribe to the topic. The ARN is displayed in the SNS console. You can specify the type of source (SourceType) you want to be notified of, provide a list of Neptune sources (SourceIds) that triggers the events, and provide a list of event categories (EventCategories) for events you want to be notified of. For example, you can specify SourceType = db-instance, SourceIds = mydbinstance1, mydbinstance2 and EventCategories = Availability, Backup. If you specify both the SourceType and SourceIds, such as SourceType = db-instance and SourceIdentifier = myDBInstance1, you are notified of all the db-instance events for the specified source. If you specify a SourceType but do not specify a SourceIdentifier, you receive notice of the events for that source type for all your Neptune sources. If you do not specify either the SourceType nor the SourceIdentifier, you are notified of events generated from all Neptune sources belonging to your customer account.
#
# GET /
# operationId: GET_CreateEventSubscription
export def "get-create-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the subscription. Constraints: The name must be less than 255 characters. (required)
  --sns-topic-arn: string # The Amazon Resource Name (ARN) of the SNS topic created for event notification. The ARN is created by Amazon SNS when you create a topic and subscribe to it. (required)
  --source-type: string # The type of source that is generating the events. For example, if you want to be notified of events generated by a DB instance, you would set this parameter to db-instance. if this value is not specified, all events are returned. Valid values: db-instance | db-cluster | db-parameter-group | db-security-group | db-snapshot | db-cluster-snapshot
  --event-categories: list # A list of event categories for a SourceType that you want to subscribe to. You can see a list of the categories for a given SourceType by using the DescribeEventCategories action.
  --source-ids: list # The list of identifiers of the event sources for which events are returned. If not specified, then all sources are included in the response. An identifier must begin with a letter and must contain only ASCII letters, digits, and hyphens; it can't end with a hyphen or contain two consecutive hyphens. Constraints: If SourceIds are supplied, SourceType must also be provided. If the source type is a DB instance, then a DBInstanceIdentifier must be supplied. If the source type is a DB security group, a DBSecurityGroupName must be supplied. If the source type is a DB parameter group, a DBParameterGroupName must be supplied. If the source type is a DB snapshot, a DBSnapshotIdentifier must be supplied.
  --enabled: oneof<nothing, bool> # A Boolean value; set to true to activate the subscription, set to false to create the subscription but not active it.
  --tags: list # The tags to be applied to the new event subscription.
  --action: string@action-completer-14 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_name == null) { error make --unspanned { msg: "required query parameter 'SubscriptionName' missing: pass --subscription-name" } }
  if ($sns_topic_arn == null) { error make --unspanned { msg: "required query parameter 'SnsTopicArn' missing: pass --sns-topic-arn" } }
  let action = ($action | default "CreateEventSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "SnsTopicArn" $sns_topic_arn "scalar") (serialize-qp "SourceType" $source_type "scalar") (serialize-qp "EventCategories" $event_categories "multi") (serialize-qp "SourceIds" $source_ids "multi") (serialize-qp "Enabled" $enabled "scalar") (serialize-qp "Tags" $tags "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SubscriptionName": $subscription_name, "SnsTopicArn": $sns_topic_arn, "SourceType": $source_type, "EventCategories": $event_categories, "SourceIds": $source_ids, "Enabled": $enabled, "Tags": $tags, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates an event notification subscription. This action requires a topic ARN (Amazon Resource Name) created by either the Neptune console, the SNS console, or the SNS API. To obtain an ARN with SNS, you must create a topic in Amazon SNS and subscribe to the topic. The ARN is displayed in the SNS console. You can specify the type of source (SourceType) you want to be notified of, provide a list of Neptune sources (SourceIds) that triggers the events, and provide a list of event categories (EventCategories) for events you want to be notified of. For example, you can specify SourceType = db-instance, SourceIds = mydbinstance1, mydbinstance2 and EventCategories = Availability, Backup. If you specify both the SourceType and SourceIds, such as SourceType = db-instance and SourceIdentifier = myDBInstance1, you are notified of all the db-instance events for the specified source. If you specify a SourceType but do not specify a SourceIdentifier, you receive notice of the events for that source type for all your Neptune sources. If you do not specify either the SourceType nor the SourceIdentifier, you are notified of events generated from all Neptune sources belonging to your customer account.
#
# POST /
# operationId: POST_CreateEventSubscription
export def "post-create-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-14 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateEventSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a Neptune global database spread across multiple Amazon Regions. The global database contains a single primary cluster with read-write capability, and read-only secondary clusters that receive data from the primary cluster through high-speed replication performed by the Neptune storage subsystem. You can create a global database that is initially empty, and then add a primary cluster and secondary clusters to it, or you can specify an existing Neptune cluster during the create operation to become the primary cluster of the global database.
#
# GET /
# operationId: GET_CreateGlobalCluster
export def "get-create-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The cluster identifier of the new global database cluster. (required)
  --source-db-cluster-identifier: string # (Optional) The Amazon Resource Name (ARN) of an existing Neptune DB cluster to use as the primary cluster of the new global database.
  --engine: string # The name of the database engine to be used in the global database. Valid values: neptune
  --engine-version: string # The Neptune engine version to be used by the global database. Valid values: 1.2.0.0 or above.
  --deletion-protection: oneof<nothing, bool> # The deletion protection setting for the new global database. The global database can't be deleted when deletion protection is enabled.
  --storage-encrypted: oneof<nothing, bool> # The storage encryption setting for the new global database cluster.
  --action: string@action-completer-15 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($global_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'GlobalClusterIdentifier' missing: pass --global-cluster-identifier" } }
  let action = ($action | default "CreateGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "GlobalClusterIdentifier" $global_cluster_identifier "scalar") (serialize-qp "SourceDBClusterIdentifier" $source_db_cluster_identifier "scalar") (serialize-qp "Engine" $engine "scalar") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "DeletionProtection" $deletion_protection "scalar") (serialize-qp "StorageEncrypted" $storage_encrypted "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GlobalClusterIdentifier": $global_cluster_identifier, "SourceDBClusterIdentifier": $source_db_cluster_identifier, "Engine": $engine, "EngineVersion": $engine_version, "DeletionProtection": $deletion_protection, "StorageEncrypted": $storage_encrypted, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a Neptune global database spread across multiple Amazon Regions. The global database contains a single primary cluster with read-write capability, and read-only secondary clusters that receive data from the primary cluster through high-speed replication performed by the Neptune storage subsystem. You can create a global database that is initially empty, and then add a primary cluster and secondary clusters to it, or you can specify an existing Neptune cluster during the create operation to become the primary cluster of the global database.
#
# POST /
# operationId: POST_CreateGlobalCluster
export def "post-create-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-15 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "CreateGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# The DeleteDBCluster action deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted. Note that the DB Cluster cannot be deleted if deletion protection is enabled. To delete it, you must first set its DeletionProtection field to False.
#
# GET /
# operationId: GET_DeleteDBCluster
export def "get-delete-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The DB cluster identifier for the DB cluster to be deleted. This parameter isn't case-sensitive. Constraints: Must match an existing DBClusterIdentifier. (required)
  --skip-final-snapshot: oneof<nothing, bool> # Determines whether a final DB cluster snapshot is created before the DB cluster is deleted. If true is specified, no DB cluster snapshot is created. If false is specified, a DB cluster snapshot is created before the DB cluster is deleted. You must specify a FinalDBSnapshotIdentifier parameter if SkipFinalSnapshot is false. Default: false
  --final-db-snapshot-identifier: string # The DB cluster snapshot identifier of the new DB cluster snapshot created when SkipFinalSnapshot is set to false. Specifying this parameter and also setting the SkipFinalShapshot parameter to true results in an error. Constraints: Must be 1 to 255 letters, numbers, or hyphens. First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens
  --action: string@action-completer-16 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  let action = ($action | default "DeleteDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "SkipFinalSnapshot" $skip_final_snapshot "scalar") (serialize-qp "FinalDBSnapshotIdentifier" $final_db_snapshot_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "SkipFinalSnapshot": $skip_final_snapshot, "FinalDBSnapshotIdentifier": $final_db_snapshot_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The DeleteDBCluster action deletes a previously provisioned DB cluster. When you delete a DB cluster, all automated backups for that DB cluster are deleted and can't be recovered. Manual DB cluster snapshots of the specified DB cluster are not deleted. Note that the DB Cluster cannot be deleted if deletion protection is enabled. To delete it, you must first set its DeletionProtection field to False.
#
# POST /
# operationId: POST_DeleteDBCluster
export def "post-delete-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-16 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a custom endpoint and removes it from an Amazon Neptune DB cluster.
#
# GET /
# operationId: GET_DeleteDBClusterEndpoint
export def "get-delete-db-cluster-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-endpoint-identifier: string # The identifier associated with the custom endpoint. This parameter is stored as a lowercase string. (required)
  --action: string@action-completer-17 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterEndpointIdentifier: string, DBClusterIdentifier: string, DBClusterEndpointResourceIdentifier: string, Endpoint: string, Status: string, EndpointType: string, CustomEndpointType: string, StaticMembers: list<string>, ExcludedMembers: list<string>, DBClusterEndpointArn: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_endpoint_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterEndpointIdentifier' missing: pass --db-cluster-endpoint-identifier" } }
  let action = ($action | default "DeleteDBClusterEndpoint")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterEndpointIdentifier" $db_cluster_endpoint_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterEndpointIdentifier": $db_cluster_endpoint_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a custom endpoint and removes it from an Amazon Neptune DB cluster.
#
# POST /
# operationId: POST_DeleteDBClusterEndpoint
export def "post-delete-db-cluster-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-17 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterEndpointIdentifier: string, DBClusterIdentifier: string, DBClusterEndpointResourceIdentifier: string, Endpoint: string, Status: string, EndpointType: string, CustomEndpointType: string, StaticMembers: list<string>, ExcludedMembers: list<string>, DBClusterEndpointArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteDBClusterEndpoint")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
#
# GET /
# operationId: GET_DeleteDBClusterParameterGroup
export def "get-delete-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group. Constraints: Must be the name of an existing DB cluster parameter group. You can't delete a default DB cluster parameter group. Cannot be associated with any DB clusters. (required)
  --action: string@action-completer-18 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBClusterParameterGroupName' missing: pass --db-cluster-parameter-group-name" } }
  let action = ($action | default "DeleteDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterParameterGroupName": $db_cluster_parameter_group_name, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a specified DB cluster parameter group. The DB cluster parameter group to be deleted can't be associated with any DB clusters.
#
# POST /
# operationId: POST_DeleteDBClusterParameterGroup
export def "post-delete-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-18 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated. The DB cluster snapshot must be in the available state to be deleted.
#
# GET /
# operationId: GET_DeleteDBClusterSnapshot
export def "get-delete-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-snapshot-identifier: string # The identifier of the DB cluster snapshot to delete. Constraints: Must be the name of an existing DB cluster snapshot in the available state. (required)
  --action: string@action-completer-19 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterSnapshot: record<AvailabilityZones: list<string>, DBClusterSnapshotIdentifier: string, DBClusterIdentifier: string, SnapshotCreateTime: string, Engine: string, AllocatedStorage: int, Status: string, Port: int, VpcId: string, ClusterCreateTime: string, MasterUsername: string, EngineVersion: string, LicenseModel: string, SnapshotType: string, PercentProgress: int, StorageEncrypted: bool, KmsKeyId: string, DBClusterSnapshotArn: string, SourceDBClusterSnapshotArn: string, IAMDatabaseAuthenticationEnabled: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_snapshot_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterSnapshotIdentifier' missing: pass --db-cluster-snapshot-identifier" } }
  let action = ($action | default "DeleteDBClusterSnapshot")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterSnapshotIdentifier" $db_cluster_snapshot_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterSnapshotIdentifier": $db_cluster_snapshot_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a DB cluster snapshot. If the snapshot is being copied, the copy operation is terminated. The DB cluster snapshot must be in the available state to be deleted.
#
# POST /
# operationId: POST_DeleteDBClusterSnapshot
export def "post-delete-db-cluster-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-19 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterSnapshot: record<AvailabilityZones: list<string>, DBClusterSnapshotIdentifier: string, DBClusterIdentifier: string, SnapshotCreateTime: string, Engine: string, AllocatedStorage: int, Status: string, Port: int, VpcId: string, ClusterCreateTime: string, MasterUsername: string, EngineVersion: string, LicenseModel: string, SnapshotType: string, PercentProgress: int, StorageEncrypted: bool, KmsKeyId: string, DBClusterSnapshotArn: string, SourceDBClusterSnapshotArn: string, IAMDatabaseAuthenticationEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteDBClusterSnapshot")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# The DeleteDBInstance action deletes a previously provisioned DB instance. When you delete a DB instance, all automated backups for that instance are deleted and can't be recovered. Manual DB snapshots of the DB instance to be deleted by DeleteDBInstance are not deleted. If you request a final DB snapshot the status of the Amazon Neptune DB instance is deleting until the DB snapshot is created. The API action DescribeDBInstance is used to monitor the status of this operation. The action can't be canceled or reverted once submitted. Note that when a DB instance is in a failure state and has a status of failed, incompatible-restore, or incompatible-network, you can only delete it when the SkipFinalSnapshot parameter is set to true. You can't delete a DB instance if it is the only instance in the DB cluster, or if it has deletion protection enabled.
#
# GET /
# operationId: GET_DeleteDBInstance
export def "get-delete-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The DB instance identifier for the DB instance to be deleted. This parameter isn't case-sensitive. Constraints: Must match the name of an existing DB instance. (required)
  --skip-final-snapshot: oneof<nothing, bool> # Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted. Note that when a DB instance is in a failure state and has a status of 'failed', 'incompatible-restore', or 'incompatible-network', it can only be deleted when the SkipFinalSnapshot parameter is set to "true". Specify true when deleting a Read Replica. The FinalDBSnapshotIdentifier parameter must be specified if SkipFinalSnapshot is false. Default: false
  --final-db-snapshot-identifier: string # The DBSnapshotIdentifier of the new DBSnapshot created when SkipFinalSnapshot is set to false. Specifying this parameter and also setting the SkipFinalShapshot parameter to true results in an error. Constraints: Must be 1 to 255 letters or numbers. First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens Cannot be specified when deleting a Read Replica.
  --action: string@action-completer-20 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBInstance: record<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record<Address: string, Port: int, HostedZoneId: string>, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list<record>, VpcSecurityGroups: list<record>, DBParameterGroups: list<record>, AvailabilityZone: string, DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<DBInstanceClass: string, AllocatedStorage: int, MasterUserPassword: string, Port: int, BackupRetentionPeriod: int, MultiAZ: bool, EngineVersion: string, LicenseModel: string, Iops: int, DBInstanceIdentifier: string, StorageType: string, CACertificateIdentifier: string, DBSubnetGroupName: string, PendingCloudwatchLogsExports: record>, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list<string>, ReadReplicaDBClusterIdentifiers: list<string>, LicenseModel: string, Iops: int, OptionGroupMemberships: list<record>, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list<record>, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list<record>, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list<string>, DeletionProtection: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_instance_identifier == null) { error make --unspanned { msg: "required query parameter 'DBInstanceIdentifier' missing: pass --db-instance-identifier" } }
  let action = ($action | default "DeleteDBInstance")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBInstanceIdentifier" $db_instance_identifier "scalar") (serialize-qp "SkipFinalSnapshot" $skip_final_snapshot "scalar") (serialize-qp "FinalDBSnapshotIdentifier" $final_db_snapshot_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBInstanceIdentifier": $db_instance_identifier, "SkipFinalSnapshot": $skip_final_snapshot, "FinalDBSnapshotIdentifier": $final_db_snapshot_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# The DeleteDBInstance action deletes a previously provisioned DB instance. When you delete a DB instance, all automated backups for that instance are deleted and can't be recovered. Manual DB snapshots of the DB instance to be deleted by DeleteDBInstance are not deleted. If you request a final DB snapshot the status of the Amazon Neptune DB instance is deleting until the DB snapshot is created. The API action DescribeDBInstance is used to monitor the status of this operation. The action can't be canceled or reverted once submitted. Note that when a DB instance is in a failure state and has a status of failed, incompatible-restore, or incompatible-network, you can only delete it when the SkipFinalSnapshot parameter is set to true. You can't delete a DB instance if it is the only instance in the DB cluster, or if it has deletion protection enabled.
#
# POST /
# operationId: POST_DeleteDBInstance
export def "post-delete-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-20 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBInstance: record<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record<Address: string, Port: int, HostedZoneId: string>, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list<record>, VpcSecurityGroups: list<record>, DBParameterGroups: list<record>, AvailabilityZone: string, DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<DBInstanceClass: string, AllocatedStorage: int, MasterUserPassword: string, Port: int, BackupRetentionPeriod: int, MultiAZ: bool, EngineVersion: string, LicenseModel: string, Iops: int, DBInstanceIdentifier: string, StorageType: string, CACertificateIdentifier: string, DBSubnetGroupName: string, PendingCloudwatchLogsExports: record>, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list<string>, ReadReplicaDBClusterIdentifiers: list<string>, LicenseModel: string, Iops: int, OptionGroupMemberships: list<record>, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list<record>, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list<record>, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list<string>, DeletionProtection: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteDBInstance")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a specified DBParameterGroup. The DBParameterGroup to be deleted can't be associated with any DB instances.
#
# GET /
# operationId: GET_DeleteDBParameterGroup
export def "get-delete-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-name: string # The name of the DB parameter group. Constraints: Must be the name of an existing DB parameter group You can't delete a default DB parameter group Cannot be associated with any DB instances (required)
  --action: string@action-completer-21 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupName' missing: pass --db-parameter-group-name" } }
  let action = ($action | default "DeleteDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBParameterGroupName" $db_parameter_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBParameterGroupName": $db_parameter_group_name, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a specified DBParameterGroup. The DBParameterGroup to be deleted can't be associated with any DB instances.
#
# POST /
# operationId: POST_DeleteDBParameterGroup
export def "post-delete-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-21 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a DB subnet group. The specified database subnet group must not be associated with any DB instances.
#
# GET /
# operationId: GET_DeleteDBSubnetGroup
export def "get-delete-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-subnet-group-name: string # The name of the database subnet group to delete. You can't delete the default subnet group. Constraints: Constraints: Must match the name of an existing DBSubnetGroup. Must not be default. Example: mySubnetgroup (required)
  --action: string@action-completer-22 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_subnet_group_name == null) { error make --unspanned { msg: "required query parameter 'DBSubnetGroupName' missing: pass --db-subnet-group-name" } }
  let action = ($action | default "DeleteDBSubnetGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBSubnetGroupName": $db_subnet_group_name, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a DB subnet group. The specified database subnet group must not be associated with any DB instances.
#
# POST /
# operationId: POST_DeleteDBSubnetGroup
export def "post-delete-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-22 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteDBSubnetGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes an event notification subscription.
#
# GET /
# operationId: GET_DeleteEventSubscription
export def "get-delete-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the event notification subscription you want to delete. (required)
  --action: string@action-completer-23 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_name == null) { error make --unspanned { msg: "required query parameter 'SubscriptionName' missing: pass --subscription-name" } }
  let action = ($action | default "DeleteEventSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SubscriptionName": $subscription_name, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes an event notification subscription.
#
# POST /
# operationId: POST_DeleteEventSubscription
export def "post-delete-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-23 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteEventSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes a global database. The primary and all secondary clusters must already be detached or deleted first.
#
# GET /
# operationId: GET_DeleteGlobalCluster
export def "get-delete-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The cluster identifier of the global database cluster being deleted. (required)
  --action: string@action-completer-24 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($global_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'GlobalClusterIdentifier' missing: pass --global-cluster-identifier" } }
  let action = ($action | default "DeleteGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "GlobalClusterIdentifier" $global_cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GlobalClusterIdentifier": $global_cluster_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a global database. The primary and all secondary clusters must already be detached or deleted first.
#
# POST /
# operationId: POST_DeleteGlobalCluster
export def "post-delete-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-24 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DeleteGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about endpoints for an Amazon Neptune DB cluster. This operation can also return information for Amazon RDS clusters and Amazon DocDB clusters.
#
# GET /
# operationId: GET_DescribeDBClusterEndpoints
export def "get-describe-db-cluster-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The DB cluster identifier of the DB cluster associated with the endpoint. This parameter is stored as a lowercase string.
  --db-cluster-endpoint-identifier: string # The identifier of the endpoint to describe. This parameter is stored as a lowercase string.
  --filters: list # A set of name-value pairs that define which endpoints to include in the output. The filters are specified as name-value pairs, in the format Name=endpoint_type,Values=endpoint_type1,endpoint_type2,.... Name can be one of: db-cluster-endpoint-type, db-cluster-endpoint-custom-type, db-cluster-endpoint-id, db-cluster-endpoint-status. Values for the db-cluster-endpoint-type filter can be one or more of: reader, writer, custom. Values for the db-cluster-endpoint-custom-type filter can be one or more of: reader, any. Values for the db-cluster-endpoint-status filter can be one or more of: available, creating, deleting, inactive, modifying.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so you can retrieve the remaining results. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBClusterEndpoints request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-25 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, DBClusterEndpoints: table<DBClusterEndpointIdentifier: string, DBClusterIdentifier: string, DBClusterEndpointResourceIdentifier: string, Endpoint: string, Status: string, EndpointType: string, CustomEndpointType: string, StaticMembers: list, ExcludedMembers: list, DBClusterEndpointArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusterEndpoints")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "DBClusterEndpointIdentifier" $db_cluster_endpoint_identifier "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "DBClusterEndpointIdentifier": $db_cluster_endpoint_identifier, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about endpoints for an Amazon Neptune DB cluster. This operation can also return information for Amazon RDS clusters and Amazon DocDB clusters.
#
# POST /
# operationId: POST_DescribeDBClusterEndpoints
export def "post-describe-db-cluster-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-25 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, DBClusterEndpoints: table<DBClusterEndpointIdentifier: string, DBClusterIdentifier: string, DBClusterEndpointResourceIdentifier: string, Endpoint: string, Status: string, EndpointType: string, CustomEndpointType: string, StaticMembers: list, ExcludedMembers: list, DBClusterEndpointArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusterEndpoints")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of DBClusterParameterGroup descriptions. If a DBClusterParameterGroupName parameter is specified, the list will contain only the description of the specified DB cluster parameter group.
#
# GET /
# operationId: GET_DescribeDBClusterParameterGroups
export def "get-describe-db-cluster-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of a specific DB cluster parameter group to return details for. Constraints: If supplied, must match the name of an existing DBClusterParameterGroup.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBClusterParameterGroups request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-26 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, DBClusterParameterGroups: table<DBClusterParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBClusterParameterGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusterParameterGroups")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterParameterGroupName": $db_cluster_parameter_group_name, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of DBClusterParameterGroup descriptions. If a DBClusterParameterGroupName parameter is specified, the list will contain only the description of the specified DB cluster parameter group.
#
# POST /
# operationId: POST_DescribeDBClusterParameterGroups
export def "post-describe-db-cluster-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-26 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, DBClusterParameterGroups: table<DBClusterParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBClusterParameterGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusterParameterGroups")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the detailed parameter list for a particular DB cluster parameter group.
#
# GET /
# operationId: GET_DescribeDBClusterParameters
export def "get-describe-db-cluster-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of a specific DB cluster parameter group to return parameter details for. Constraints: If supplied, must match the name of an existing DBClusterParameterGroup. (required)
  --source: string # A value that indicates to return only parameters for a specific source. Parameter sources can be engine, service, or customer.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBClusterParameters request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-27 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Parameters: table<ParameterName: string, ParameterValue: string, Description: string, Source: string, ApplyType: string, DataType: string, AllowedValues: string, IsModifiable: bool, MinimumEngineVersion: string, ApplyMethod: string>, Marker: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBClusterParameterGroupName' missing: pass --db-cluster-parameter-group-name" } }
  let action = ($action | default "DescribeDBClusterParameters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "Source" $source "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterParameterGroupName": $db_cluster_parameter_group_name, "Source": $source, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the detailed parameter list for a particular DB cluster parameter group.
#
# POST /
# operationId: POST_DescribeDBClusterParameters
export def "post-describe-db-cluster-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-27 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Parameters: table<ParameterName: string, ParameterValue: string, Description: string, Source: string, ApplyType: string, DataType: string, AllowedValues: string, IsModifiable: bool, MinimumEngineVersion: string, ApplyMethod: string>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusterParameters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot. When sharing snapshots with other Amazon accounts, DescribeDBClusterSnapshotAttributes returns the restore attribute and a list of IDs for the Amazon accounts that are authorized to copy or restore the manual DB cluster snapshot. If all is included in the list of values for the restore attribute, then the manual DB cluster snapshot is public and can be copied or restored by all Amazon accounts. To add or remove access for an Amazon account to copy or restore a manual DB cluster snapshot, or to make the manual DB cluster snapshot public or private, use the ModifyDBClusterSnapshotAttribute API action.
#
# GET /
# operationId: GET_DescribeDBClusterSnapshotAttributes
export def "get-describe-db-cluster-snapshot-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-snapshot-identifier: string # The identifier for the DB cluster snapshot to describe the attributes for. (required)
  --action: string@action-completer-28 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterSnapshotAttributesResult: record<DBClusterSnapshotIdentifier: string, DBClusterSnapshotAttributes: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_snapshot_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterSnapshotIdentifier' missing: pass --db-cluster-snapshot-identifier" } }
  let action = ($action | default "DescribeDBClusterSnapshotAttributes")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterSnapshotIdentifier" $db_cluster_snapshot_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterSnapshotIdentifier": $db_cluster_snapshot_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of DB cluster snapshot attribute names and values for a manual DB cluster snapshot. When sharing snapshots with other Amazon accounts, DescribeDBClusterSnapshotAttributes returns the restore attribute and a list of IDs for the Amazon accounts that are authorized to copy or restore the manual DB cluster snapshot. If all is included in the list of values for the restore attribute, then the manual DB cluster snapshot is public and can be copied or restored by all Amazon accounts. To add or remove access for an Amazon account to copy or restore a manual DB cluster snapshot, or to make the manual DB cluster snapshot public or private, use the ModifyDBClusterSnapshotAttribute API action.
#
# POST /
# operationId: POST_DescribeDBClusterSnapshotAttributes
export def "post-describe-db-cluster-snapshot-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-28 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterSnapshotAttributesResult: record<DBClusterSnapshotIdentifier: string, DBClusterSnapshotAttributes: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusterSnapshotAttributes")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about DB cluster snapshots. This API action supports pagination.
#
# GET /
# operationId: GET_DescribeDBClusterSnapshots
export def "get-describe-db-cluster-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The ID of the DB cluster to retrieve the list of DB cluster snapshots for. This parameter can't be used in conjunction with the DBClusterSnapshotIdentifier parameter. This parameter is not case-sensitive. Constraints: If supplied, must match the identifier of an existing DBCluster.
  --db-cluster-snapshot-identifier: string # A specific DB cluster snapshot identifier to describe. This parameter can't be used in conjunction with the DBClusterIdentifier parameter. This value is stored as a lowercase string. Constraints: If supplied, must match the identifier of an existing DBClusterSnapshot. If this identifier is for an automated snapshot, the SnapshotType parameter must also be specified.
  --snapshot-type: string # The type of DB cluster snapshots to be returned. You can specify one of the following values: automated - Return all DB cluster snapshots that have been automatically taken by Amazon Neptune for my Amazon account. manual - Return all DB cluster snapshots that have been taken by my Amazon account. shared - Return all manual DB cluster snapshots that have been shared to my Amazon account. public - Return all DB cluster snapshots that have been marked as public. If you don't specify a SnapshotType value, then both automated and manual DB cluster snapshots are returned. You can include shared DB cluster snapshots with these results by setting the IncludeShared parameter to true. You can include public DB cluster snapshots with these results by setting the IncludePublic parameter to true. The IncludeShared and IncludePublic parameters don't apply for SnapshotType values of manual or automated. The IncludePublic parameter doesn't apply when SnapshotType is set to shared. The IncludeShared parameter doesn't apply when SnapshotType is set to public.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBClusterSnapshots request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --include-shared: oneof<nothing, bool> # True to include shared manual DB cluster snapshots from other Amazon accounts that this Amazon account has been given permission to copy or restore, and otherwise false. The default is false. You can give an Amazon account permission to restore a manual DB cluster snapshot from another Amazon account by the ModifyDBClusterSnapshotAttribute API action.
  --include-public: oneof<nothing, bool> # True to include manual DB cluster snapshots that are public and can be copied or restored by any Amazon account, and otherwise false. The default is false. The default is false. You can share a manual DB cluster snapshot as public by using the ModifyDBClusterSnapshotAttribute API action.
  --action: string@action-completer-29 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, DBClusterSnapshots: table<AvailabilityZones: list, DBClusterSnapshotIdentifier: string, DBClusterIdentifier: string, SnapshotCreateTime: string, Engine: string, AllocatedStorage: int, Status: string, Port: int, VpcId: string, ClusterCreateTime: string, MasterUsername: string, EngineVersion: string, LicenseModel: string, SnapshotType: string, PercentProgress: int, StorageEncrypted: bool, KmsKeyId: string, DBClusterSnapshotArn: string, SourceDBClusterSnapshotArn: string, IAMDatabaseAuthenticationEnabled: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusterSnapshots")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "DBClusterSnapshotIdentifier" $db_cluster_snapshot_identifier "scalar") (serialize-qp "SnapshotType" $snapshot_type "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "IncludeShared" $include_shared "scalar") (serialize-qp "IncludePublic" $include_public "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "DBClusterSnapshotIdentifier": $db_cluster_snapshot_identifier, "SnapshotType": $snapshot_type, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "IncludeShared": $include_shared, "IncludePublic": $include_public, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about DB cluster snapshots. This API action supports pagination.
#
# POST /
# operationId: POST_DescribeDBClusterSnapshots
export def "post-describe-db-cluster-snapshots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-29 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, DBClusterSnapshots: table<AvailabilityZones: list, DBClusterSnapshotIdentifier: string, DBClusterIdentifier: string, SnapshotCreateTime: string, Engine: string, AllocatedStorage: int, Status: string, Port: int, VpcId: string, ClusterCreateTime: string, MasterUsername: string, EngineVersion: string, LicenseModel: string, SnapshotType: string, PercentProgress: int, StorageEncrypted: bool, KmsKeyId: string, DBClusterSnapshotArn: string, SourceDBClusterSnapshotArn: string, IAMDatabaseAuthenticationEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusterSnapshots")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about provisioned DB clusters, and supports pagination. This operation can also return information for Amazon RDS clusters and Amazon DocDB clusters.
#
# GET /
# operationId: GET_DescribeDBClusters
export def "get-describe-db-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The user-supplied DB cluster identifier. If this parameter is specified, information from only the specific DB cluster is returned. This parameter isn't case-sensitive. Constraints: If supplied, must match an existing DBClusterIdentifier.
  --filters: list # A filter that specifies one or more DB clusters to describe. Supported filters: db-cluster-id - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list will only include information about the DB clusters identified by these ARNs. engine - Accepts an engine name (such as neptune), and restricts the results list to DB clusters created by that engine. For example, to invoke this API from the Amazon CLI and filter so that only Neptune DB clusters are returned, you could use the following command:
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBClusters request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-30 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, DBClusters: table<AllocatedStorage: int, AvailabilityZones: list, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list, DBClusterMembers: list, VpcSecurityGroups: list, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list, PendingModifiedValues: record, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about provisioned DB clusters, and supports pagination. This operation can also return information for Amazon RDS clusters and Amazon DocDB clusters.
#
# POST /
# operationId: POST_DescribeDBClusters
export def "post-describe-db-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-30 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, DBClusters: table<AllocatedStorage: int, AvailabilityZones: list, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list, DBClusterMembers: list, VpcSecurityGroups: list, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list, PendingModifiedValues: record, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBClusters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of the available DB engines.
#
# GET /
# operationId: GET_DescribeDBEngineVersions
export def "get-describe-db-engine-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine: string # The database engine to return.
  --engine-version: string # The database engine version to return. Example: 5.1.49
  --db-parameter-group-family: string # The name of a specific DB parameter group family to return details for. Constraints: If supplied, must match an existing DBParameterGroupFamily.
  --filters: list # Not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more than the MaxRecords value is available, a pagination token called a marker is included in the response so that the following results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --default-only: oneof<nothing, bool> # Indicates that only the default version of the specified engine or engine and major version combination is returned.
  --list-supported-character-sets: oneof<nothing, bool> # If this parameter is specified and the requested engine supports the CharacterSetName parameter for CreateDBInstance, the response includes a list of supported character sets for each engine version.
  --list-supported-timezones: oneof<nothing, bool> # If this parameter is specified and the requested engine supports the TimeZone parameter for CreateDBInstance, the response includes a list of supported time zones for each engine version.
  --action: string@action-completer-31 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, DBEngineVersions: table<Engine: string, EngineVersion: string, DBParameterGroupFamily: string, DBEngineDescription: string, DBEngineVersionDescription: string, DefaultCharacterSet: record, SupportedCharacterSets: list, ValidUpgradeTarget: list, SupportedTimezones: list, ExportableLogTypes: list, SupportsLogExportsToCloudwatchLogs: bool, SupportsReadReplica: bool, SupportsGlobalDatabases: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBEngineVersions")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Engine" $engine "scalar") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "DBParameterGroupFamily" $db_parameter_group_family "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "DefaultOnly" $default_only "scalar") (serialize-qp "ListSupportedCharacterSets" $list_supported_character_sets "scalar") (serialize-qp "ListSupportedTimezones" $list_supported_timezones "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Engine": $engine, "EngineVersion": $engine_version, "DBParameterGroupFamily": $db_parameter_group_family, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "DefaultOnly": $default_only, "ListSupportedCharacterSets": $list_supported_character_sets, "ListSupportedTimezones": $list_supported_timezones, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of the available DB engines.
#
# POST /
# operationId: POST_DescribeDBEngineVersions
export def "post-describe-db-engine-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-31 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, DBEngineVersions: table<Engine: string, EngineVersion: string, DBParameterGroupFamily: string, DBEngineDescription: string, DBEngineVersionDescription: string, DefaultCharacterSet: record, SupportedCharacterSets: list, ValidUpgradeTarget: list, SupportedTimezones: list, ExportableLogTypes: list, SupportsLogExportsToCloudwatchLogs: bool, SupportsReadReplica: bool, SupportsGlobalDatabases: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBEngineVersions")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about provisioned instances, and supports pagination. This operation can also return information for Amazon RDS instances and Amazon DocDB instances.
#
# GET /
# operationId: GET_DescribeDBInstances
export def "get-describe-db-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The user-supplied instance identifier. If this parameter is specified, information from only the specific DB instance is returned. This parameter isn't case-sensitive. Constraints: If supplied, must match the identifier of an existing DBInstance.
  --filters: list # A filter that specifies one or more DB instances to describe. Supported filters: db-cluster-id - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list will only include information about the DB instances associated with the DB clusters identified by these ARNs. engine - Accepts an engine name (such as neptune), and restricts the results list to DB instances created by that engine. For example, to invoke this API from the Amazon CLI and filter so that only Neptune DB instances are returned, you could use the following command:
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBInstances request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-32 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, DBInstances: table<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list, VpcSecurityGroups: list, DBParameterGroups: list, AvailabilityZone: string, DBSubnetGroup: record, PreferredMaintenanceWindow: string, PendingModifiedValues: record, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list, ReadReplicaDBClusterIdentifiers: list, LicenseModel: string, Iops: int, OptionGroupMemberships: list, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list, DeletionProtection: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBInstances")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBInstanceIdentifier" $db_instance_identifier "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBInstanceIdentifier": $db_instance_identifier, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about provisioned instances, and supports pagination. This operation can also return information for Amazon RDS instances and Amazon DocDB instances.
#
# POST /
# operationId: POST_DescribeDBInstances
export def "post-describe-db-instances" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-32 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, DBInstances: table<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list, VpcSecurityGroups: list, DBParameterGroups: list, AvailabilityZone: string, DBSubnetGroup: record, PreferredMaintenanceWindow: string, PendingModifiedValues: record, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list, ReadReplicaDBClusterIdentifiers: list, LicenseModel: string, Iops: int, OptionGroupMemberships: list, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list, DeletionProtection: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBInstances")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of DBParameterGroup descriptions. If a DBParameterGroupName is specified, the list will contain only the description of the specified DB parameter group.
#
# GET /
# operationId: GET_DescribeDBParameterGroups
export def "get-describe-db-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-name: string # The name of a specific DB parameter group to return details for. Constraints: If supplied, must match the name of an existing DBClusterParameterGroup.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBParameterGroups request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-33 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, DBParameterGroups: table<DBParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBParameterGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBParameterGroups")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBParameterGroupName" $db_parameter_group_name "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBParameterGroupName": $db_parameter_group_name, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of DBParameterGroup descriptions. If a DBParameterGroupName is specified, the list will contain only the description of the specified DB parameter group.
#
# POST /
# operationId: POST_DescribeDBParameterGroups
export def "post-describe-db-parameter-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-33 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, DBParameterGroups: table<DBParameterGroupName: string, DBParameterGroupFamily: string, Description: string, DBParameterGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBParameterGroups")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the detailed parameter list for a particular DB parameter group.
#
# GET /
# operationId: GET_DescribeDBParameters
export def "get-describe-db-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-name: string # The name of a specific DB parameter group to return details for. Constraints: If supplied, must match the name of an existing DBParameterGroup. (required)
  --source: string # The parameter types to return. Default: All parameter types returned Valid Values: user | system | engine-default
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBParameters request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-34 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Parameters: table<ParameterName: string, ParameterValue: string, Description: string, Source: string, ApplyType: string, DataType: string, AllowedValues: string, IsModifiable: bool, MinimumEngineVersion: string, ApplyMethod: string>, Marker: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupName' missing: pass --db-parameter-group-name" } }
  let action = ($action | default "DescribeDBParameters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBParameterGroupName" $db_parameter_group_name "scalar") (serialize-qp "Source" $source "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBParameterGroupName": $db_parameter_group_name, "Source": $source, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the detailed parameter list for a particular DB parameter group.
#
# POST /
# operationId: POST_DescribeDBParameters
export def "post-describe-db-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-34 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Parameters: table<ParameterName: string, ParameterValue: string, Description: string, Source: string, ApplyType: string, DataType: string, AllowedValues: string, IsModifiable: bool, MinimumEngineVersion: string, ApplyMethod: string>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBParameters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of DBSubnetGroup descriptions. If a DBSubnetGroupName is specified, the list will contain only the descriptions of the specified DBSubnetGroup. For an overview of CIDR ranges, go to the Wikipedia Tutorial (http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing).
#
# GET /
# operationId: GET_DescribeDBSubnetGroups
export def "get-describe-db-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-subnet-group-name: string # The name of the DB subnet group to return details for.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeDBSubnetGroups request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-35 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, DBSubnetGroups: table<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBSubnetGroups")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBSubnetGroupName": $db_subnet_group_name, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of DBSubnetGroup descriptions. If a DBSubnetGroupName is specified, the list will contain only the descriptions of the specified DBSubnetGroup. For an overview of CIDR ranges, go to the Wikipedia Tutorial (http://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing).
#
# POST /
# operationId: POST_DescribeDBSubnetGroups
export def "post-describe-db-subnet-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-35 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, DBSubnetGroups: table<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeDBSubnetGroups")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the default engine and system parameter information for the cluster database engine.
#
# GET /
# operationId: GET_DescribeEngineDefaultClusterParameters
export def "get-describe-engine-default-cluster-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-family: string # The name of the DB cluster parameter group family to return engine parameter information for. (required)
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeEngineDefaultClusterParameters request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-36 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<EngineDefaults: record<DBParameterGroupFamily: string, Marker: string, Parameters: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_parameter_group_family == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupFamily' missing: pass --db-parameter-group-family" } }
  let action = ($action | default "DescribeEngineDefaultClusterParameters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBParameterGroupFamily" $db_parameter_group_family "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBParameterGroupFamily": $db_parameter_group_family, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the default engine and system parameter information for the cluster database engine.
#
# POST /
# operationId: POST_DescribeEngineDefaultClusterParameters
export def "post-describe-engine-default-cluster-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-36 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<EngineDefaults: record<DBParameterGroupFamily: string, Marker: string, Parameters: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeEngineDefaultClusterParameters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the default engine and system parameter information for the specified database engine.
#
# GET /
# operationId: GET_DescribeEngineDefaultParameters
export def "get-describe-engine-default-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-family: string # The name of the DB parameter group family. (required)
  --filters: list # Not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeEngineDefaultParameters request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-37 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<EngineDefaults: record<DBParameterGroupFamily: string, Marker: string, Parameters: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_parameter_group_family == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupFamily' missing: pass --db-parameter-group-family" } }
  let action = ($action | default "DescribeEngineDefaultParameters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBParameterGroupFamily" $db_parameter_group_family "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBParameterGroupFamily": $db_parameter_group_family, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the default engine and system parameter information for the specified database engine.
#
# POST /
# operationId: POST_DescribeEngineDefaultParameters
export def "post-describe-engine-default-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-37 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<EngineDefaults: record<DBParameterGroupFamily: string, Marker: string, Parameters: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeEngineDefaultParameters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Displays a list of categories for all event source types, or, if specified, for a specified source type.
#
# GET /
# operationId: GET_DescribeEventCategories
export def "get-describe-event-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-type: string # The type of source that is generating the events. Valid values: db-instance | db-parameter-group | db-security-group | db-snapshot
  --filters: list # This parameter is not currently supported.
  --action: string@action-completer-38 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<EventCategoriesMapList: table<SourceType: string, EventCategories: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeEventCategories")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SourceType" $source_type "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SourceType": $source_type, "Filters": $filters, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Displays a list of categories for all event source types, or, if specified, for a specified source type.
#
# POST /
# operationId: POST_DescribeEventCategories
export def "post-describe-event-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-38 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<EventCategoriesMapList: table<SourceType: string, EventCategories: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeEventCategories")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all the subscription descriptions for a customer account. The description for a subscription includes SubscriptionName, SNSTopicARN, CustomerID, SourceType, SourceID, CreationTime, and Status. If you specify a SubscriptionName, lists the description for that subscription.
#
# GET /
# operationId: GET_DescribeEventSubscriptions
export def "get-describe-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the event notification subscription you want to describe.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeOrderableDBInstanceOptions request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords .
  --action: string@action-completer-39 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, EventSubscriptionsList: table<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list, EventCategoriesList: list, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeEventSubscriptions")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SubscriptionName": $subscription_name, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all the subscription descriptions for a customer account. The description for a subscription includes SubscriptionName, SNSTopicARN, CustomerID, SourceType, SourceID, CreationTime, and Status. If you specify a SubscriptionName, lists the description for that subscription.
#
# POST /
# operationId: POST_DescribeEventSubscriptions
export def "post-describe-event-subscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-39 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, EventSubscriptionsList: table<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list, EventCategoriesList: list, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeEventSubscriptions")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. Events specific to a particular DB instance, DB security group, database snapshot, or DB parameter group can be obtained by providing the name as a parameter. By default, the past hour of events are returned.
#
# GET /
# operationId: GET_DescribeEvents
export def "get-describe-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-identifier: string # The identifier of the event source for which events are returned. If not specified, then all sources are included in the response. Constraints: If SourceIdentifier is supplied, SourceType must also be provided. If the source type is DBInstance, then a DBInstanceIdentifier must be supplied. If the source type is DBSecurityGroup, a DBSecurityGroupName must be supplied. If the source type is DBParameterGroup, a DBParameterGroupName must be supplied. If the source type is DBSnapshot, a DBSnapshotIdentifier must be supplied. Cannot end with a hyphen or contain two consecutive hyphens.
  --source-type: string@source-type-completer # The event source to retrieve events for. If no value is specified, all events are returned.
  --start-time: string # The beginning of the time interval to retrieve events for, specified in ISO 8601 format. For more information about ISO 8601, go to the ISO8601 Wikipedia page. (http://en.wikipedia.org/wiki/ISO_8601) Example: 2009-07-08T18:00Z (format: date-time)
  --end-time: string # The end of the time interval for which to retrieve events, specified in ISO 8601 format. For more information about ISO 8601, go to the ISO8601 Wikipedia page. (http://en.wikipedia.org/wiki/ISO_8601) Example: 2009-07-08T18:00Z (format: date-time)
  --duration: int # The number of minutes to retrieve events for. Default: 60
  --event-categories: list # A list of event categories that trigger notifications for a event notification subscription.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeEvents request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords.
  --action: string@action-completer-40 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, Events: table<SourceIdentifier: string, SourceType: string, Message: string, EventCategories: list, Date: string, SourceArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeEvents")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SourceIdentifier" $source_identifier "scalar") (serialize-qp "SourceType" $source_type "scalar") (serialize-qp "StartTime" $start_time "scalar") (serialize-qp "EndTime" $end_time "scalar") (serialize-qp "Duration" $duration "scalar") (serialize-qp "EventCategories" $event_categories "multi") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SourceIdentifier": $source_identifier, "SourceType": $source_type, "StartTime": $start_time, "EndTime": $end_time, "Duration": $duration, "EventCategories": $event_categories, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns events related to DB instances, DB security groups, DB snapshots, and DB parameter groups for the past 14 days. Events specific to a particular DB instance, DB security group, database snapshot, or DB parameter group can be obtained by providing the name as a parameter. By default, the past hour of events are returned.
#
# POST /
# operationId: POST_DescribeEvents
export def "post-describe-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-40 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, Events: table<SourceIdentifier: string, SourceType: string, Message: string, EventCategories: list, Date: string, SourceArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeEvents")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns information about Neptune global database clusters. This API supports pagination.
#
# GET /
# operationId: GET_DescribeGlobalClusters
export def "get-describe-global-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The user-supplied DB cluster identifier. If this parameter is specified, only information about the specified DB cluster is returned. This parameter is not case-sensitive. Constraints: If supplied, must match an existing DB cluster identifier.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination marker token is included in the response that you can use to retrieve the remaining results. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # (Optional) A pagination token returned by a previous call to DescribeGlobalClusters. If this parameter is specified, the response will only include records beyond the marker, up to the number specified by MaxRecords.
  --action: string@action-completer-41 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<Marker: string, GlobalClusters: table<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeGlobalClusters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "GlobalClusterIdentifier" $global_cluster_identifier "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GlobalClusterIdentifier": $global_cluster_identifier, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about Neptune global database clusters. This API supports pagination.
#
# POST /
# operationId: POST_DescribeGlobalClusters
export def "post-describe-global-clusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-41 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<Marker: string, GlobalClusters: table<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeGlobalClusters")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of orderable DB instance options for the specified engine.
#
# GET /
# operationId: GET_DescribeOrderableDBInstanceOptions
export def "get-describe-orderable-db-instance-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --engine: string # The name of the engine to retrieve DB instance options for. (required)
  --engine-version: string # The engine version filter value. Specify this parameter to show only the available offerings matching the specified engine version.
  --db-instance-class: string # The DB instance class filter value. Specify this parameter to show only the available offerings matching the specified DB instance class.
  --license-model: string # The license model filter value. Specify this parameter to show only the available offerings matching the specified license model.
  --vpc: oneof<nothing, bool> # The VPC filter value. Specify this parameter to show only the available VPC or non-VPC offerings.
  --filters: list # This parameter is not currently supported.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --marker: string # An optional pagination token provided by a previous DescribeOrderableDBInstanceOptions request. If this parameter is specified, the response includes only records beyond the marker, up to the value specified by MaxRecords .
  --action: string@action-completer-42 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<OrderableDBInstanceOptions: table<Engine: string, EngineVersion: string, DBInstanceClass: string, LicenseModel: string, AvailabilityZones: list, MultiAZCapable: bool, ReadReplicaCapable: bool, Vpc: bool, SupportsStorageEncryption: bool, StorageType: string, SupportsIops: bool, SupportsEnhancedMonitoring: bool, SupportsIAMDatabaseAuthentication: bool, SupportsPerformanceInsights: bool, MinStorageSize: int, MaxStorageSize: int, MinIopsPerDbInstance: int, MaxIopsPerDbInstance: int, MinIopsPerGib: float, MaxIopsPerGib: float, SupportsGlobalDatabases: bool>, Marker: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($engine == null) { error make --unspanned { msg: "required query parameter 'Engine' missing: pass --engine" } }
  let action = ($action | default "DescribeOrderableDBInstanceOptions")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Engine" $engine "scalar") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "DBInstanceClass" $db_instance_class "scalar") (serialize-qp "LicenseModel" $license_model "scalar") (serialize-qp "Vpc" $vpc "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Engine": $engine, "EngineVersion": $engine_version, "DBInstanceClass": $db_instance_class, "LicenseModel": $license_model, "Vpc": $vpc, "Filters": $filters, "MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of orderable DB instance options for the specified engine.
#
# POST /
# operationId: POST_DescribeOrderableDBInstanceOptions
export def "post-describe-orderable-db-instance-options" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-42 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<OrderableDBInstanceOptions: table<Engine: string, EngineVersion: string, DBInstanceClass: string, LicenseModel: string, AvailabilityZones: list, MultiAZCapable: bool, ReadReplicaCapable: bool, Vpc: bool, SupportsStorageEncryption: bool, StorageType: string, SupportsIops: bool, SupportsEnhancedMonitoring: bool, SupportsIAMDatabaseAuthentication: bool, SupportsPerformanceInsights: bool, MinStorageSize: int, MaxStorageSize: int, MinIopsPerDbInstance: int, MaxIopsPerDbInstance: int, MinIopsPerGib: float, MaxIopsPerGib: float, SupportsGlobalDatabases: bool>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeOrderableDBInstanceOptions")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
#
# GET /
# operationId: GET_DescribePendingMaintenanceActions
export def "get-describe-pending-maintenance-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-identifier: string # The ARN of a resource to return pending maintenance actions for.
  --filters: list # A filter that specifies one or more resources to return pending maintenance actions for. Supported filters: db-cluster-id - Accepts DB cluster identifiers and DB cluster Amazon Resource Names (ARNs). The results list will only include pending maintenance actions for the DB clusters identified by these ARNs. db-instance-id - Accepts DB instance identifiers and DB instance ARNs. The results list will only include pending maintenance actions for the DB instances identified by these ARNs.
  --marker: string # An optional pagination token provided by a previous DescribePendingMaintenanceActions request. If this parameter is specified, the response includes only records beyond the marker, up to a number of records specified by MaxRecords.
  --max-records: int # The maximum number of records to include in the response. If more records exist than the specified MaxRecords value, a pagination token called a marker is included in the response so that the remaining results can be retrieved. Default: 100 Constraints: Minimum 20, maximum 100.
  --action: string@action-completer-43 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<PendingMaintenanceActions: table<ResourceIdentifier: string, PendingMaintenanceActionDetails: list>, Marker: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribePendingMaintenanceActions")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "ResourceIdentifier" $resource_identifier "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "Marker" $marker "scalar") (serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ResourceIdentifier": $resource_identifier, "Filters": $filters, "Marker": $marker, "MaxRecords": $max_records, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of resources (for example, DB instances) that have at least one pending maintenance action.
#
# POST /
# operationId: POST_DescribePendingMaintenanceActions
export def "post-describe-pending-maintenance-actions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-records: string # Pagination limit
  --marker: string # Pagination token
  --action: string@action-completer-43 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<PendingMaintenanceActions: table<ResourceIdentifier: string, PendingMaintenanceActionDetails: list>, Marker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribePendingMaintenanceActions")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "MaxRecords" $max_records "scalar") (serialize-qp "Marker" $marker "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxRecords": $max_records, "Marker": $marker, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# You can call DescribeValidDBInstanceModifications to learn what modifications you can make to your DB instance. You can use this information when you call ModifyDBInstance.
#
# GET /
# operationId: GET_DescribeValidDBInstanceModifications
export def "get-describe-valid-db-instance-modifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The customer identifier or the ARN of your DB instance. (required)
  --action: string@action-completer-44 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<ValidDBInstanceModificationsMessage: record<Storage: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_instance_identifier == null) { error make --unspanned { msg: "required query parameter 'DBInstanceIdentifier' missing: pass --db-instance-identifier" } }
  let action = ($action | default "DescribeValidDBInstanceModifications")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBInstanceIdentifier" $db_instance_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBInstanceIdentifier": $db_instance_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# You can call DescribeValidDBInstanceModifications to learn what modifications you can make to your DB instance. You can use this information when you call ModifyDBInstance.
#
# POST /
# operationId: POST_DescribeValidDBInstanceModifications
export def "post-describe-valid-db-instance-modifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-44 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<ValidDBInstanceModificationsMessage: record<Storage: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "DescribeValidDBInstanceModifications")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Forces a failover for a DB cluster. A failover for a DB cluster promotes one of the Read Replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer). Amazon Neptune will automatically fail over to a Read Replica, if one exists, when the primary instance fails. You can force a failover when you want to simulate a failure of a primary instance for testing. Because each instance in a DB cluster has its own endpoint address, you will need to clean up and re-establish any existing connections that use those endpoint addresses when the failover is complete.
#
# GET /
# operationId: GET_FailoverDBCluster
export def "get-failover-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # A DB cluster identifier to force a failover for. This parameter is not case-sensitive. Constraints: Must match the identifier of an existing DBCluster.
  --target-db-instance-identifier: string # The name of the instance to promote to the primary instance. You must specify the instance identifier for an Read Replica in the DB cluster. For example, mydbcluster-replica1.
  --action: string@action-completer-45 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "FailoverDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "TargetDBInstanceIdentifier" $target_db_instance_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "TargetDBInstanceIdentifier": $target_db_instance_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Forces a failover for a DB cluster. A failover for a DB cluster promotes one of the Read Replicas (read-only instances) in the DB cluster to be the primary instance (the cluster writer). Amazon Neptune will automatically fail over to a Read Replica, if one exists, when the primary instance fails. You can force a failover when you want to simulate a failure of a primary instance for testing. Because each instance in a DB cluster has its own endpoint address, you will need to clean up and re-establish any existing connections that use those endpoint addresses when the failover is complete.
#
# POST /
# operationId: POST_FailoverDBCluster
export def "post-failover-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-45 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "FailoverDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Initiates the failover process for a Neptune global database. A failover for a Neptune global database promotes one of secondary read-only DB clusters to be the primary DB cluster and demotes the primary DB cluster to being a secondary (read-only) DB cluster. In other words, the role of the current primary DB cluster and the selected target secondary DB cluster are switched. The selected secondary DB cluster assumes full read/write capabilities for the Neptune global database. This action applies only to Neptune global databases. This action is only intended for use on healthy Neptune global databases with healthy Neptune DB clusters and no region-wide outages, to test disaster recovery scenarios or to reconfigure the global database topology.
#
# GET /
# operationId: GET_FailoverGlobalCluster
export def "get-failover-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # Identifier of the Neptune global database that should be failed over. The identifier is the unique key assigned by the user when the Neptune global database was created. In other words, it's the name of the global database that you want to fail over. Constraints: Must match the identifier of an existing Neptune global database. (required)
  --target-db-cluster-identifier: string # The Amazon Resource Name (ARN) of the secondary Neptune DB cluster that you want to promote to primary for the global database. (required)
  --action: string@action-completer-46 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($global_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'GlobalClusterIdentifier' missing: pass --global-cluster-identifier" } }
  if ($target_db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'TargetDbClusterIdentifier' missing: pass --target-db-cluster-identifier" } }
  let action = ($action | default "FailoverGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "GlobalClusterIdentifier" $global_cluster_identifier "scalar") (serialize-qp "TargetDbClusterIdentifier" $target_db_cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GlobalClusterIdentifier": $global_cluster_identifier, "TargetDbClusterIdentifier": $target_db_cluster_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Initiates the failover process for a Neptune global database. A failover for a Neptune global database promotes one of secondary read-only DB clusters to be the primary DB cluster and demotes the primary DB cluster to being a secondary (read-only) DB cluster. In other words, the role of the current primary DB cluster and the selected target secondary DB cluster are switched. The selected secondary DB cluster assumes full read/write capabilities for the Neptune global database. This action applies only to Neptune global databases. This action is only intended for use on healthy Neptune global databases with healthy Neptune DB clusters and no region-wide outages, to test disaster recovery scenarios or to reconfigure the global database topology.
#
# POST /
# operationId: POST_FailoverGlobalCluster
export def "post-failover-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-46 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "FailoverGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all tags on an Amazon Neptune resource.
#
# GET /
# operationId: GET_ListTagsForResource
export def "get-list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon Neptune resource with tags to be listed. This value is an Amazon Resource Name (ARN). For information about creating an ARN, see Constructing an Amazon Resource Name (ARN) (https://docs.aws.amazon.com/neptune/latest/UserGuide/tagging.ARN.html#tagging.ARN.Constructing). (required)
  --filters: list # This parameter is not currently supported.
  --action: string@action-completer-47 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<TagList: table<Key: string, Value: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name == null) { error make --unspanned { msg: "required query parameter 'ResourceName' missing: pass --resource-name" } }
  let action = ($action | default "ListTagsForResource")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "ResourceName" $resource_name "scalar") (serialize-qp "Filters" $filters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ResourceName": $resource_name, "Filters": $filters, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lists all tags on an Amazon Neptune resource.
#
# POST /
# operationId: POST_ListTagsForResource
export def "post-list-tags-for-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-47 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<TagList: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ListTagsForResource")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modify a setting for a DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
#
# GET /
# operationId: GET_ModifyDBCluster
export def "get-modify-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The DB cluster identifier for the cluster being modified. This parameter is not case-sensitive. Constraints: Must match the identifier of an existing DBCluster. (required)
  --new-db-cluster-identifier: string # The new DB cluster identifier for the DB cluster when renaming a DB cluster. This value is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens The first character must be a letter Cannot end with a hyphen or contain two consecutive hyphens Example: my-cluster2
  --apply-immediately: oneof<nothing, bool> # A value that specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the PreferredMaintenanceWindow setting for the DB cluster. If this parameter is set to false, changes to the DB cluster are applied during the next maintenance window. The ApplyImmediately parameter only affects NewDBClusterIdentifier values. If you set the ApplyImmediately parameter value to false, then changes to NewDBClusterIdentifier values are applied during the next maintenance window. All other changes are applied immediately, regardless of the value of the ApplyImmediately parameter. Default: false
  --backup-retention-period: int # The number of days for which automated backups are retained. You must specify a minimum value of 1. Default: 1 Constraints: Must be a value from 1 to 35
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group to use for the DB cluster.
  --vpc-security-group-ids: list # A list of VPC security groups that the DB cluster will belong to.
  --port: int # The port number on which the DB cluster accepts connections. Constraints: Value must be 1150-65535 Default: The same port as the original DB cluster.
  --master-user-password: string # Not supported by Neptune.
  --option-group-name: string # Not supported by Neptune.
  --preferred-backup-window: string # The daily time range during which automated backups are created if automated backups are enabled, using the BackupRetentionPeriod parameter. The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Region. Constraints: Must be in the format hh24:mi-hh24:mi. Must be in Universal Coordinated Time (UTC). Must not conflict with the preferred maintenance window. Must be at least 30 minutes.
  --preferred-maintenance-window: string # The weekly time range during which system maintenance can occur, in Universal Coordinated Time (UTC). Format: ddd:hh24:mi-ddd:hh24:mi The default is a 30-minute window selected at random from an 8-hour block of time for each Amazon Region, occurring on a random day of the week. Valid Days: Mon, Tue, Wed, Thu, Fri, Sat, Sun. Constraints: Minimum 30-minute window.
  --enable-iam-database-authentication: oneof<nothing, bool> # True to enable mapping of Amazon Identity and Access Management (IAM) accounts to database accounts, and otherwise false. Default: false
  --cloudwatch-logs-export-configuration: record # The configuration setting for the log types to be enabled for export to CloudWatch Logs for a specific DB cluster.
  --engine-version: string # The version number of the database engine to which you want to upgrade. Changing this parameter results in an outage. The change is applied during the next maintenance window unless the ApplyImmediately parameter is set to true. For a list of valid engine versions, see Engine Releases for Amazon Neptune (https://docs.aws.amazon.com/neptune/latest/userguide/engine-releases.html), or call DescribeDBEngineVersions (https://docs.aws.amazon.com/neptune/latest/userguide/api-other-apis.html#DescribeDBEngineVersions).
  --allow-major-version-upgrade: oneof<nothing, bool> # A value that indicates whether upgrades between different major versions are allowed. Constraints: You must set the allow-major-version-upgrade flag when providing an EngineVersion parameter that uses a different major version than the DB cluster's current version.
  --db-instance-parameter-group-name: string # The name of the DB parameter group to apply to all instances of the DB cluster. When you apply a parameter group using DBInstanceParameterGroupName, parameter changes aren't applied during the next maintenance window but instead are applied immediately. Default: The existing name setting Constraints: The DB parameter group must be in the same DB parameter group family as the target DB cluster version. The DBInstanceParameterGroupName parameter is only valid in combination with the AllowMajorVersionUpgrade parameter.
  --deletion-protection: oneof<nothing, bool> # A value that indicates whether the DB cluster has deletion protection enabled. The database can't be deleted when deletion protection is enabled. By default, deletion protection is disabled.
  --copy-tags-to-snapshot: oneof<nothing, bool> # If set to true, tags are copied to any snapshot of the DB cluster that is created.
  --serverless-v2-scaling-configuration: record
  --action: string@action-completer-48 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  let action = ($action | default "ModifyDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "NewDBClusterIdentifier" $new_db_cluster_identifier "scalar") (serialize-qp "ApplyImmediately" $apply_immediately "scalar") (serialize-qp "BackupRetentionPeriod" $backup_retention_period "scalar") (serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "Port" $port "scalar") (serialize-qp "MasterUserPassword" $master_user_password "scalar") (serialize-qp "OptionGroupName" $option_group_name "scalar") (serialize-qp "PreferredBackupWindow" $preferred_backup_window "scalar") (serialize-qp "PreferredMaintenanceWindow" $preferred_maintenance_window "scalar") (serialize-qp "EnableIAMDatabaseAuthentication" $enable_iam_database_authentication "scalar") (serialize-qp "CloudwatchLogsExportConfiguration" $cloudwatch_logs_export_configuration "multi") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "AllowMajorVersionUpgrade" $allow_major_version_upgrade "scalar") (serialize-qp "DBInstanceParameterGroupName" $db_instance_parameter_group_name "scalar") (serialize-qp "DeletionProtection" $deletion_protection "scalar") (serialize-qp "CopyTagsToSnapshot" $copy_tags_to_snapshot "scalar") (serialize-qp "ServerlessV2ScalingConfiguration" $serverless_v2_scaling_configuration "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "NewDBClusterIdentifier": $new_db_cluster_identifier, "ApplyImmediately": $apply_immediately, "BackupRetentionPeriod": $backup_retention_period, "DBClusterParameterGroupName": $db_cluster_parameter_group_name, "VpcSecurityGroupIds": $vpc_security_group_ids, "Port": $port, "MasterUserPassword": $master_user_password, "OptionGroupName": $option_group_name, "PreferredBackupWindow": $preferred_backup_window, "PreferredMaintenanceWindow": $preferred_maintenance_window, "EnableIAMDatabaseAuthentication": $enable_iam_database_authentication, "CloudwatchLogsExportConfiguration": $cloudwatch_logs_export_configuration, "EngineVersion": $engine_version, "AllowMajorVersionUpgrade": $allow_major_version_upgrade, "DBInstanceParameterGroupName": $db_instance_parameter_group_name, "DeletionProtection": $deletion_protection, "CopyTagsToSnapshot": $copy_tags_to_snapshot, "ServerlessV2ScalingConfiguration": $serverless_v2_scaling_configuration, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modify a setting for a DB cluster. You can change one or more database configuration parameters by specifying these parameters and the new values in the request.
#
# POST /
# operationId: POST_ModifyDBCluster
export def "post-modify-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-48 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the properties of an endpoint in an Amazon Neptune DB cluster.
#
# GET /
# operationId: GET_ModifyDBClusterEndpoint
export def "get-modify-db-cluster-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-endpoint-identifier: string # The identifier of the endpoint to modify. This parameter is stored as a lowercase string. (required)
  --endpoint-type: string # The type of the endpoint. One of: READER, WRITER, ANY.
  --static-members: list # List of DB instance identifiers that are part of the custom endpoint group.
  --excluded-members: list # List of DB instance identifiers that aren't part of the custom endpoint group. All other eligible instances are reachable through the custom endpoint. Only relevant if the list of static members is empty.
  --action: string@action-completer-49 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterEndpointIdentifier: string, DBClusterIdentifier: string, DBClusterEndpointResourceIdentifier: string, Endpoint: string, Status: string, EndpointType: string, CustomEndpointType: string, StaticMembers: list<string>, ExcludedMembers: list<string>, DBClusterEndpointArn: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_endpoint_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterEndpointIdentifier' missing: pass --db-cluster-endpoint-identifier" } }
  let action = ($action | default "ModifyDBClusterEndpoint")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterEndpointIdentifier" $db_cluster_endpoint_identifier "scalar") (serialize-qp "EndpointType" $endpoint_type "scalar") (serialize-qp "StaticMembers" $static_members "multi") (serialize-qp "ExcludedMembers" $excluded_members "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterEndpointIdentifier": $db_cluster_endpoint_identifier, "EndpointType": $endpoint_type, "StaticMembers": $static_members, "ExcludedMembers": $excluded_members, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies the properties of an endpoint in an Amazon Neptune DB cluster.
#
# POST /
# operationId: POST_ModifyDBClusterEndpoint
export def "post-modify-db-cluster-endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-49 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterEndpointIdentifier: string, DBClusterIdentifier: string, DBClusterEndpointResourceIdentifier: string, Endpoint: string, Status: string, EndpointType: string, CustomEndpointType: string, StaticMembers: list<string>, ExcludedMembers: list<string>, DBClusterEndpointArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyDBClusterEndpoint")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: ParameterName, ParameterValue, and ApplyMethod. A maximum of 20 parameters can be modified in a single request. Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot without failover to the DB cluster associated with the parameter group before the change can take effect. After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon Neptune to fully complete the create action before the parameter group is used as the default for a new DB cluster. This is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the character_set_database parameter. You can use the Parameter Groups option of the Amazon Neptune console or the DescribeDBClusterParameters command to verify that your DB cluster parameter group has been created or modified.
#
# GET /
# operationId: GET_ModifyDBClusterParameterGroup
export def "get-modify-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group to modify. (required)
  --parameters: list # A list of parameters in the DB cluster parameter group to modify. (required)
  --action: string@action-completer-50 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterParameterGroupName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBClusterParameterGroupName' missing: pass --db-cluster-parameter-group-name" } }
  if ($parameters == null) { error make --unspanned { msg: "required query parameter 'Parameters' missing: pass --parameters" } }
  let action = ($action | default "ModifyDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "Parameters" $parameters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterParameterGroupName": $db_cluster_parameter_group_name, "Parameters": $parameters, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a DB cluster parameter group. To modify more than one parameter, submit a list of the following: ParameterName, ParameterValue, and ApplyMethod. A maximum of 20 parameters can be modified in a single request. Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot without failover to the DB cluster associated with the parameter group before the change can take effect. After you create a DB cluster parameter group, you should wait at least 5 minutes before creating your first DB cluster that uses that DB cluster parameter group as the default parameter group. This allows Amazon Neptune to fully complete the create action before the parameter group is used as the default for a new DB cluster. This is especially important for parameters that are critical when creating the default database for a DB cluster, such as the character set for the default database defined by the character_set_database parameter. You can use the Parameter Groups option of the Amazon Neptune console or the DescribeDBClusterParameters command to verify that your DB cluster parameter group has been created or modified.
#
# POST /
# operationId: POST_ModifyDBClusterParameterGroup
export def "post-modify-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-50 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterParameterGroupName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot. To share a manual DB cluster snapshot with other Amazon accounts, specify restore as the AttributeName and use the ValuesToAdd parameter to add a list of IDs of the Amazon accounts that are authorized to restore the manual DB cluster snapshot. Use the value all to make the manual DB cluster snapshot public, which means that it can be copied or restored by all Amazon accounts. Do not add the all value for any manual DB cluster snapshots that contain private information that you don't want available to all Amazon accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized Amazon account IDs for the ValuesToAdd parameter. You can't use all as a value for that parameter in this case. To view which Amazon accounts have access to copy or restore a manual DB cluster snapshot, or whether a manual DB cluster snapshot public or private, use the DescribeDBClusterSnapshotAttributes API action.
#
# GET /
# operationId: GET_ModifyDBClusterSnapshotAttribute
export def "get-modify-db-cluster-snapshot-attribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-snapshot-identifier: string # The identifier for the DB cluster snapshot to modify the attributes for. (required)
  --attribute-name: string # The name of the DB cluster snapshot attribute to modify. To manage authorization for other Amazon accounts to copy or restore a manual DB cluster snapshot, set this value to restore. (required)
  --values-to-add: list # A list of DB cluster snapshot attributes to add to the attribute specified by AttributeName. To authorize other Amazon accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more Amazon account IDs, or all to make the manual DB cluster snapshot restorable by any Amazon account. Do not add the all value for any manual DB cluster snapshots that contain private information that you don't want available to all Amazon accounts.
  --values-to-remove: list # A list of DB cluster snapshot attributes to remove from the attribute specified by AttributeName. To remove authorization for other Amazon accounts to copy or restore a manual DB cluster snapshot, set this list to include one or more Amazon account identifiers, or all to remove authorization for any Amazon account to copy or restore the DB cluster snapshot. If you specify all, an Amazon account whose account ID is explicitly added to the restore attribute can still copy or restore a manual DB cluster snapshot.
  --action: string@action-completer-51 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterSnapshotAttributesResult: record<DBClusterSnapshotIdentifier: string, DBClusterSnapshotAttributes: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_snapshot_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterSnapshotIdentifier' missing: pass --db-cluster-snapshot-identifier" } }
  if ($attribute_name == null) { error make --unspanned { msg: "required query parameter 'AttributeName' missing: pass --attribute-name" } }
  let action = ($action | default "ModifyDBClusterSnapshotAttribute")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterSnapshotIdentifier" $db_cluster_snapshot_identifier "scalar") (serialize-qp "AttributeName" $attribute_name "scalar") (serialize-qp "ValuesToAdd" $values_to_add "multi") (serialize-qp "ValuesToRemove" $values_to_remove "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterSnapshotIdentifier": $db_cluster_snapshot_identifier, "AttributeName": $attribute_name, "ValuesToAdd": $values_to_add, "ValuesToRemove": $values_to_remove, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Adds an attribute and values to, or removes an attribute and values from, a manual DB cluster snapshot. To share a manual DB cluster snapshot with other Amazon accounts, specify restore as the AttributeName and use the ValuesToAdd parameter to add a list of IDs of the Amazon accounts that are authorized to restore the manual DB cluster snapshot. Use the value all to make the manual DB cluster snapshot public, which means that it can be copied or restored by all Amazon accounts. Do not add the all value for any manual DB cluster snapshots that contain private information that you don't want available to all Amazon accounts. If a manual DB cluster snapshot is encrypted, it can be shared, but only by specifying a list of authorized Amazon account IDs for the ValuesToAdd parameter. You can't use all as a value for that parameter in this case. To view which Amazon accounts have access to copy or restore a manual DB cluster snapshot, or whether a manual DB cluster snapshot public or private, use the DescribeDBClusterSnapshotAttributes API action.
#
# POST /
# operationId: POST_ModifyDBClusterSnapshotAttribute
export def "post-modify-db-cluster-snapshot-attribute" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-51 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterSnapshotAttributesResult: record<DBClusterSnapshotIdentifier: string, DBClusterSnapshotAttributes: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyDBClusterSnapshotAttribute")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. To learn what modifications you can make to your DB instance, call DescribeValidDBInstanceModifications before you call ModifyDBInstance.
#
# GET /
# operationId: GET_ModifyDBInstance
export def "get-modify-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The DB instance identifier. This value is stored as a lowercase string. Constraints: Must match the identifier of an existing DBInstance. (required)
  --allocated-storage: int # Not supported by Neptune.
  --db-instance-class: string # The new compute and memory capacity of the DB instance, for example, db.m4.large. Not all DB instance classes are available in all Amazon Regions. If you modify the DB instance class, an outage occurs during the change. The change is applied during the next maintenance window, unless ApplyImmediately is specified as true for this request. Default: Uses existing setting
  --db-subnet-group-name: string # The new DB subnet group for the DB instance. You can use this parameter to move your DB instance to a different VPC. Changing the subnet group causes an outage during the change. The change is applied during the next maintenance window, unless you specify true for the ApplyImmediately parameter. Constraints: If supplied, must match the name of an existing DBSubnetGroup. Example: mySubnetGroup
  --db-security-groups: list # A list of DB security groups to authorize on this DB instance. Changing this setting doesn't result in an outage and the change is asynchronously applied as soon as possible. Constraints: If supplied, must match existing DBSecurityGroups.
  --vpc-security-group-ids: list # A list of EC2 VPC security groups to authorize on this DB instance. This change is asynchronously applied as soon as possible. Not applicable. The associated list of EC2 VPC security groups is managed by the DB cluster. For more information, see ModifyDBCluster. Constraints: If supplied, must match existing VpcSecurityGroupIds.
  --apply-immediately: oneof<nothing, bool> # Specifies whether the modifications in this request and any pending modifications are asynchronously applied as soon as possible, regardless of the PreferredMaintenanceWindow setting for the DB instance. If this parameter is set to false, changes to the DB instance are applied during the next maintenance window. Some parameter changes can cause an outage and are applied on the next call to RebootDBInstance, or the next failure reboot. Default: false
  --master-user-password: string # Not supported by Neptune.
  --db-parameter-group-name: string # The name of the DB parameter group to apply to the DB instance. Changing this setting doesn't result in an outage. The parameter group name itself is changed immediately, but the actual parameter changes are not applied until you reboot the instance without failover. The db instance will NOT be rebooted automatically and the parameter changes will NOT be applied during the next maintenance window. Default: Uses existing setting Constraints: The DB parameter group must be in the same DB parameter group family as this DB instance.
  --backup-retention-period: int # Not applicable. The retention period for automated backups is managed by the DB cluster. For more information, see ModifyDBCluster. Default: Uses existing setting
  --preferred-backup-window: string # The daily time range during which automated backups are created if automated backups are enabled. Not applicable. The daily time range for creating automated backups is managed by the DB cluster. For more information, see ModifyDBCluster. Constraints: Must be in the format hh24:mi-hh24:mi Must be in Universal Time Coordinated (UTC) Must not conflict with the preferred maintenance window Must be at least 30 minutes
  --preferred-maintenance-window: string # The weekly time range (in UTC) during which system maintenance can occur, which might result in an outage. Changing this parameter doesn't result in an outage, except in the following situation, and the change is asynchronously applied as soon as possible. If there are pending actions that cause a reboot, and the maintenance window is changed to include the current time, then changing this parameter will cause a reboot of the DB instance. If moving this window to the current time, there must be at least 30 minutes between the current time and end of the window to ensure pending changes are applied. Default: Uses existing setting Format: ddd:hh24:mi-ddd:hh24:mi Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun Constraints: Must be at least 30 minutes
  --multi-az: oneof<nothing, bool> # Specifies if the DB instance is a Multi-AZ deployment. Changing this parameter doesn't result in an outage and the change is applied during the next maintenance window unless the ApplyImmediately parameter is set to true for this request.
  --engine-version: string # The version number of the database engine to upgrade to. Currently, setting this parameter has no effect. To upgrade your database engine to the most recent release, use the ApplyPendingMaintenanceAction API.
  --allow-major-version-upgrade: oneof<nothing, bool> # Indicates that major version upgrades are allowed. Changing this parameter doesn't result in an outage and the change is asynchronously applied as soon as possible.
  --auto-minor-version-upgrade: oneof<nothing, bool> # Indicates that minor version upgrades are applied automatically to the DB instance during the maintenance window. Changing this parameter doesn't result in an outage except in the following case and the change is asynchronously applied as soon as possible. An outage will result if this parameter is set to true during the maintenance window, and a newer minor version is available, and Neptune has enabled auto patching for that engine version.
  --license-model: string # Not supported by Neptune.
  --iops: int # The new Provisioned IOPS (I/O operations per second) value for the instance. Changing this setting doesn't result in an outage and the change is applied during the next maintenance window unless the ApplyImmediately parameter is set to true for this request. Default: Uses existing setting
  --option-group-name: string # (Not supported by Neptune)
  --new-db-instance-identifier: string # The new DB instance identifier for the DB instance when renaming a DB instance. When you change the DB instance identifier, an instance reboot will occur immediately if you set Apply Immediately to true, or will occur during the next maintenance window if Apply Immediately to false. This value is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Cannot end with a hyphen or contain two consecutive hyphens. Example: mydbinstance
  --storage-type: string # Not supported.
  --tde-credential-arn: string # The ARN from the key store with which to associate the instance for TDE encryption.
  --tde-credential-password: string # The password for the given ARN from the key store in order to access the device.
  --ca-certificate-identifier: string # Indicates the certificate that needs to be associated with the instance.
  --domain: string # Not supported.
  --copy-tags-to-snapshot: oneof<nothing, bool> # True to copy all tags from the DB instance to snapshots of the DB instance, and otherwise false. The default is false.
  --monitoring-interval: int # The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. If MonitoringRoleArn is specified, then you must also set MonitoringInterval to a value other than 0. Valid Values: 0, 1, 5, 10, 15, 30, 60
  --db-port-number: int # The port number on which the database accepts connections. The value of the DBPortNumber parameter must not match any of the port values specified for options in the option group for the DB instance. Your database will restart when you change the DBPortNumber value regardless of the value of the ApplyImmediately parameter. Default: 8182
  --publicly-accessible: oneof<nothing, bool> # This flag should no longer be used.
  --monitoring-role-arn: string # The ARN for the IAM role that permits Neptune to send enhanced monitoring metrics to Amazon CloudWatch Logs. For example, arn:aws:iam:123456789012:role/emaccess. If MonitoringInterval is set to a value other than 0, then you must supply a MonitoringRoleArn value.
  --domain-iam-role-name: string # Not supported
  --promotion-tier: int # A value that specifies the order in which a Read Replica is promoted to the primary instance after a failure of the existing primary instance. Default: 1 Valid Values: 0 - 15
  --enable-iam-database-authentication: oneof<nothing, bool> # True to enable mapping of Amazon Identity and Access Management (IAM) accounts to database accounts, and otherwise false. You can enable IAM database authentication for the following database engines Not applicable. Mapping Amazon IAM accounts to database accounts is managed by the DB cluster. For more information, see ModifyDBCluster. Default: false
  --enable-performance-insights: oneof<nothing, bool> # (Not supported by Neptune)
  --performance-insights-kms-key-id: string # (Not supported by Neptune)
  --cloudwatch-logs-export-configuration: record # The configuration setting for the log types to be enabled for export to CloudWatch Logs for a specific DB instance or DB cluster.
  --deletion-protection: oneof<nothing, bool> # A value that indicates whether the DB instance has deletion protection enabled. The database can't be deleted when deletion protection is enabled. By default, deletion protection is disabled. See Deleting a DB Instance (https://docs.aws.amazon.com/neptune/latest/userguide/manage-console-instances-delete.html).
  --action: string@action-completer-52 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBInstance: record<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record<Address: string, Port: int, HostedZoneId: string>, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list<record>, VpcSecurityGroups: list<record>, DBParameterGroups: list<record>, AvailabilityZone: string, DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<DBInstanceClass: string, AllocatedStorage: int, MasterUserPassword: string, Port: int, BackupRetentionPeriod: int, MultiAZ: bool, EngineVersion: string, LicenseModel: string, Iops: int, DBInstanceIdentifier: string, StorageType: string, CACertificateIdentifier: string, DBSubnetGroupName: string, PendingCloudwatchLogsExports: record>, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list<string>, ReadReplicaDBClusterIdentifiers: list<string>, LicenseModel: string, Iops: int, OptionGroupMemberships: list<record>, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list<record>, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list<record>, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list<string>, DeletionProtection: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_instance_identifier == null) { error make --unspanned { msg: "required query parameter 'DBInstanceIdentifier' missing: pass --db-instance-identifier" } }
  let action = ($action | default "ModifyDBInstance")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBInstanceIdentifier" $db_instance_identifier "scalar") (serialize-qp "AllocatedStorage" $allocated_storage "scalar") (serialize-qp "DBInstanceClass" $db_instance_class "scalar") (serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "DBSecurityGroups" $db_security_groups "multi") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "ApplyImmediately" $apply_immediately "scalar") (serialize-qp "MasterUserPassword" $master_user_password "scalar") (serialize-qp "DBParameterGroupName" $db_parameter_group_name "scalar") (serialize-qp "BackupRetentionPeriod" $backup_retention_period "scalar") (serialize-qp "PreferredBackupWindow" $preferred_backup_window "scalar") (serialize-qp "PreferredMaintenanceWindow" $preferred_maintenance_window "scalar") (serialize-qp "MultiAZ" $multi_az "scalar") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "AllowMajorVersionUpgrade" $allow_major_version_upgrade "scalar") (serialize-qp "AutoMinorVersionUpgrade" $auto_minor_version_upgrade "scalar") (serialize-qp "LicenseModel" $license_model "scalar") (serialize-qp "Iops" $iops "scalar") (serialize-qp "OptionGroupName" $option_group_name "scalar") (serialize-qp "NewDBInstanceIdentifier" $new_db_instance_identifier "scalar") (serialize-qp "StorageType" $storage_type "scalar") (serialize-qp "TdeCredentialArn" $tde_credential_arn "scalar") (serialize-qp "TdeCredentialPassword" $tde_credential_password "scalar") (serialize-qp "CACertificateIdentifier" $ca_certificate_identifier "scalar") (serialize-qp "Domain" $domain "scalar") (serialize-qp "CopyTagsToSnapshot" $copy_tags_to_snapshot "scalar") (serialize-qp "MonitoringInterval" $monitoring_interval "scalar") (serialize-qp "DBPortNumber" $db_port_number "scalar") (serialize-qp "PubliclyAccessible" $publicly_accessible "scalar") (serialize-qp "MonitoringRoleArn" $monitoring_role_arn "scalar") (serialize-qp "DomainIAMRoleName" $domain_iam_role_name "scalar") (serialize-qp "PromotionTier" $promotion_tier "scalar") (serialize-qp "EnableIAMDatabaseAuthentication" $enable_iam_database_authentication "scalar") (serialize-qp "EnablePerformanceInsights" $enable_performance_insights "scalar") (serialize-qp "PerformanceInsightsKMSKeyId" $performance_insights_kms_key_id "scalar") (serialize-qp "CloudwatchLogsExportConfiguration" $cloudwatch_logs_export_configuration "multi") (serialize-qp "DeletionProtection" $deletion_protection "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBInstanceIdentifier": $db_instance_identifier, "AllocatedStorage": $allocated_storage, "DBInstanceClass": $db_instance_class, "DBSubnetGroupName": $db_subnet_group_name, "DBSecurityGroups": $db_security_groups, "VpcSecurityGroupIds": $vpc_security_group_ids, "ApplyImmediately": $apply_immediately, "MasterUserPassword": $master_user_password, "DBParameterGroupName": $db_parameter_group_name, "BackupRetentionPeriod": $backup_retention_period, "PreferredBackupWindow": $preferred_backup_window, "PreferredMaintenanceWindow": $preferred_maintenance_window, "MultiAZ": $multi_az, "EngineVersion": $engine_version, "AllowMajorVersionUpgrade": $allow_major_version_upgrade, "AutoMinorVersionUpgrade": $auto_minor_version_upgrade, "LicenseModel": $license_model, "Iops": $iops, "OptionGroupName": $option_group_name, "NewDBInstanceIdentifier": $new_db_instance_identifier, "StorageType": $storage_type, "TdeCredentialArn": $tde_credential_arn, "TdeCredentialPassword": $tde_credential_password, "CACertificateIdentifier": $ca_certificate_identifier, "Domain": $domain, "CopyTagsToSnapshot": $copy_tags_to_snapshot, "MonitoringInterval": $monitoring_interval, "DBPortNumber": $db_port_number, "PubliclyAccessible": $publicly_accessible, "MonitoringRoleArn": $monitoring_role_arn, "DomainIAMRoleName": $domain_iam_role_name, "PromotionTier": $promotion_tier, "EnableIAMDatabaseAuthentication": $enable_iam_database_authentication, "EnablePerformanceInsights": $enable_performance_insights, "PerformanceInsightsKMSKeyId": $performance_insights_kms_key_id, "CloudwatchLogsExportConfiguration": $cloudwatch_logs_export_configuration, "DeletionProtection": $deletion_protection, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies settings for a DB instance. You can change one or more database configuration parameters by specifying these parameters and the new values in the request. To learn what modifications you can make to your DB instance, call DescribeValidDBInstanceModifications before you call ModifyDBInstance.
#
# POST /
# operationId: POST_ModifyDBInstance
export def "post-modify-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-52 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBInstance: record<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record<Address: string, Port: int, HostedZoneId: string>, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list<record>, VpcSecurityGroups: list<record>, DBParameterGroups: list<record>, AvailabilityZone: string, DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<DBInstanceClass: string, AllocatedStorage: int, MasterUserPassword: string, Port: int, BackupRetentionPeriod: int, MultiAZ: bool, EngineVersion: string, LicenseModel: string, Iops: int, DBInstanceIdentifier: string, StorageType: string, CACertificateIdentifier: string, DBSubnetGroupName: string, PendingCloudwatchLogsExports: record>, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list<string>, ReadReplicaDBClusterIdentifiers: list<string>, LicenseModel: string, Iops: int, OptionGroupMemberships: list<record>, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list<record>, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list<record>, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list<string>, DeletionProtection: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyDBInstance")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a DB parameter group. To modify more than one parameter, submit a list of the following: ParameterName, ParameterValue, and ApplyMethod. A maximum of 20 parameters can be modified in a single request. Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot without failover to the DB instance associated with the parameter group before the change can take effect. After you modify a DB parameter group, you should wait at least 5 minutes before creating your first DB instance that uses that DB parameter group as the default parameter group. This allows Amazon Neptune to fully complete the modify action before the parameter group is used as the default for a new DB instance. This is especially important for parameters that are critical when creating the default database for a DB instance, such as the character set for the default database defined by the character_set_database parameter. You can use the Parameter Groups option of the Amazon Neptune console or the DescribeDBParameters command to verify that your DB parameter group has been created or modified.
#
# GET /
# operationId: GET_ModifyDBParameterGroup
export def "get-modify-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-name: string # The name of the DB parameter group. Constraints: If supplied, must match the name of an existing DBParameterGroup. (required)
  --parameters: list # An array of parameter names, values, and the apply method for the parameter update. At least one parameter name, value, and apply method must be supplied; subsequent arguments are optional. A maximum of 20 parameters can be modified in a single request. Valid Values (for the application method): immediate | pending-reboot You can use the immediate value with dynamic parameters only. You can use the pending-reboot value for both dynamic and static parameters, and changes are applied when you reboot the DB instance without failover. (required)
  --action: string@action-completer-53 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBParameterGroupName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupName' missing: pass --db-parameter-group-name" } }
  if ($parameters == null) { error make --unspanned { msg: "required query parameter 'Parameters' missing: pass --parameters" } }
  let action = ($action | default "ModifyDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBParameterGroupName" $db_parameter_group_name "scalar") (serialize-qp "Parameters" $parameters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBParameterGroupName": $db_parameter_group_name, "Parameters": $parameters, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a DB parameter group. To modify more than one parameter, submit a list of the following: ParameterName, ParameterValue, and ApplyMethod. A maximum of 20 parameters can be modified in a single request. Changes to dynamic parameters are applied immediately. Changes to static parameters require a reboot without failover to the DB instance associated with the parameter group before the change can take effect. After you modify a DB parameter group, you should wait at least 5 minutes before creating your first DB instance that uses that DB parameter group as the default parameter group. This allows Amazon Neptune to fully complete the modify action before the parameter group is used as the default for a new DB instance. This is especially important for parameters that are critical when creating the default database for a DB instance, such as the character set for the default database defined by the character_set_database parameter. You can use the Parameter Groups option of the Amazon Neptune console or the DescribeDBParameters command to verify that your DB parameter group has been created or modified.
#
# POST /
# operationId: POST_ModifyDBParameterGroup
export def "post-modify-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-53 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBParameterGroupName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two AZs in the Amazon Region.
#
# GET /
# operationId: GET_ModifyDBSubnetGroup
export def "get-modify-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-subnet-group-name: string # The name for the DB subnet group. This value is stored as a lowercase string. You can't modify the default subnet group. Constraints: Must match the name of an existing DBSubnetGroup. Must not be default. Example: mySubnetgroup (required)
  --db-subnet-group-description: string # The description for the DB subnet group.
  --subnet-ids: list # The EC2 subnet IDs for the DB subnet group. (required)
  --action: string@action-completer-54 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, DBSubnetGroupArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_subnet_group_name == null) { error make --unspanned { msg: "required query parameter 'DBSubnetGroupName' missing: pass --db-subnet-group-name" } }
  if ($subnet_ids == null) { error make --unspanned { msg: "required query parameter 'SubnetIds' missing: pass --subnet-ids" } }
  let action = ($action | default "ModifyDBSubnetGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "DBSubnetGroupDescription" $db_subnet_group_description "scalar") (serialize-qp "SubnetIds" $subnet_ids "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBSubnetGroupName": $db_subnet_group_name, "DBSubnetGroupDescription": $db_subnet_group_description, "SubnetIds": $subnet_ids, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies an existing DB subnet group. DB subnet groups must contain at least one subnet in at least two AZs in the Amazon Region.
#
# POST /
# operationId: POST_ModifyDBSubnetGroup
export def "post-modify-db-subnet-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-54 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list<record>, DBSubnetGroupArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyDBSubnetGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies an existing event notification subscription. Note that you can't modify the source identifiers using this call; to change source identifiers for a subscription, use the AddSourceIdentifierToSubscription and RemoveSourceIdentifierFromSubscription calls. You can see a list of the event categories for a given SourceType by using the DescribeEventCategories action.
#
# GET /
# operationId: GET_ModifyEventSubscription
export def "get-modify-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the event notification subscription. (required)
  --sns-topic-arn: string # The Amazon Resource Name (ARN) of the SNS topic created for event notification. The ARN is created by Amazon SNS when you create a topic and subscribe to it.
  --source-type: string # The type of source that is generating the events. For example, if you want to be notified of events generated by a DB instance, you would set this parameter to db-instance. if this value is not specified, all events are returned. Valid values: db-instance | db-parameter-group | db-security-group | db-snapshot
  --event-categories: list # A list of event categories for a SourceType that you want to subscribe to. You can see a list of the categories for a given SourceType by using the DescribeEventCategories action.
  --enabled: oneof<nothing, bool> # A Boolean value; set to true to activate the subscription.
  --action: string@action-completer-55 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_name == null) { error make --unspanned { msg: "required query parameter 'SubscriptionName' missing: pass --subscription-name" } }
  let action = ($action | default "ModifyEventSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "SnsTopicArn" $sns_topic_arn "scalar") (serialize-qp "SourceType" $source_type "scalar") (serialize-qp "EventCategories" $event_categories "multi") (serialize-qp "Enabled" $enabled "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SubscriptionName": $subscription_name, "SnsTopicArn": $sns_topic_arn, "SourceType": $source_type, "EventCategories": $event_categories, "Enabled": $enabled, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies an existing event notification subscription. Note that you can't modify the source identifiers using this call; to change source identifiers for a subscription, use the AddSourceIdentifierToSubscription and RemoveSourceIdentifierFromSubscription calls. You can see a list of the event categories for a given SourceType by using the DescribeEventCategories action.
#
# POST /
# operationId: POST_ModifyEventSubscription
export def "post-modify-event-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-55 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyEventSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modify a setting for an Amazon Neptune global cluster. You can change one or more database configuration parameters by specifying these parameters and their new values in the request.
#
# GET /
# operationId: GET_ModifyGlobalCluster
export def "get-modify-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The DB cluster identifier for the global cluster being modified. This parameter is not case-sensitive. Constraints: Must match the identifier of an existing global database cluster. (required)
  --new-global-cluster-identifier: string # A new cluster identifier to assign to the global database. This value is stored as a lowercase string. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens. The first character must be a letter. Can't end with a hyphen or contain two consecutive hyphens Example: my-cluster2
  --deletion-protection: oneof<nothing, bool> # Indicates whether the global database has deletion protection enabled. The global database cannot be deleted when deletion protection is enabled.
  --engine-version: string # The version number of the database engine to which you want to upgrade. Changing this parameter will result in an outage. The change is applied during the next maintenance window unless ApplyImmediately is enabled. To list all of the available Neptune engine versions, use the following command:
  --allow-major-version-upgrade: oneof<nothing, bool> # A value that indicates whether major version upgrades are allowed. Constraints: You must allow major version upgrades if you specify a value for the EngineVersion parameter that is a different major version than the DB cluster's current version. If you upgrade the major version of a global database, the cluster and DB instance parameter groups are set to the default parameter groups for the new version, so you will need to apply any custom parameter groups after completing the upgrade.
  --action: string@action-completer-56 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($global_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'GlobalClusterIdentifier' missing: pass --global-cluster-identifier" } }
  let action = ($action | default "ModifyGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "GlobalClusterIdentifier" $global_cluster_identifier "scalar") (serialize-qp "NewGlobalClusterIdentifier" $new_global_cluster_identifier "scalar") (serialize-qp "DeletionProtection" $deletion_protection "scalar") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "AllowMajorVersionUpgrade" $allow_major_version_upgrade "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GlobalClusterIdentifier": $global_cluster_identifier, "NewGlobalClusterIdentifier": $new_global_cluster_identifier, "DeletionProtection": $deletion_protection, "EngineVersion": $engine_version, "AllowMajorVersionUpgrade": $allow_major_version_upgrade, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modify a setting for an Amazon Neptune global cluster. You can change one or more database configuration parameters by specifying these parameters and their new values in the request.
#
# POST /
# operationId: POST_ModifyGlobalCluster
export def "post-modify-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-56 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ModifyGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Not supported.
#
# GET /
# operationId: GET_PromoteReadReplicaDBCluster
export def "get-promote-read-replica-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # Not supported. (required)
  --action: string@action-completer-57 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  let action = ($action | default "PromoteReadReplicaDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Not supported.
#
# POST /
# operationId: POST_PromoteReadReplicaDBCluster
export def "post-promote-read-replica-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-57 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "PromoteReadReplicaDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain modifications, or if you change the DB parameter group associated with the DB instance, you must reboot the instance for the changes to take effect. Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to rebooting.
#
# GET /
# operationId: GET_RebootDBInstance
export def "get-reboot-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-instance-identifier: string # The DB instance identifier. This parameter is stored as a lowercase string. Constraints: Must match the identifier of an existing DBInstance. (required)
  --force-failover: oneof<nothing, bool> # When true, the reboot is conducted through a MultiAZ failover. Constraint: You can't specify true if the instance is not configured for MultiAZ.
  --action: string@action-completer-58 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBInstance: record<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record<Address: string, Port: int, HostedZoneId: string>, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list<record>, VpcSecurityGroups: list<record>, DBParameterGroups: list<record>, AvailabilityZone: string, DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<DBInstanceClass: string, AllocatedStorage: int, MasterUserPassword: string, Port: int, BackupRetentionPeriod: int, MultiAZ: bool, EngineVersion: string, LicenseModel: string, Iops: int, DBInstanceIdentifier: string, StorageType: string, CACertificateIdentifier: string, DBSubnetGroupName: string, PendingCloudwatchLogsExports: record>, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list<string>, ReadReplicaDBClusterIdentifiers: list<string>, LicenseModel: string, Iops: int, OptionGroupMemberships: list<record>, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list<record>, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list<record>, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list<string>, DeletionProtection: bool>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_instance_identifier == null) { error make --unspanned { msg: "required query parameter 'DBInstanceIdentifier' missing: pass --db-instance-identifier" } }
  let action = ($action | default "RebootDBInstance")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBInstanceIdentifier" $db_instance_identifier "scalar") (serialize-qp "ForceFailover" $force_failover "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBInstanceIdentifier": $db_instance_identifier, "ForceFailover": $force_failover, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# You might need to reboot your DB instance, usually for maintenance reasons. For example, if you make certain modifications, or if you change the DB parameter group associated with the DB instance, you must reboot the instance for the changes to take effect. Rebooting a DB instance restarts the database engine service. Rebooting a DB instance results in a momentary outage, during which the DB instance status is set to rebooting.
#
# POST /
# operationId: POST_RebootDBInstance
export def "post-reboot-db-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-58 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBInstance: record<DBInstanceIdentifier: string, DBInstanceClass: string, Engine: string, DBInstanceStatus: string, MasterUsername: string, DBName: string, Endpoint: record<Address: string, Port: int, HostedZoneId: string>, AllocatedStorage: int, InstanceCreateTime: string, PreferredBackupWindow: string, BackupRetentionPeriod: int, DBSecurityGroups: list<record>, VpcSecurityGroups: list<record>, DBParameterGroups: list<record>, AvailabilityZone: string, DBSubnetGroup: record<DBSubnetGroupName: string, DBSubnetGroupDescription: string, VpcId: string, SubnetGroupStatus: string, Subnets: list, DBSubnetGroupArn: string>, PreferredMaintenanceWindow: string, PendingModifiedValues: record<DBInstanceClass: string, AllocatedStorage: int, MasterUserPassword: string, Port: int, BackupRetentionPeriod: int, MultiAZ: bool, EngineVersion: string, LicenseModel: string, Iops: int, DBInstanceIdentifier: string, StorageType: string, CACertificateIdentifier: string, DBSubnetGroupName: string, PendingCloudwatchLogsExports: record>, LatestRestorableTime: string, MultiAZ: bool, EngineVersion: string, AutoMinorVersionUpgrade: bool, ReadReplicaSourceDBInstanceIdentifier: string, ReadReplicaDBInstanceIdentifiers: list<string>, ReadReplicaDBClusterIdentifiers: list<string>, LicenseModel: string, Iops: int, OptionGroupMemberships: list<record>, CharacterSetName: string, SecondaryAvailabilityZone: string, PubliclyAccessible: bool, StatusInfos: list<record>, StorageType: string, TdeCredentialArn: string, DbInstancePort: int, DBClusterIdentifier: string, StorageEncrypted: bool, KmsKeyId: string, DbiResourceId: string, CACertificateIdentifier: string, DomainMemberships: list<record>, CopyTagsToSnapshot: bool, MonitoringInterval: int, EnhancedMonitoringResourceArn: string, MonitoringRoleArn: string, PromotionTier: int, DBInstanceArn: string, Timezone: string, IAMDatabaseAuthenticationEnabled: bool, PerformanceInsightsEnabled: bool, PerformanceInsightsKMSKeyId: string, EnabledCloudwatchLogsExports: list<string>, DeletionProtection: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "RebootDBInstance")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Detaches a Neptune DB cluster from a Neptune global database. A secondary cluster becomes a normal standalone cluster with read-write capability instead of being read-only, and no longer receives data from a the primary cluster.
#
# GET /
# operationId: GET_RemoveFromGlobalCluster
export def "get-remove-from-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --global-cluster-identifier: string # The identifier of the Neptune global database from which to detach the specified Neptune DB cluster. (required)
  --db-cluster-identifier: string # The Amazon Resource Name (ARN) identifying the cluster to be detached from the Neptune global database cluster. (required)
  --action: string@action-completer-59 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($global_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'GlobalClusterIdentifier' missing: pass --global-cluster-identifier" } }
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DbClusterIdentifier' missing: pass --db-cluster-identifier" } }
  let action = ($action | default "RemoveFromGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "GlobalClusterIdentifier" $global_cluster_identifier "scalar") (serialize-qp "DbClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GlobalClusterIdentifier": $global_cluster_identifier, "DbClusterIdentifier": $db_cluster_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Detaches a Neptune DB cluster from a Neptune global database. A secondary cluster becomes a normal standalone cluster with read-write capability instead of being read-only, and no longer receives data from a the primary cluster.
#
# POST /
# operationId: POST_RemoveFromGlobalCluster
export def "post-remove-from-global-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-59 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<GlobalCluster: record<GlobalClusterIdentifier: string, GlobalClusterResourceId: string, GlobalClusterArn: string, Status: string, Engine: string, EngineVersion: string, StorageEncrypted: bool, DeletionProtection: bool, GlobalClusterMembers: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "RemoveFromGlobalCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Disassociates an Identity and Access Management (IAM) role from a DB cluster.
#
# GET /
# operationId: GET_RemoveRoleFromDBCluster
export def "get-remove-role-from-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The name of the DB cluster to disassociate the IAM role from. (required)
  --role-arn: string # The Amazon Resource Name (ARN) of the IAM role to disassociate from the DB cluster, for example arn:aws:iam::123456789012:role/NeptuneAccessRole. (required)
  --feature-name: string # The name of the feature for the DB cluster that the IAM role is to be disassociated from. For the list of supported feature names, see DescribeDBEngineVersions (https://docs.aws.amazon.com/neptune/latest/userguide/api-other-apis.html#DescribeDBEngineVersions).
  --action: string@action-completer-60 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  if ($role_arn == null) { error make --unspanned { msg: "required query parameter 'RoleArn' missing: pass --role-arn" } }
  let action = ($action | default "RemoveRoleFromDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "RoleArn" $role_arn "scalar") (serialize-qp "FeatureName" $feature_name "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "RoleArn": $role_arn, "FeatureName": $feature_name, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Disassociates an Identity and Access Management (IAM) role from a DB cluster.
#
# POST /
# operationId: POST_RemoveRoleFromDBCluster
export def "post-remove-role-from-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-60 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "RemoveRoleFromDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes a source identifier from an existing event notification subscription.
#
# GET /
# operationId: GET_RemoveSourceIdentifierFromSubscription
export def "get-remove-source-identifier-from-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-name: string # The name of the event notification subscription you want to remove a source identifier from. (required)
  --source-identifier: string # The source identifier to be removed from the subscription, such as the DB instance identifier for a DB instance or the name of a security group. (required)
  --action: string@action-completer-61 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_name == null) { error make --unspanned { msg: "required query parameter 'SubscriptionName' missing: pass --subscription-name" } }
  if ($source_identifier == null) { error make --unspanned { msg: "required query parameter 'SourceIdentifier' missing: pass --source-identifier" } }
  let action = ($action | default "RemoveSourceIdentifierFromSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "SubscriptionName" $subscription_name "scalar") (serialize-qp "SourceIdentifier" $source_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SubscriptionName": $subscription_name, "SourceIdentifier": $source_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Removes a source identifier from an existing event notification subscription.
#
# POST /
# operationId: POST_RemoveSourceIdentifierFromSubscription
export def "post-remove-source-identifier-from-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-61 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<EventSubscription: record<CustomerAwsId: string, CustSubscriptionId: string, SnsTopicArn: string, Status: string, SubscriptionCreationTime: string, SourceType: string, SourceIdsList: list<string>, EventCategoriesList: list<string>, Enabled: bool, EventSubscriptionArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "RemoveSourceIdentifierFromSubscription")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Removes metadata tags from an Amazon Neptune resource.
#
# GET /
# operationId: GET_RemoveTagsFromResource
export def "get-remove-tags-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --resource-name: string # The Amazon Neptune resource that the tags are removed from. This value is an Amazon Resource Name (ARN). For information about creating an ARN, see Constructing an Amazon Resource Name (ARN) (https://docs.aws.amazon.com/neptune/latest/UserGuide/tagging.ARN.html#tagging.ARN.Constructing). (required)
  --tag-keys: list # The tag key (name) of the tag to be removed. (required)
  --action: string@action-completer-62 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource_name == null) { error make --unspanned { msg: "required query parameter 'ResourceName' missing: pass --resource-name" } }
  if ($tag_keys == null) { error make --unspanned { msg: "required query parameter 'TagKeys' missing: pass --tag-keys" } }
  let action = ($action | default "RemoveTagsFromResource")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "ResourceName" $resource_name "scalar") (serialize-qp "TagKeys" $tag_keys "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ResourceName": $resource_name, "TagKeys": $tag_keys, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Removes metadata tags from an Amazon Neptune resource.
#
# POST /
# operationId: POST_RemoveTagsFromResource
export def "post-remove-tags-from-resource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-62 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "RemoveTagsFromResource")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters submit a list of the following: ParameterName and ApplyMethod. To reset the entire DB cluster parameter group, specify the DBClusterParameterGroupName and ResetAllParameters parameters. When resetting the entire group, dynamic parameters are updated immediately and static parameters are set to pending-reboot to take effect on the next DB instance restart or RebootDBInstance request. You must call RebootDBInstance for every DB instance in your DB cluster that you want the updated static parameter to apply to.
#
# GET /
# operationId: GET_ResetDBClusterParameterGroup
export def "get-reset-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group to reset. (required)
  --reset-all-parameters: oneof<nothing, bool> # A value that is set to true to reset all parameters in the DB cluster parameter group to their default values, and false otherwise. You can't use this parameter if there is a list of parameter names specified for the Parameters parameter.
  --parameters: list # A list of parameter names in the DB cluster parameter group to reset to the default values. You can't use this parameter if the ResetAllParameters parameter is set to true.
  --action: string@action-completer-63 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBClusterParameterGroupName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBClusterParameterGroupName' missing: pass --db-cluster-parameter-group-name" } }
  let action = ($action | default "ResetDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "ResetAllParameters" $reset_all_parameters "scalar") (serialize-qp "Parameters" $parameters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterParameterGroupName": $db_cluster_parameter_group_name, "ResetAllParameters": $reset_all_parameters, "Parameters": $parameters, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a DB cluster parameter group to the default value. To reset specific parameters submit a list of the following: ParameterName and ApplyMethod. To reset the entire DB cluster parameter group, specify the DBClusterParameterGroupName and ResetAllParameters parameters. When resetting the entire group, dynamic parameters are updated immediately and static parameters are set to pending-reboot to take effect on the next DB instance restart or RebootDBInstance request. You must call RebootDBInstance for every DB instance in your DB cluster that you want the updated static parameter to apply to.
#
# POST /
# operationId: POST_ResetDBClusterParameterGroup
export def "post-reset-db-cluster-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-63 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBClusterParameterGroupName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ResetDBClusterParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a DB parameter group to the engine/system default value. To reset specific parameters, provide a list of the following: ParameterName and ApplyMethod. To reset the entire DB parameter group, specify the DBParameterGroup name and ResetAllParameters parameters. When resetting the entire group, dynamic parameters are updated immediately and static parameters are set to pending-reboot to take effect on the next DB instance restart or RebootDBInstance request.
#
# GET /
# operationId: GET_ResetDBParameterGroup
export def "get-reset-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-parameter-group-name: string # The name of the DB parameter group. Constraints: Must match the name of an existing DBParameterGroup. (required)
  --reset-all-parameters: oneof<nothing, bool> # Specifies whether (true) or not (false) to reset all parameters in the DB parameter group to default values. Default: true
  --parameters: list # To reset the entire DB parameter group, specify the DBParameterGroup name and ResetAllParameters parameters. To reset specific parameters, provide a list of the following: ParameterName and ApplyMethod. A maximum of 20 parameters can be modified in a single request. Valid Values (for Apply method): pending-reboot
  --action: string@action-completer-64 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBParameterGroupName: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_parameter_group_name == null) { error make --unspanned { msg: "required query parameter 'DBParameterGroupName' missing: pass --db-parameter-group-name" } }
  let action = ($action | default "ResetDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBParameterGroupName" $db_parameter_group_name "scalar") (serialize-qp "ResetAllParameters" $reset_all_parameters "scalar") (serialize-qp "Parameters" $parameters "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBParameterGroupName": $db_parameter_group_name, "ResetAllParameters": $reset_all_parameters, "Parameters": $parameters, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modifies the parameters of a DB parameter group to the engine/system default value. To reset specific parameters, provide a list of the following: ParameterName and ApplyMethod. To reset the entire DB parameter group, specify the DBParameterGroup name and ResetAllParameters parameters. When resetting the entire group, dynamic parameters are updated immediately and static parameters are set to pending-reboot to take effect on the next DB instance restart or RebootDBInstance request.
#
# POST /
# operationId: POST_ResetDBParameterGroup
export def "post-reset-db-parameter-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-64 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBParameterGroupName: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "ResetDBParameterGroup")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a new DB cluster from a DB snapshot or DB cluster snapshot. If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group. If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.
#
# GET /
# operationId: GET_RestoreDBClusterFromSnapshot
export def "get-restore-db-cluster-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --availability-zones: list # Provides the list of EC2 Availability Zones that instances in the restored DB cluster can be created in.
  --db-cluster-identifier: string # The name of the DB cluster to create from the DB snapshot or DB cluster snapshot. This parameter isn't case-sensitive. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens Example: my-snapshot-id (required)
  --snapshot-identifier: string # The identifier for the DB snapshot or DB cluster snapshot to restore from. You can use either the name or the Amazon Resource Name (ARN) to specify a DB cluster snapshot. However, you can use only the ARN to specify a DB snapshot. Constraints: Must match the identifier of an existing Snapshot. (required)
  --engine: string # The database engine to use for the new DB cluster. Default: The same as source Constraint: Must be compatible with the engine of the source (required)
  --engine-version: string # The version of the database engine to use for the new DB cluster.
  --port: int # The port number on which the new DB cluster accepts connections. Constraints: Value must be 1150-65535 Default: The same port as the original DB cluster.
  --db-subnet-group-name: string # The name of the DB subnet group to use for the new DB cluster. Constraints: If supplied, must match the name of an existing DBSubnetGroup. Example: mySubnetgroup
  --database-name: string # Not supported.
  --option-group-name: string # (Not supported by Neptune)
  --vpc-security-group-ids: list # A list of VPC security groups that the new DB cluster will belong to.
  --tags: list # The tags to be assigned to the restored DB cluster.
  --kms-key-id: string # The Amazon KMS key identifier to use when restoring an encrypted DB cluster from a DB snapshot or DB cluster snapshot. The KMS key identifier is the Amazon Resource Name (ARN) for the KMS encryption key. If you are restoring a DB cluster with the same Amazon account that owns the KMS encryption key used to encrypt the new DB cluster, then you can use the KMS key alias instead of the ARN for the KMS encryption key. If you do not specify a value for the KmsKeyId parameter, then the following will occur: If the DB snapshot or DB cluster snapshot in SnapshotIdentifier is encrypted, then the restored DB cluster is encrypted using the KMS key that was used to encrypt the DB snapshot or DB cluster snapshot. If the DB snapshot or DB cluster snapshot in SnapshotIdentifier is not encrypted, then the restored DB cluster is not encrypted.
  --enable-iam-database-authentication: oneof<nothing, bool> # True to enable mapping of Amazon Identity and Access Management (IAM) accounts to database accounts, and otherwise false. Default: false
  --enable-cloudwatch-logs-exports: list # The list of logs that the restored DB cluster is to export to Amazon CloudWatch Logs.
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group to associate with the new DB cluster. Constraints: If supplied, must match the name of an existing DBClusterParameterGroup.
  --deletion-protection: oneof<nothing, bool> # A value that indicates whether the DB cluster has deletion protection enabled. The database can't be deleted when deletion protection is enabled. By default, deletion protection is disabled.
  --copy-tags-to-snapshot: oneof<nothing, bool> # If set to true, tags are copied to any snapshot of the restored DB cluster that is created.
  --serverless-v2-scaling-configuration: record
  --action: string@action-completer-65 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  if ($snapshot_identifier == null) { error make --unspanned { msg: "required query parameter 'SnapshotIdentifier' missing: pass --snapshot-identifier" } }
  if ($engine == null) { error make --unspanned { msg: "required query parameter 'Engine' missing: pass --engine" } }
  let action = ($action | default "RestoreDBClusterFromSnapshot")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "AvailabilityZones" $availability_zones "multi") (serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "SnapshotIdentifier" $snapshot_identifier "scalar") (serialize-qp "Engine" $engine "scalar") (serialize-qp "EngineVersion" $engine_version "scalar") (serialize-qp "Port" $port "scalar") (serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "DatabaseName" $database_name "scalar") (serialize-qp "OptionGroupName" $option_group_name "scalar") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "Tags" $tags "multi") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "EnableIAMDatabaseAuthentication" $enable_iam_database_authentication "scalar") (serialize-qp "EnableCloudwatchLogsExports" $enable_cloudwatch_logs_exports "multi") (serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "DeletionProtection" $deletion_protection "scalar") (serialize-qp "CopyTagsToSnapshot" $copy_tags_to_snapshot "scalar") (serialize-qp "ServerlessV2ScalingConfiguration" $serverless_v2_scaling_configuration "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"AvailabilityZones": $availability_zones, "DBClusterIdentifier": $db_cluster_identifier, "SnapshotIdentifier": $snapshot_identifier, "Engine": $engine, "EngineVersion": $engine_version, "Port": $port, "DBSubnetGroupName": $db_subnet_group_name, "DatabaseName": $database_name, "OptionGroupName": $option_group_name, "VpcSecurityGroupIds": $vpc_security_group_ids, "Tags": $tags, "KmsKeyId": $kms_key_id, "EnableIAMDatabaseAuthentication": $enable_iam_database_authentication, "EnableCloudwatchLogsExports": $enable_cloudwatch_logs_exports, "DBClusterParameterGroupName": $db_cluster_parameter_group_name, "DeletionProtection": $deletion_protection, "CopyTagsToSnapshot": $copy_tags_to_snapshot, "ServerlessV2ScalingConfiguration": $serverless_v2_scaling_configuration, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a new DB cluster from a DB snapshot or DB cluster snapshot. If a DB snapshot is specified, the target DB cluster is created from the source DB snapshot with a default configuration and default security group. If a DB cluster snapshot is specified, the target DB cluster is created from the source DB cluster restore point with the same configuration as the original source DB cluster, except that the new DB cluster is created with the default security group.
#
# POST /
# operationId: POST_RestoreDBClusterFromSnapshot
export def "post-restore-db-cluster-from-snapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-65 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "RestoreDBClusterFromSnapshot")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before LatestRestorableTime for up to BackupRetentionPeriod days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. This action only restores the DB cluster, not the DB instances for that DB cluster. You must invoke the CreateDBInstance action to create DB instances for the restored DB cluster, specifying the identifier of the restored DB cluster in DBClusterIdentifier. You can create DB instances only after the RestoreDBClusterToPointInTime action has completed and the DB cluster is available.
#
# GET /
# operationId: GET_RestoreDBClusterToPointInTime
export def "get-restore-db-cluster-to-point-in-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The name of the new DB cluster to be created. Constraints: Must contain from 1 to 63 letters, numbers, or hyphens First character must be a letter Cannot end with a hyphen or contain two consecutive hyphens (required)
  --restore-type: string # The type of restore to be performed. You can specify one of the following values: full-copy - The new DB cluster is restored as a full copy of the source DB cluster. copy-on-write - The new DB cluster is restored as a clone of the source DB cluster. If you don't specify a RestoreType value, then the new DB cluster is restored as a full copy of the source DB cluster.
  --source-db-cluster-identifier: string # The identifier of the source DB cluster from which to restore. Constraints: Must match the identifier of an existing DBCluster. (required)
  --restore-to-time: string # The date and time to restore the DB cluster to. Valid Values: Value must be a time in Universal Coordinated Time (UTC) format Constraints: Must be before the latest restorable time for the DB instance Must be specified if UseLatestRestorableTime parameter is not provided Cannot be specified if UseLatestRestorableTime parameter is true Cannot be specified if RestoreType parameter is copy-on-write Example: 2015-03-07T23:45:00Z (format: date-time)
  --use-latest-restorable-time: oneof<nothing, bool> # A value that is set to true to restore the DB cluster to the latest restorable backup time, and false otherwise. Default: false Constraints: Cannot be specified if RestoreToTime parameter is provided.
  --port: int # The port number on which the new DB cluster accepts connections. Constraints: Value must be 1150-65535 Default: The same port as the original DB cluster.
  --db-subnet-group-name: string # The DB subnet group name to use for the new DB cluster. Constraints: If supplied, must match the name of an existing DBSubnetGroup. Example: mySubnetgroup
  --option-group-name: string # (Not supported by Neptune)
  --vpc-security-group-ids: list # A list of VPC security groups that the new DB cluster belongs to.
  --tags: list # The tags to be applied to the restored DB cluster.
  --kms-key-id: string # The Amazon KMS key identifier to use when restoring an encrypted DB cluster from an encrypted DB cluster. The KMS key identifier is the Amazon Resource Name (ARN) for the KMS encryption key. If you are restoring a DB cluster with the same Amazon account that owns the KMS encryption key used to encrypt the new DB cluster, then you can use the KMS key alias instead of the ARN for the KMS encryption key. You can restore to a new DB cluster and encrypt the new DB cluster with a KMS key that is different than the KMS key used to encrypt the source DB cluster. The new DB cluster is encrypted with the KMS key identified by the KmsKeyId parameter. If you do not specify a value for the KmsKeyId parameter, then the following will occur: If the DB cluster is encrypted, then the restored DB cluster is encrypted using the KMS key that was used to encrypt the source DB cluster. If the DB cluster is not encrypted, then the restored DB cluster is not encrypted. If DBClusterIdentifier refers to a DB cluster that is not encrypted, then the restore request is rejected.
  --enable-iam-database-authentication: oneof<nothing, bool> # True to enable mapping of Amazon Identity and Access Management (IAM) accounts to database accounts, and otherwise false. Default: false
  --enable-cloudwatch-logs-exports: list # The list of logs that the restored DB cluster is to export to CloudWatch Logs.
  --db-cluster-parameter-group-name: string # The name of the DB cluster parameter group to associate with the new DB cluster. Constraints: If supplied, must match the name of an existing DBClusterParameterGroup.
  --deletion-protection: oneof<nothing, bool> # A value that indicates whether the DB cluster has deletion protection enabled. The database can't be deleted when deletion protection is enabled. By default, deletion protection is disabled.
  --serverless-v2-scaling-configuration: record
  --action: string@action-completer-66 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  if ($source_db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'SourceDBClusterIdentifier' missing: pass --source-db-cluster-identifier" } }
  let action = ($action | default "RestoreDBClusterToPointInTime")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "RestoreType" $restore_type "scalar") (serialize-qp "SourceDBClusterIdentifier" $source_db_cluster_identifier "scalar") (serialize-qp "RestoreToTime" $restore_to_time "scalar") (serialize-qp "UseLatestRestorableTime" $use_latest_restorable_time "scalar") (serialize-qp "Port" $port "scalar") (serialize-qp "DBSubnetGroupName" $db_subnet_group_name "scalar") (serialize-qp "OptionGroupName" $option_group_name "scalar") (serialize-qp "VpcSecurityGroupIds" $vpc_security_group_ids "multi") (serialize-qp "Tags" $tags "multi") (serialize-qp "KmsKeyId" $kms_key_id "scalar") (serialize-qp "EnableIAMDatabaseAuthentication" $enable_iam_database_authentication "scalar") (serialize-qp "EnableCloudwatchLogsExports" $enable_cloudwatch_logs_exports "multi") (serialize-qp "DBClusterParameterGroupName" $db_cluster_parameter_group_name "scalar") (serialize-qp "DeletionProtection" $deletion_protection "scalar") (serialize-qp "ServerlessV2ScalingConfiguration" $serverless_v2_scaling_configuration "multi") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "RestoreType": $restore_type, "SourceDBClusterIdentifier": $source_db_cluster_identifier, "RestoreToTime": $restore_to_time, "UseLatestRestorableTime": $use_latest_restorable_time, "Port": $port, "DBSubnetGroupName": $db_subnet_group_name, "OptionGroupName": $option_group_name, "VpcSecurityGroupIds": $vpc_security_group_ids, "Tags": $tags, "KmsKeyId": $kms_key_id, "EnableIAMDatabaseAuthentication": $enable_iam_database_authentication, "EnableCloudwatchLogsExports": $enable_cloudwatch_logs_exports, "DBClusterParameterGroupName": $db_cluster_parameter_group_name, "DeletionProtection": $deletion_protection, "ServerlessV2ScalingConfiguration": $serverless_v2_scaling_configuration, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Restores a DB cluster to an arbitrary point in time. Users can restore to any point in time before LatestRestorableTime for up to BackupRetentionPeriod days. The target DB cluster is created from the source DB cluster with the same configuration as the original DB cluster, except that the new DB cluster is created with the default DB security group. This action only restores the DB cluster, not the DB instances for that DB cluster. You must invoke the CreateDBInstance action to create DB instances for the restored DB cluster, specifying the identifier of the restored DB cluster in DBClusterIdentifier. You can create DB instances only after the RestoreDBClusterToPointInTime action has completed and the DB cluster is available.
#
# POST /
# operationId: POST_RestoreDBClusterToPointInTime
export def "post-restore-db-cluster-to-point-in-time" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-66 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "RestoreDBClusterToPointInTime")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Starts an Amazon Neptune DB cluster that was stopped using the Amazon console, the Amazon CLI stop-db-cluster command, or the StopDBCluster API.
#
# GET /
# operationId: GET_StartDBCluster
export def "get-start-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The DB cluster identifier of the Neptune DB cluster to be started. This parameter is stored as a lowercase string. (required)
  --action: string@action-completer-67 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  let action = ($action | default "StartDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Starts an Amazon Neptune DB cluster that was stopped using the Amazon console, the Amazon CLI stop-db-cluster command, or the StopDBCluster API.
#
# POST /
# operationId: POST_StartDBCluster
export def "post-start-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-67 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "StartDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Stops an Amazon Neptune DB cluster. When you stop a DB cluster, Neptune retains the DB cluster's metadata, including its endpoints and DB parameter groups. Neptune also retains the transaction logs so you can do a point-in-time restore if necessary.
#
# GET /
# operationId: GET_StopDBCluster
export def "get-stop-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --db-cluster-identifier: string # The DB cluster identifier of the Neptune DB cluster to be stopped. This parameter is stored as a lowercase string. (required)
  --action: string@action-completer-68 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($db_cluster_identifier == null) { error make --unspanned { msg: "required query parameter 'DBClusterIdentifier' missing: pass --db-cluster-identifier" } }
  let action = ($action | default "StopDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "DBClusterIdentifier" $db_cluster_identifier "scalar") (serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"DBClusterIdentifier": $db_cluster_identifier, "Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Stops an Amazon Neptune DB cluster. When you stop a DB cluster, Neptune retains the DB cluster's metadata, including its endpoints and DB parameter groups. Neptune also retains the transaction logs so you can do a point-in-time restore if necessary.
#
# POST /
# operationId: POST_StopDBCluster
export def "post-stop-db-cluster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-68 # required
  --version: string@version-completer # required
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --body: any
]: any -> oneof<record<DBCluster: record<AllocatedStorage: int, AvailabilityZones: list<string>, BackupRetentionPeriod: int, CharacterSetName: string, DatabaseName: string, DBClusterIdentifier: string, DBClusterParameterGroup: string, DBSubnetGroup: string, Status: string, PercentProgress: string, EarliestRestorableTime: string, Endpoint: string, ReaderEndpoint: string, MultiAZ: bool, Engine: string, EngineVersion: string, LatestRestorableTime: string, Port: int, MasterUsername: string, DBClusterOptionGroupMemberships: list<record>, PreferredBackupWindow: string, PreferredMaintenanceWindow: string, ReplicationSourceIdentifier: string, ReadReplicaIdentifiers: list<string>, DBClusterMembers: list<record>, VpcSecurityGroups: list<record>, HostedZoneId: string, StorageEncrypted: bool, KmsKeyId: string, DbClusterResourceId: string, DBClusterArn: string, AssociatedRoles: list<record>, IAMDatabaseAuthenticationEnabled: bool, CloneGroupId: string, ClusterCreateTime: string, CopyTagsToSnapshot: bool, EnabledCloudwatchLogsExports: list<string>, PendingModifiedValues: record<PendingCloudwatchLogsExports: record, DBClusterIdentifier: string, IAMDatabaseAuthenticationEnabled: bool, EngineVersion: string, BackupRetentionPeriod: int, AllocatedStorage: int, Iops: int>, DeletionProtection: bool, CrossAccountClone: bool, AutomaticRestartTime: string, ServerlessV2ScalingConfiguration: record<MinCapacity: float, MaxCapacity: float>, GlobalClusterIdentifier: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let action = ($action | default "StopDBCluster")
  let version = ($version | default "2014-10-31")
  let qp = [(serialize-qp "Action" $action "scalar") (serialize-qp "Version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "text/xml"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"Action": $action, "Version": $version} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "text/xml"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}
