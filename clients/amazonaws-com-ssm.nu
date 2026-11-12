# Auto-generated client for Amazon Simple Systems Manager (SSM) v2014-11-06
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ssm/2014-11-06/openapi.json
# Auth: --token flag or $env.AMAZON_SIMPLE_SYSTEMS_MANAGER_SSM_TOKEN

const BASE_URL = "http://ssm.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_SIMPLE_SYSTEMS_MANAGER_SSM_TOKEN | default "" }
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

def base-url-completer [] { ["http://ssm.us-east-1.amazonaws.com" "http://ssm.us-east-2.amazonaws.com" "http://ssm.us-west-1.amazonaws.com" "http://ssm.us-west-2.amazonaws.com" "http://ssm.us-gov-west-1.amazonaws.com" "http://ssm.us-gov-east-1.amazonaws.com" "http://ssm.ca-central-1.amazonaws.com" "http://ssm.eu-north-1.amazonaws.com" "http://ssm.eu-west-1.amazonaws.com" "http://ssm.eu-west-2.amazonaws.com" "http://ssm.eu-west-3.amazonaws.com" "http://ssm.eu-central-1.amazonaws.com" "http://ssm.eu-south-1.amazonaws.com" "http://ssm.af-south-1.amazonaws.com" "http://ssm.ap-northeast-1.amazonaws.com" "http://ssm.ap-northeast-2.amazonaws.com" "http://ssm.ap-northeast-3.amazonaws.com" "http://ssm.ap-southeast-1.amazonaws.com" "http://ssm.ap-southeast-2.amazonaws.com" "http://ssm.ap-east-1.amazonaws.com" "http://ssm.ap-south-1.amazonaws.com" "http://ssm.sa-east-1.amazonaws.com" "http://ssm.me-south-1.amazonaws.com" "https://ssm.us-east-1.amazonaws.com" "https://ssm.us-east-2.amazonaws.com" "https://ssm.us-west-1.amazonaws.com" "https://ssm.us-west-2.amazonaws.com" "https://ssm.us-gov-west-1.amazonaws.com" "https://ssm.us-gov-east-1.amazonaws.com" "https://ssm.ca-central-1.amazonaws.com" "https://ssm.eu-north-1.amazonaws.com" "https://ssm.eu-west-1.amazonaws.com" "https://ssm.eu-west-2.amazonaws.com" "https://ssm.eu-west-3.amazonaws.com" "https://ssm.eu-central-1.amazonaws.com" "https://ssm.eu-south-1.amazonaws.com" "https://ssm.af-south-1.amazonaws.com" "https://ssm.ap-northeast-1.amazonaws.com" "https://ssm.ap-northeast-2.amazonaws.com" "https://ssm.ap-northeast-3.amazonaws.com" "https://ssm.ap-southeast-1.amazonaws.com" "https://ssm.ap-southeast-2.amazonaws.com" "https://ssm.ap-east-1.amazonaws.com" "https://ssm.ap-south-1.amazonaws.com" "https://ssm.sa-east-1.amazonaws.com" "https://ssm.me-south-1.amazonaws.com" "http://ssm.cn-north-1.amazonaws.com.cn" "http://ssm.cn-northwest-1.amazonaws.com.cn" "https://ssm.cn-north-1.amazonaws.com.cn" "https://ssm.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def resource-type-completer [] { ["Association" "Automation" "Document" "MaintenanceWindow" "ManagedInstance" "OpsItem" "OpsMetadata" "Parameter" "PatchBaseline"] }
def x-amz-target-completer [] { ["AmazonSSM.AddTagsToResource"] }
def x-amz-target-completer-1 [] { ["AmazonSSM.AssociateOpsItemRelatedItem"] }
def x-amz-target-completer-2 [] { ["AmazonSSM.CancelCommand"] }
def x-amz-target-completer-3 [] { ["AmazonSSM.CancelMaintenanceWindowExecution"] }
def x-amz-target-completer-4 [] { ["AmazonSSM.CreateActivation"] }
def compliance-severity-completer [] { ["CRITICAL" "HIGH" "LOW" "MEDIUM" "UNSPECIFIED"] }
def sync-compliance-completer [] { ["AUTO" "MANUAL"] }
def x-amz-target-completer-5 [] { ["AmazonSSM.CreateAssociation"] }
def x-amz-target-completer-6 [] { ["AmazonSSM.CreateAssociationBatch"] }
def document-type-completer [] { ["ApplicationConfiguration" "ApplicationConfigurationSchema" "Automation" "Automation.ChangeTemplate" "ChangeCalendar" "CloudFormation" "Command" "ConformancePackTemplate" "DeploymentStrategy" "Package" "Policy" "ProblemAnalysis" "ProblemAnalysisTemplate" "QuickSetup" "Session"] }
def document-format-completer [] { ["JSON" "TEXT" "YAML"] }
def x-amz-target-completer-7 [] { ["AmazonSSM.CreateDocument"] }
def x-amz-target-completer-8 [] { ["AmazonSSM.CreateMaintenanceWindow"] }
def x-amz-target-completer-9 [] { ["AmazonSSM.CreateOpsItem"] }
def x-amz-target-completer-10 [] { ["AmazonSSM.CreateOpsMetadata"] }
def operating-system-completer [] { ["ALMA_LINUX" "AMAZON_LINUX" "AMAZON_LINUX_2" "AMAZON_LINUX_2022" "AMAZON_LINUX_2023" "CENTOS" "DEBIAN" "MACOS" "ORACLE_LINUX" "RASPBIAN" "REDHAT_ENTERPRISE_LINUX" "ROCKY_LINUX" "SUSE" "UBUNTU" "WINDOWS"] }
def approved-patches-compliance-level-completer [] { ["CRITICAL" "HIGH" "INFORMATIONAL" "LOW" "MEDIUM" "UNSPECIFIED"] }
def rejected-patches-action-completer [] { ["ALLOW_AS_DEPENDENCY" "BLOCK"] }
def x-amz-target-completer-11 [] { ["AmazonSSM.CreatePatchBaseline"] }
def x-amz-target-completer-12 [] { ["AmazonSSM.CreateResourceDataSync"] }
def x-amz-target-completer-13 [] { ["AmazonSSM.DeleteActivation"] }
def x-amz-target-completer-14 [] { ["AmazonSSM.DeleteAssociation"] }
def x-amz-target-completer-15 [] { ["AmazonSSM.DeleteDocument"] }
def schema-delete-option-completer [] { ["DeleteSchema" "DisableSchema"] }
def x-amz-target-completer-16 [] { ["AmazonSSM.DeleteInventory"] }
def x-amz-target-completer-17 [] { ["AmazonSSM.DeleteMaintenanceWindow"] }
def x-amz-target-completer-18 [] { ["AmazonSSM.DeleteOpsMetadata"] }
def x-amz-target-completer-19 [] { ["AmazonSSM.DeleteParameter"] }
def x-amz-target-completer-20 [] { ["AmazonSSM.DeleteParameters"] }
def x-amz-target-completer-21 [] { ["AmazonSSM.DeletePatchBaseline"] }
def x-amz-target-completer-22 [] { ["AmazonSSM.DeleteResourceDataSync"] }
def x-amz-target-completer-23 [] { ["AmazonSSM.DeleteResourcePolicy"] }
def x-amz-target-completer-24 [] { ["AmazonSSM.DeregisterManagedInstance"] }
def x-amz-target-completer-25 [] { ["AmazonSSM.DeregisterPatchBaselineForPatchGroup"] }
def x-amz-target-completer-26 [] { ["AmazonSSM.DeregisterTargetFromMaintenanceWindow"] }
def x-amz-target-completer-27 [] { ["AmazonSSM.DeregisterTaskFromMaintenanceWindow"] }
def x-amz-target-completer-28 [] { ["AmazonSSM.DescribeActivations"] }
def x-amz-target-completer-29 [] { ["AmazonSSM.DescribeAssociation"] }
def x-amz-target-completer-30 [] { ["AmazonSSM.DescribeAssociationExecutionTargets"] }
def x-amz-target-completer-31 [] { ["AmazonSSM.DescribeAssociationExecutions"] }
def x-amz-target-completer-32 [] { ["AmazonSSM.DescribeAutomationExecutions"] }
def x-amz-target-completer-33 [] { ["AmazonSSM.DescribeAutomationStepExecutions"] }
def x-amz-target-completer-34 [] { ["AmazonSSM.DescribeAvailablePatches"] }
def x-amz-target-completer-35 [] { ["AmazonSSM.DescribeDocument"] }
def permission-type-completer [] { ["Share"] }
def x-amz-target-completer-36 [] { ["AmazonSSM.DescribeDocumentPermission"] }
def x-amz-target-completer-37 [] { ["AmazonSSM.DescribeEffectiveInstanceAssociations"] }
def x-amz-target-completer-38 [] { ["AmazonSSM.DescribeEffectivePatchesForPatchBaseline"] }
def x-amz-target-completer-39 [] { ["AmazonSSM.DescribeInstanceAssociationsStatus"] }
def x-amz-target-completer-40 [] { ["AmazonSSM.DescribeInstanceInformation"] }
def x-amz-target-completer-41 [] { ["AmazonSSM.DescribeInstancePatchStates"] }
def x-amz-target-completer-42 [] { ["AmazonSSM.DescribeInstancePatchStatesForPatchGroup"] }
def x-amz-target-completer-43 [] { ["AmazonSSM.DescribeInstancePatches"] }
def x-amz-target-completer-44 [] { ["AmazonSSM.DescribeInventoryDeletions"] }
def x-amz-target-completer-45 [] { ["AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"] }
def x-amz-target-completer-46 [] { ["AmazonSSM.DescribeMaintenanceWindowExecutionTasks"] }
def x-amz-target-completer-47 [] { ["AmazonSSM.DescribeMaintenanceWindowExecutions"] }
def resource-type-completer-1 [] { ["INSTANCE" "RESOURCE_GROUP"] }
def x-amz-target-completer-48 [] { ["AmazonSSM.DescribeMaintenanceWindowSchedule"] }
def x-amz-target-completer-49 [] { ["AmazonSSM.DescribeMaintenanceWindowTargets"] }
def x-amz-target-completer-50 [] { ["AmazonSSM.DescribeMaintenanceWindowTasks"] }
def x-amz-target-completer-51 [] { ["AmazonSSM.DescribeMaintenanceWindows"] }
def x-amz-target-completer-52 [] { ["AmazonSSM.DescribeMaintenanceWindowsForTarget"] }
def x-amz-target-completer-53 [] { ["AmazonSSM.DescribeOpsItems"] }
def x-amz-target-completer-54 [] { ["AmazonSSM.DescribeParameters"] }
def x-amz-target-completer-55 [] { ["AmazonSSM.DescribePatchBaselines"] }
def x-amz-target-completer-56 [] { ["AmazonSSM.DescribePatchGroupState"] }
def x-amz-target-completer-57 [] { ["AmazonSSM.DescribePatchGroups"] }
def property-completer [] { ["CLASSIFICATION" "MSRC_SEVERITY" "PRIORITY" "PRODUCT" "PRODUCT_FAMILY" "SEVERITY"] }
def patch-set-completer [] { ["APPLICATION" "OS"] }
def x-amz-target-completer-58 [] { ["AmazonSSM.DescribePatchProperties"] }
def state-completer [] { ["Active" "History"] }
def x-amz-target-completer-59 [] { ["AmazonSSM.DescribeSessions"] }
def x-amz-target-completer-60 [] { ["AmazonSSM.DisassociateOpsItemRelatedItem"] }
def x-amz-target-completer-61 [] { ["AmazonSSM.GetAutomationExecution"] }
def x-amz-target-completer-62 [] { ["AmazonSSM.GetCalendarState"] }
def x-amz-target-completer-63 [] { ["AmazonSSM.GetCommandInvocation"] }
def x-amz-target-completer-64 [] { ["AmazonSSM.GetConnectionStatus"] }
def x-amz-target-completer-65 [] { ["AmazonSSM.GetDefaultPatchBaseline"] }
def x-amz-target-completer-66 [] { ["AmazonSSM.GetDeployablePatchSnapshotForInstance"] }
def x-amz-target-completer-67 [] { ["AmazonSSM.GetDocument"] }
def x-amz-target-completer-68 [] { ["AmazonSSM.GetInventory"] }
def x-amz-target-completer-69 [] { ["AmazonSSM.GetInventorySchema"] }
def x-amz-target-completer-70 [] { ["AmazonSSM.GetMaintenanceWindow"] }
def x-amz-target-completer-71 [] { ["AmazonSSM.GetMaintenanceWindowExecution"] }
def x-amz-target-completer-72 [] { ["AmazonSSM.GetMaintenanceWindowExecutionTask"] }
def x-amz-target-completer-73 [] { ["AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"] }
def x-amz-target-completer-74 [] { ["AmazonSSM.GetMaintenanceWindowTask"] }
def x-amz-target-completer-75 [] { ["AmazonSSM.GetOpsItem"] }
def x-amz-target-completer-76 [] { ["AmazonSSM.GetOpsMetadata"] }
def x-amz-target-completer-77 [] { ["AmazonSSM.GetOpsSummary"] }
def x-amz-target-completer-78 [] { ["AmazonSSM.GetParameter"] }
def x-amz-target-completer-79 [] { ["AmazonSSM.GetParameterHistory"] }
def x-amz-target-completer-80 [] { ["AmazonSSM.GetParameters"] }
def x-amz-target-completer-81 [] { ["AmazonSSM.GetParametersByPath"] }
def x-amz-target-completer-82 [] { ["AmazonSSM.GetPatchBaseline"] }
def x-amz-target-completer-83 [] { ["AmazonSSM.GetPatchBaselineForPatchGroup"] }
def x-amz-target-completer-84 [] { ["AmazonSSM.GetResourcePolicies"] }
def x-amz-target-completer-85 [] { ["AmazonSSM.GetServiceSetting"] }
def x-amz-target-completer-86 [] { ["AmazonSSM.LabelParameterVersion"] }
def x-amz-target-completer-87 [] { ["AmazonSSM.ListAssociationVersions"] }
def x-amz-target-completer-88 [] { ["AmazonSSM.ListAssociations"] }
def x-amz-target-completer-89 [] { ["AmazonSSM.ListCommandInvocations"] }
def x-amz-target-completer-90 [] { ["AmazonSSM.ListCommands"] }
def x-amz-target-completer-91 [] { ["AmazonSSM.ListComplianceItems"] }
def x-amz-target-completer-92 [] { ["AmazonSSM.ListComplianceSummaries"] }
def metadata-completer [] { ["DocumentReviews"] }
def x-amz-target-completer-93 [] { ["AmazonSSM.ListDocumentMetadataHistory"] }
def x-amz-target-completer-94 [] { ["AmazonSSM.ListDocumentVersions"] }
def x-amz-target-completer-95 [] { ["AmazonSSM.ListDocuments"] }
def x-amz-target-completer-96 [] { ["AmazonSSM.ListInventoryEntries"] }
def x-amz-target-completer-97 [] { ["AmazonSSM.ListOpsItemEvents"] }
def x-amz-target-completer-98 [] { ["AmazonSSM.ListOpsItemRelatedItems"] }
def x-amz-target-completer-99 [] { ["AmazonSSM.ListOpsMetadata"] }
def x-amz-target-completer-100 [] { ["AmazonSSM.ListResourceComplianceSummaries"] }
def x-amz-target-completer-101 [] { ["AmazonSSM.ListResourceDataSync"] }
def x-amz-target-completer-102 [] { ["AmazonSSM.ListTagsForResource"] }
def x-amz-target-completer-103 [] { ["AmazonSSM.ModifyDocumentPermission"] }
def upload-type-completer [] { ["COMPLETE" "PARTIAL"] }
def x-amz-target-completer-104 [] { ["AmazonSSM.PutComplianceItems"] }
def x-amz-target-completer-105 [] { ["AmazonSSM.PutInventory"] }
def type-completer [] { ["SecureString" "String" "StringList"] }
def tier-completer [] { ["Advanced" "Intelligent-Tiering" "Standard"] }
def x-amz-target-completer-106 [] { ["AmazonSSM.PutParameter"] }
def x-amz-target-completer-107 [] { ["AmazonSSM.PutResourcePolicy"] }
def x-amz-target-completer-108 [] { ["AmazonSSM.RegisterDefaultPatchBaseline"] }
def x-amz-target-completer-109 [] { ["AmazonSSM.RegisterPatchBaselineForPatchGroup"] }
def x-amz-target-completer-110 [] { ["AmazonSSM.RegisterTargetWithMaintenanceWindow"] }
def task-type-completer [] { ["AUTOMATION" "LAMBDA" "RUN_COMMAND" "STEP_FUNCTIONS"] }
def cutoff-behavior-completer [] { ["CANCEL_TASK" "CONTINUE_TASK"] }
def x-amz-target-completer-111 [] { ["AmazonSSM.RegisterTaskWithMaintenanceWindow"] }
def x-amz-target-completer-112 [] { ["AmazonSSM.RemoveTagsFromResource"] }
def x-amz-target-completer-113 [] { ["AmazonSSM.ResetServiceSetting"] }
def x-amz-target-completer-114 [] { ["AmazonSSM.ResumeSession"] }
def signal-type-completer [] { ["Approve" "Reject" "Resume" "StartStep" "StopStep"] }
def x-amz-target-completer-115 [] { ["AmazonSSM.SendAutomationSignal"] }
def document-hash-type-completer [] { ["Sha1" "Sha256"] }
def x-amz-target-completer-116 [] { ["AmazonSSM.SendCommand"] }
def x-amz-target-completer-117 [] { ["AmazonSSM.StartAssociationsOnce"] }
def mode-completer [] { ["Auto" "Interactive"] }
def x-amz-target-completer-118 [] { ["AmazonSSM.StartAutomationExecution"] }
def x-amz-target-completer-119 [] { ["AmazonSSM.StartChangeRequestExecution"] }
def x-amz-target-completer-120 [] { ["AmazonSSM.StartSession"] }
def type-completer-1 [] { ["Cancel" "Complete"] }
def x-amz-target-completer-121 [] { ["AmazonSSM.StopAutomationExecution"] }
def x-amz-target-completer-122 [] { ["AmazonSSM.TerminateSession"] }
def x-amz-target-completer-123 [] { ["AmazonSSM.UnlabelParameterVersion"] }
def x-amz-target-completer-124 [] { ["AmazonSSM.UpdateAssociation"] }
def x-amz-target-completer-125 [] { ["AmazonSSM.UpdateAssociationStatus"] }
def x-amz-target-completer-126 [] { ["AmazonSSM.UpdateDocument"] }
def x-amz-target-completer-127 [] { ["AmazonSSM.UpdateDocumentDefaultVersion"] }
def x-amz-target-completer-128 [] { ["AmazonSSM.UpdateDocumentMetadata"] }
def x-amz-target-completer-129 [] { ["AmazonSSM.UpdateMaintenanceWindow"] }
def x-amz-target-completer-130 [] { ["AmazonSSM.UpdateMaintenanceWindowTarget"] }
def x-amz-target-completer-131 [] { ["AmazonSSM.UpdateMaintenanceWindowTask"] }
def x-amz-target-completer-132 [] { ["AmazonSSM.UpdateManagedInstanceRole"] }
def status-completer [] { ["Approved" "Cancelled" "Cancelling" "ChangeCalendarOverrideApproved" "ChangeCalendarOverrideRejected" "Closed" "CompletedWithFailure" "CompletedWithSuccess" "Failed" "InProgress" "Open" "Pending" "PendingApproval" "PendingChangeCalendarOverride" "Rejected" "Resolved" "RunbookInProgress" "Scheduled" "TimedOut"] }
def x-amz-target-completer-133 [] { ["AmazonSSM.UpdateOpsItem"] }
def x-amz-target-completer-134 [] { ["AmazonSSM.UpdateOpsMetadata"] }
def x-amz-target-completer-135 [] { ["AmazonSSM.UpdatePatchBaseline"] }
def x-amz-target-completer-136 [] { ["AmazonSSM.UpdateResourceDataSync"] }
def x-amz-target-completer-137 [] { ["AmazonSSM.UpdateServiceSetting"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["add-tags-to-resource" "associate-ops-item-related-item" "cancel-command" "cancel-maintenance-window-execution" "create-activation" "create-association" "create-association-batch" "create-document" "create-maintenance-window" "create-ops-item" "create-ops-metadata" "create-patch-baseline" "create-resource-data-sync" "delete-activation" "delete-association" "delete-document" "delete-inventory" "delete-maintenance-window" "delete-ops-metadata" "delete-parameter" "delete-parameters" "delete-patch-baseline" "delete-resource-data-sync" "delete-resource-policy" "deregister-managed-instance" "deregister-patch-baseline-for-patch-group" "deregister-target-from-maintenance-window" "deregister-task-from-maintenance-window" "describe-activations" "describe-association" "describe-association-execution-targets" "describe-association-executions" "describe-automation-executions" "describe-automation-step-executions" "describe-available-patches" "describe-document" "describe-document-permission" "describe-effective-instance-associations" "describe-effective-patches-for-patch-baseline" "describe-instance-associations-status" "describe-instance-information" "describe-instance-patch-states" "describe-instance-patch-states-for-patch-group" "describe-instance-patches" "describe-inventory-deletions" "describe-maintenance-window-execution-task-invocations" "describe-maintenance-window-execution-tasks" "describe-maintenance-window-executions" "describe-maintenance-window-schedule" "describe-maintenance-window-targets" "describe-maintenance-window-tasks" "describe-maintenance-windows" "describe-maintenance-windows-for-target" "describe-ops-items" "describe-parameters" "describe-patch-baselines" "describe-patch-group-state" "describe-patch-groups" "describe-patch-properties" "describe-sessions" "disassociate-ops-item-related-item" "get-automation-execution" "get-calendar-state" "get-command-invocation" "get-connection-status" "get-default-patch-baseline" "get-deployable-patch-snapshot-for-instance" "get-document" "get-inventory" "get-inventory-schema" "get-maintenance-window" "get-maintenance-window-execution" "get-maintenance-window-execution-task" "get-maintenance-window-execution-task-invocation" "get-maintenance-window-task" "get-ops-item" "get-ops-metadata" "get-ops-summary" "get-parameter" "get-parameter-history" "get-parameters" "get-parameters-by-path" "get-patch-baseline" "get-patch-baseline-for-patch-group" "get-resource-policies" "get-service-setting" "label-parameter-version" "list-association-versions" "list-associations" "list-command-invocations" "list-commands" "list-compliance-items" "list-compliance-summaries" "list-document-metadata-history" "list-document-versions" "list-documents" "list-inventory-entries" "list-ops-item-events" "list-ops-item-related-items" "list-ops-metadata" "list-resource-compliance-summaries" "list-resource-data-sync" "list-tags-for-resource" "modify-document-permission" "put-compliance-items" "put-inventory" "put-parameter" "put-resource-policy" "register-default-patch-baseline" "register-patch-baseline-for-patch-group" "register-target-with-maintenance-window" "register-task-with-maintenance-window" "remove-tags-from-resource" "reset-service-setting" "resume-session" "send-automation-signal" "send-command" "start-associations-once" "start-automation-execution" "start-change-request-execution" "start-session" "stop-automation-execution" "terminate-session" "unlabel-parameter-version" "update-association" "update-association-status" "update-document" "update-document-default-version" "update-document-metadata" "update-maintenance-window" "update-maintenance-window-target" "update-maintenance-window-task" "update-managed-instance-role" "update-ops-item" "update-ops-metadata" "update-patch-baseline" "update-resource-data-sync" "update-service-setting" "commands"] | sort) } | get name | first)
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

# Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your automations, documents, managed nodes, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed nodes that helps you track each node's owner and stack level. For example: Key=Owner,Value=DbAdmin Key=Owner,Value=SysAdmin Key=Owner,Value=Dev Key=Stack,Value=Production Key=Stack,Value=Pre-Production Key=Stack,Value=Test Most resources can have a maximum of 50 tags. Automations can have a maximum of 5 tags. We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to and are interpreted strictly as a string of characters. For more information about using tags with Amazon Elastic Compute Cloud (Amazon EC2) instances, see Tagging your Amazon EC2 resources (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html) in the Amazon EC2 User Guide.
#
# POST /
# operationId: AddTagsToResource
export def "add-tags-to-resource" [
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
  resource_type: string@resource-type-completer # Specifies the type of resource you are tagging. The ManagedInstance type for this API operation is for on-premises managed nodes. You must specify the name of the managed node in the following format: mi-ID_number . For example, mi-1a2b3c4d5e6f.
  resource_id: string # The resource ID you want to tag. Use the ID of the resource. Here are some examples: MaintenanceWindow: mw-012345abcde PatchBaseline: pb-012345abcde Automation: example-c160-4567-8519-012345abcde OpsMetadata object: ResourceID for tagging is created from the Amazon Resource Name (ARN) for the object. Specifically, ResourceID is created from the strings that come after the word opsmetadata in the ARN. For example, an OpsMetadata object with an ARN of arn:aws:ssm:us-east-2:1234567890:opsmetadata/aws/ssm/MyGroup/appmanager has a ResourceID of either aws/ssm/MyGroup/appmanager or /aws/ssm/MyGroup/appmanager. For the Document and Parameter values, use the name of the resource. ManagedInstance: mi-012345abcde The ManagedInstance type for this API operation is only for on-premises managed nodes. You must specify the name of the managed node in the following format: mi-ID_number . For example, mi-1a2b3c4d5e6f.
  tags: list # One or more tags. The value parameter is required. Don't enter personally identifiable information in this field. — item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.AddTagsToResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceType": $resource_type, "ResourceId": $resource_id, "Tags": $tags} | compact
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

# Associates a related item to a Systems Manager OpsCenter OpsItem. For example, you can associate an Incident Manager incident or analysis with an OpsItem. Incident Manager and OpsCenter are capabilities of Amazon Web Services Systems Manager.
#
# POST /
# operationId: AssociateOpsItemRelatedItem
export def "associate-ops-item-related-item" [
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
  ops_item_id: string # The ID of the OpsItem to which you want to associate a resource as a related item.
  association_type: string # The type of association that you want to create between an OpsItem and a resource. OpsCenter supports IsParentOf and RelatesTo association types.
  resource_type: string # The type of resource that you want to associate with an OpsItem. OpsCenter supports the following types: AWS::SSMIncidents::IncidentRecord: an Incident Manager incident. AWS::SSM::Document: a Systems Manager (SSM) document.
  resource_uri: string # The Amazon Resource Name (ARN) of the Amazon Web Services resource that you want to associate with the OpsItem.
]: any -> oneof<record<AssociationId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.AssociateOpsItemRelatedItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OpsItemId": $ops_item_id, "AssociationType": $association_type, "ResourceType": $resource_type, "ResourceUri": $resource_uri} | compact
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

# Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
#
# POST /
# operationId: CancelCommand
export def "cancel-command" [
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
  command_id: string # The ID of the command you want to cancel.
  --instance-ids: list<string> # (Optional) A list of managed node IDs on which you want to cancel the command. If not provided, the command is canceled on every node on which it was requested.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CancelCommand")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CommandId": $command_id, "InstanceIds": $instance_ids} | compact
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

# Stops a maintenance window execution that is already in progress and cancels any tasks in the window that haven't already starting running. Tasks already in progress will continue to completion.
#
# POST /
# operationId: CancelMaintenanceWindowExecution
export def "cancel-maintenance-window-execution" [
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
  window_execution_id: string # The ID of the maintenance window execution to stop.
]: any -> oneof<record<WindowExecutionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CancelMaintenanceWindowExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowExecutionId": $window_execution_id} | compact
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

# Generates an activation code and activation ID you can use to register your on-premises servers, edge devices, or virtual machine (VM) with Amazon Web Services Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises machines using Systems Manager, see Setting up Amazon Web Services Systems Manager for hybrid environments (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html) in the Amazon Web Services Systems Manager User Guide. Amazon Elastic Compute Cloud (Amazon EC2) instances, edge devices, and on-premises servers and VMs that are configured for Systems Manager are all called managed nodes.
#
# POST /
# operationId: CreateActivation
export def "create-activation" [
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
  --description: string # A user-defined description of the resource that you want to register with Systems Manager. Don't enter personally identifiable information in this field.
  --default-instance-name: string # The name of the registered, managed node as it will appear in the Amazon Web Services Systems Manager console or when you use the Amazon Web Services command line tools to list Systems Manager resources. Don't enter personally identifiable information in this field.
  iam_role: string # The name of the Identity and Access Management (IAM) role that you want to assign to the managed node. This IAM role must provide AssumeRole permissions for the Amazon Web Services Systems Manager service principal ssm.amazonaws.com. For more information, see Create an IAM service role for a hybrid environment (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-service-role.html) in the Amazon Web Services Systems Manager User Guide. You can't specify an IAM service-linked role for this parameter. You must create a unique role.
  --registration-limit: int # Specify the maximum number of managed nodes you want to register. The default value is 1.
  --expiration-date: string # The date by which this activation request should expire, in timestamp format, such as "2021-07-07T00:00:00". You can specify a date up to 30 days in advance. If you don't provide an expiration date, the activation code expires in 24 hours. (format: date-time)
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag an activation to identify which servers or virtual machines (VMs) in your on-premises environment you intend to activate. In this case, you could specify the following key-value pairs: Key=OS,Value=Windows Key=Environment,Value=Production When you install SSM Agent on your on-premises servers and VMs, you specify an activation ID and code. When you specify the activation ID and code, tags assigned to the activation are automatically applied to the on-premises servers or VMs. You can't add tags to or delete tags from an existing activation. You can tag your on-premises servers, edge devices, and VMs after they connect to Systems Manager for the first time and are assigned a managed node ID. This means they are listed in the Amazon Web Services Systems Manager console with an ID that is prefixed with "mi-". For information about how to add tags to your managed nodes, see AddTagsToResource. For information about how to remove tags from your managed nodes, see RemoveTagsFromResource. — item shape: {Key: string, Value: string}
  --registration-metadata: list # Reserved for internal use. — item shape: {Key: string, Value: string}
]: any -> oneof<record<ActivationId: string, ActivationCode: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreateActivation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Description": $description, "DefaultInstanceName": $default_instance_name, "IamRole": $iam_role, "RegistrationLimit": $registration_limit, "ExpirationDate": $expiration_date, "Tags": $tags, "RegistrationMetadata": $registration_metadata} | compact
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

# A State Manager association defines the state that you want to maintain on your managed nodes. For example, an association can specify that anti-virus software must be installed and running on your managed nodes, or that certain ports must be closed. For static targets, the association specifies a schedule for when the configuration is reapplied. For dynamic targets, such as an Amazon Web Services resource group or an Amazon Web Services autoscaling group, State Manager, a capability of Amazon Web Services Systems Manager applies the configuration when new managed nodes are added to the group. The association also specifies actions to take when applying the configuration. For example, an association for anti-virus software might run once a day. If the software isn't installed, then State Manager installs it. If the software is installed, but the service isn't running, then the association might instruct State Manager to start the service.
#
# POST /
# operationId: CreateAssociation
export def "create-association" [
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
  name: string # The name of the SSM Command document or Automation runbook that contains the configuration information for the managed node. You can specify Amazon Web Services-predefined documents, documents you created, or a document that is shared with you from another Amazon Web Services account. For Systems Manager documents (SSM documents) that are shared with you from other Amazon Web Services accounts, you must specify the complete SSM document ARN, in the following format: arn:partition:ssm:region:account-id:document/document-name For example: arn:aws:ssm:us-east-2:12345678912:document/My-Shared-Document For Amazon Web Services-predefined documents and SSM documents you created in your account, you only need to specify the document name. For example, AWS-ApplyPatchBaseline or My-Document.
  --document-version: string # The document version you want to associate with the target(s). Can be a specific version or the default version. State Manager doesn't support running associations that use a new version of a document if that document is shared from another account. State Manager always runs the default version of a document if shared from another account, even though the Systems Manager console shows that a new version was processed. If you want to run an association using a new version of a document shared form another account, you must set the document version to default.
  --instance-id: string # The managed node ID. InstanceId has been deprecated. To specify a managed node ID for an association, use the Targets parameter. Requests that include the parameter InstanceID with Systems Manager documents (SSM documents) that use schema version 2.0 or later will fail. In addition, if you use the parameter InstanceId, you can't use the parameters AssociationName, DocumentVersion, MaxErrors, MaxConcurrency, OutputLocation, or ScheduleExpression. To use these parameters, you must use the Targets parameter.
  --parameters: record # The parameters for the runtime configuration of the document.
  --targets: list # The targets for the association. You can target managed nodes by using tags, Amazon Web Services resource groups, all managed nodes in an Amazon Web Services account, or individual managed node IDs. You can target all managed nodes in an Amazon Web Services account by specifying the InstanceIds key with a value of *. For more information about choosing targets for an association, see Using targets and rate controls with State Manager associations (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-state-manager-targets-and-rate-controls.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Key?: string, Values?: list<string>}
  --schedule-expression: string # A cron expression when the association will be applied to the target(s).
  --output-location: record # An S3 bucket where you want to store the results of this request. For the minimal permissions required to enable Amazon S3 output for an association, see Creating associations (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-state-assoc.html) in the Systems Manager User Guide. — shape: {S3Location?: record}
  --association-name: string # Specify a descriptive name for the association.
  --automation-target-parameter-name: string # Choose the parameter that will define how your automation will branch out. This target is required for associations that use an Automation runbook and target resources by using rate controls. Automation is a capability of Amazon Web Services Systems Manager.
  --max-errors: string # The number of errors that are allowed before the system stops sending requests to run the association on additional targets. You can specify either an absolute number of errors, for example 10, or a percentage of the target set, for example 10%. If you specify 3, for example, the system stops sending requests when the fourth error is received. If you specify 0, then the system stops sending requests after the first error is returned. If you run an association on 50 managed nodes and set MaxError to 10%, then the system stops sending the request when the sixth error is received. Executions that are already running an association when MaxErrors is reached are allowed to complete, but some of these executions may fail as well. If you need to ensure that there won't be more than max-errors failed executions, set MaxConcurrency to 1 so that executions proceed one at a time.
  --max-concurrency: string # The maximum number of targets allowed to run the association at the same time. You can specify a number, for example 10, or a percentage of the target set, for example 10%. The default value is 100%, which means all targets run the association at the same time. If a new managed node starts and attempts to run an association while Systems Manager is running MaxConcurrency associations, the association is allowed to run. During the next association interval, the new managed node will process its association within the limit specified for MaxConcurrency.
  --compliance-severity: string@compliance-severity-completer # The severity level to assign to the association.
  --sync-compliance: string@sync-compliance-completer # The mode for generating association compliance. You can specify AUTO or MANUAL. In AUTO mode, the system uses the status of the association execution to determine the compliance status. If the association execution runs successfully, then the association is COMPLIANT. If the association execution doesn't run successfully, the association is NON-COMPLIANT. In MANUAL mode, you must specify the AssociationId as a parameter for the PutComplianceItems API operation. In this case, compliance data isn't managed by State Manager. It is managed by your direct call to the PutComplianceItems API operation. By default, all associations use AUTO mode.
  --apply-only-at-cron-interval: oneof<nothing, bool> # By default, when you create a new association, the system runs it immediately after it is created and then according to the schedule you specified. Specify this option if you don't want an association to run immediately after you create it. This parameter isn't supported for rate expressions.
  --calendar-names: list<string> # The names or Amazon Resource Names (ARNs) of the Change Calendar type documents you want to gate your associations under. The associations only run when that change calendar is open. For more information, see Amazon Web Services Systems Manager Change Calendar (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar).
  --target-locations: list # A location is a combination of Amazon Web Services Regions and Amazon Web Services accounts where you want to run the association. Use this action to create an association in multiple Regions and multiple accounts. — item shape: {Accounts?: list<string>, Regions?: list<string>, TargetLocationMaxConcurrency?: string, TargetLocationMaxErrors?: string, ExecutionRoleName?: string, TargetLocationAlarmConfiguration?: record}
  --schedule-offset: int # Number of days to wait after the scheduled day to run an association. For example, if you specified a cron schedule of cron(0 0 ? * THU#2 *), you could specify an offset of 3 to run the association each Sunday after the second Thursday of the month. For more information about cron schedules for associations, see Reference: Cron and rate expressions for Systems Manager (https://docs.aws.amazon.com/systems-manager/latest/userguide/reference-cron-and-rate-expressions.html) in the Amazon Web Services Systems Manager User Guide. To use offsets, you must specify the ApplyOnlyAtCronInterval parameter. This option tells the system not to run an association immediately after you create it.
  --target-maps: list # A key-value mapping of document parameters to target resources. Both Targets and TargetMaps can't be specified together.
  --tags: list # Adds or overwrites one or more tags for a State Manager association. Tags are metadata that you can assign to your Amazon Web Services resources. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. — item shape: {Key: string, Value: string}
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreateAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "DocumentVersion": $document_version, "InstanceId": $instance_id, "Parameters": $parameters, "Targets": $targets, "ScheduleExpression": $schedule_expression, "OutputLocation": $output_location, "AssociationName": $association_name, "AutomationTargetParameterName": $automation_target_parameter_name, "MaxErrors": $max_errors, "MaxConcurrency": $max_concurrency, "ComplianceSeverity": $compliance_severity, "SyncCompliance": $sync_compliance, "ApplyOnlyAtCronInterval": $apply_only_at_cron_interval, "CalendarNames": $calendar_names, "TargetLocations": $target_locations, "ScheduleOffset": $schedule_offset, "TargetMaps": $target_maps, "Tags": $tags, "AlarmConfiguration": $alarm_configuration} | compact
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

# Associates the specified Amazon Web Services Systems Manager document (SSM document) with the specified managed nodes or targets. When you associate a document with one or more managed nodes using IDs or tags, Amazon Web Services Systems Manager Agent (SSM Agent) running on the managed node processes the document and configures the node as specified. If you associate a document with a managed node that already has an associated document, the system returns the AssociationAlreadyExists exception.
#
# POST /
# operationId: CreateAssociationBatch
export def "create-association-batch" [
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
  entries: list # One or more associations. — item shape: {Name: string, InstanceId?: string, Parameters?: record, AutomationTargetParameterName?: string, DocumentVersion?: string, Targets?: list, ScheduleExpression?: string, OutputLocation?: record, AssociationName?: string, MaxErrors?: string, MaxConcurrency?: string, ComplianceSeverity?: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW"|"UNSPECIFIED", SyncCompliance?: "AUTO"|"MANUAL", ApplyOnlyAtCronInterval?: bool, CalendarNames?: list<string>, TargetLocations?: list, ScheduleOffset?: int, TargetMaps?: list, ... (1 more fields)}
]: any -> oneof<record<Successful: table<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record, Overview: record, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list, ScheduleExpression: string, OutputLocation: record, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list, TargetLocations: list, ScheduleOffset: int, TargetMaps: list, AlarmConfiguration: record, TriggeredAlarms: list>, Failed: table<Entry: record, Message: string, Fault: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreateAssociationBatch")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Entries": $entries} | compact
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

# Creates a Amazon Web Services Systems Manager (SSM document). An SSM document defines the actions that Systems Manager performs on your managed nodes. For more information about SSM documents, including information about supported schemas, features, and syntax, see Amazon Web Services Systems Manager Documents (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-ssm-docs.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# operationId: CreateDocument
export def "create-document" [
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
  content: string # The content for the new SSM document in JSON or YAML format. The content of the document must not exceed 64KB. This quota also includes the content specified for input parameters at runtime. We recommend storing the contents for your new document in an external JSON or YAML file and referencing the file in a command. For examples, see the following topics in the Amazon Web Services Systems Manager User Guide. Create an SSM document (Amazon Web Services API) (https://docs.aws.amazon.com/systems-manager/latest/userguide/create-ssm-document-api.html) Create an SSM document (Amazon Web Services CLI) (https://docs.aws.amazon.com/systems-manager/latest/userguide/create-ssm-document-cli.html) Create an SSM document (API) (https://docs.aws.amazon.com/systems-manager/latest/userguide/create-ssm-document-api.html)
  --requires: list # A list of SSM documents required by a document. This parameter is used exclusively by AppConfig. When a user creates an AppConfig configuration in an SSM document, the user must also specify a required document for validation purposes. In this case, an ApplicationConfiguration document requires an ApplicationConfigurationSchema document for validation purposes. For more information, see What is AppConfig? (https://docs.aws.amazon.com/appconfig/latest/userguide/what-is-appconfig.html) in the AppConfig User Guide. — item shape: {Name: string, Version?: string, RequireType?: string, VersionName?: string}
  --attachments: list # A list of key-value pairs that describe attachments to a version of a document. — item shape: {Key?: "SourceUrl"|"S3FileUrl"|"AttachmentReference", Values?: list<string>, Name?: string}
  name: string # A name for the SSM document. You can't use the following strings as document name prefixes. These are reserved by Amazon Web Services for use as document name prefixes: aws amazon amzn
  --display-name: string # An optional field where you can specify a friendly name for the SSM document. This value can differ for each version of the document. You can update this value at a later time using the UpdateDocument operation.
  --version-name: string # An optional field specifying the version of the artifact you are creating with the document. For example, Release12.1. This value is unique across all versions of a document, and can't be changed.
  --document-type: string@document-type-completer # The type of document to create. The DeploymentStrategy document type is an internal-use-only document type reserved for AppConfig.
  --document-format: string@document-format-completer # Specify the document format for the request. The document format can be JSON, YAML, or TEXT. JSON is the default format.
  --target-type: string # Specify a target type to define the kinds of resources the document can run on. For example, to run a document on EC2 instances, specify the following value: /AWS::EC2::Instance. If you specify a value of '/' the document can run on all types of resources. If you don't specify a value, the document can't run on any resources. For a list of valid resource types, see Amazon Web Services resource and property types reference (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html) in the CloudFormation User Guide.
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag an SSM document to identify the types of targets or the environment where it will run. In this case, you could specify the following key-value pairs: Key=OS,Value=Windows Key=Environment,Value=Production To add tags to an existing SSM document, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
]: any -> oneof<record<DocumentDescription: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreateDocument")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Content": $content, "Requires": $requires, "Attachments": $attachments, "Name": $name, "DisplayName": $display_name, "VersionName": $version_name, "DocumentType": $document_type, "DocumentFormat": $document_format, "TargetType": $target_type, "Tags": $tags} | compact
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

# Creates a new maintenance window. The value you specify for Duration determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for Cutoff. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for Cutoff is one hour, no maintenance window tasks can start after 5 PM.
#
# POST /
# operationId: CreateMaintenanceWindow
export def "create-maintenance-window" [
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
  name: string # The name of the maintenance window.
  --description: string # An optional description for the maintenance window. We recommend specifying a description to help you organize your maintenance windows. (format: password)
  --start-date: string # The date and time, in ISO-8601 Extended format, for when you want the maintenance window to become active. StartDate allows you to delay activation of the maintenance window until the specified future date.
  --end-date: string # The date and time, in ISO-8601 Extended format, for when you want the maintenance window to become inactive. EndDate allows you to set a date and time in the future when the maintenance window will no longer run.
  schedule: string # The schedule of the maintenance window in the form of a cron or rate expression.
  --schedule-timezone: string # The time zone that the scheduled maintenance window executions are based on, in Internet Assigned Numbers Authority (IANA) format. For example: "America/Los_Angeles", "UTC", or "Asia/Seoul". For more information, see the Time Zone Database (https://www.iana.org/time-zones) on the IANA website.
  --schedule-offset: int # The number of days to wait after the date and time specified by a cron expression before running the maintenance window. For example, the following cron expression schedules a maintenance window to run on the third Tuesday of every month at 11:30 PM. cron(30 23 ? * TUE#3 *) If the schedule offset is 2, the maintenance window won't run until two days later.
  duration: int # The duration of the maintenance window in hours.
  cutoff: int # The number of hours before the end of the maintenance window that Amazon Web Services Systems Manager stops scheduling new tasks for execution.
  --allow-unassociated-targets: oneof<nothing, bool> # Enables a maintenance window task to run on managed nodes, even if you haven't registered those nodes as targets. If enabled, then you must specify the unregistered managed nodes (by node ID) when you register a task with the maintenance window. If you don't enable this option, then you must specify previously-registered targets when you register a task with the maintenance window.
  --client-token: string # User-provided idempotency token.
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag a maintenance window to identify the type of tasks it will run, the types of targets, and the environment it will run in. In this case, you could specify the following key-value pairs: Key=TaskType,Value=AgentUpdate Key=OS,Value=Windows Key=Environment,Value=Production To add tags to an existing maintenance window, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
]: any -> oneof<record<WindowId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreateMaintenanceWindow")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "StartDate": $start_date, "EndDate": $end_date, "Schedule": $schedule, "ScheduleTimezone": $schedule_timezone, "ScheduleOffset": $schedule_offset, "Duration": $duration, "Cutoff": $cutoff, "AllowUnassociatedTargets": $allow_unassociated_targets, "ClientToken": $client_token, "Tags": $tags} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "AllowUnassociatedTargets") == null) { error make --unspanned { msg: "required body field 'AllowUnassociatedTargets' missing: pass --allow-unassociated-targets or pipe a record" } }
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

# Creates a new OpsItem. You must have permission in Identity and Access Management (IAM) to create a new OpsItem. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html) in the Amazon Web Services Systems Manager User Guide. Operations engineers and IT professionals use Amazon Web Services Systems Manager OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their Amazon Web Services resources. For more information, see Amazon Web Services Systems Manager OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# operationId: CreateOpsItem
export def "create-ops-item" [
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
  description: string # Information about the OpsItem.
  --ops-item-type: string # The type of OpsItem to create. Systems Manager supports the following types of OpsItems: /aws/issue This type of OpsItem is used for default OpsItems created by OpsCenter. /aws/changerequest This type of OpsItem is used by Change Manager for reviewing and approving or rejecting change requests. /aws/insights This type of OpsItem is used by OpsCenter for aggregating and reporting on duplicate OpsItems.
  --operational-data: record # Operational data is custom data that provides useful reference details about the OpsItem. For example, you can specify log files, error strings, license keys, troubleshooting tips, or other relevant data. You enter operational data as key-value pairs. The key has a maximum length of 128 characters. The value has a maximum size of 20 KB. Operational data keys can't begin with the following: amazon, aws, amzn, ssm, /amazon, /aws, /amzn, /ssm. You can choose to make the data searchable by other users in the account or you can restrict search access. Searchable data means that all users with access to the OpsItem Overview page (as provided by the DescribeOpsItems API operation) can view and search on the specified data. Operational data that isn't searchable is only viewable by users who have access to the OpsItem (as provided by the GetOpsItem API operation). Use the /aws/resources key in OperationalData to specify a related resource in the request. Use the /aws/automations key in OperationalData to associate an Automation runbook with the OpsItem. To view Amazon Web Services CLI example commands that use these keys, see Creating OpsItems manually (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-creating-OpsItems.html#OpsCenter-manually-create-OpsItems) in the Amazon Web Services Systems Manager User Guide.
  --notifications: list # The Amazon Resource Name (ARN) of an SNS topic where notifications are sent when this OpsItem is edited or changed. — item shape: {Arn?: string}
  --priority: int # The importance of this OpsItem in relation to other OpsItems in the system.
  --related-ops-items: list # One or more OpsItems that share something in common with the current OpsItems. For example, related OpsItems can include OpsItems with similar error messages, impacted resources, or statuses for the impacted resource. — item shape: {OpsItemId: string}
  source: string # The origin of the OpsItem, such as Amazon EC2 or Systems Manager. The source name can't contain the following strings: aws, amazon, and amzn.
  title: string # A short heading that describes the nature of the OpsItem and the impacted resource.
  --tags: list # Optional metadata that you assign to a resource. You can restrict access to OpsItems by using an inline IAM policy that specifies tags. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html#OpsCenter-getting-started-user-permissions) in the Amazon Web Services Systems Manager User Guide. Tags use a key-value pair. For example: Key=Department,Value=Finance To add tags to a new OpsItem, a user must have IAM permissions for both the ssm:CreateOpsItems operation and the ssm:AddTagsToResource operation. To add tags to an existing OpsItem, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
  --category: string # Specify a category to assign to an OpsItem.
  --severity: string # Specify a severity to assign to an OpsItem.
  --actual-start-time: string # The time a runbook workflow started. Currently reported only for the OpsItem type /aws/changerequest. (format: date-time)
  --actual-end-time: string # The time a runbook workflow ended. Currently reported only for the OpsItem type /aws/changerequest. (format: date-time)
  --planned-start-time: string # The time specified in a change request for a runbook workflow to start. Currently supported only for the OpsItem type /aws/changerequest. (format: date-time)
  --planned-end-time: string # The time specified in a change request for a runbook workflow to end. Currently supported only for the OpsItem type /aws/changerequest. (format: date-time)
  --account-id: string # The target Amazon Web Services account where you want to create an OpsItem. To make this call, your account must be configured to work with OpsItems across accounts. For more information, see Setting up OpsCenter to work with OpsItems across accounts (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-OpsCenter-multiple-accounts.html) in the Amazon Web Services Systems Manager User Guide.
]: any -> oneof<record<OpsItemId: string, OpsItemArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreateOpsItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Description": $description, "OpsItemType": $ops_item_type, "OperationalData": $operational_data, "Notifications": $notifications, "Priority": $priority, "RelatedOpsItems": $related_ops_items, "Source": $source, "Title": $title, "Tags": $tags, "Category": $category, "Severity": $severity, "ActualStartTime": $actual_start_time, "ActualEndTime": $actual_end_time, "PlannedStartTime": $planned_start_time, "PlannedEndTime": $planned_end_time, "AccountId": $account_id} | compact
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

# If you create a new application in Application Manager, Amazon Web Services Systems Manager calls this API operation to specify information about the new application, including the application type.
#
# POST /
# operationId: CreateOpsMetadata
export def "create-ops-metadata" [
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
  resource_id: string # A resource ID for a new Application Manager application.
  --metadata: record # Metadata for a new Application Manager application.
  --tags: list # Optional metadata that you assign to a resource. You can specify a maximum of five tags for an OpsMetadata object. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag an OpsMetadata object to identify an environment or target Amazon Web Services Region. In this case, you could specify the following key-value pairs: Key=Environment,Value=Production Key=Region,Value=us-east-2 — item shape: {Key: string, Value: string}
]: any -> oneof<record<OpsMetadataArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreateOpsMetadata")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id, "Metadata": $metadata, "Tags": $tags} | compact
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

# Creates a patch baseline. For information about valid key-value pairs in PatchFilters for each supported operating system type, see PatchFilter.
#
# POST /
# operationId: CreatePatchBaseline
export def "create-patch-baseline" [
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
  --operating-system: string@operating-system-completer # Defines the operating system the patch baseline applies to. The default value is WINDOWS.
  name: string # The name of the patch baseline.
  --global-filters: record # A set of patch filters, typically used for approval rules. — shape: {PatchFilters: list}
  --approval-rules: record # A set of rules defining the approval rules for a patch baseline. — shape: {PatchRules: list}
  --approved-patches: list<string> # A list of explicitly approved patches for the baseline. For information about accepted formats for lists of approved patches and rejected patches, see About package name formats for approved and rejected patch lists (https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-approved-rejected-package-name-formats.html) in the Amazon Web Services Systems Manager User Guide.
  --approved-patches-compliance-level: string@approved-patches-compliance-level-completer # Defines the compliance level for approved patches. When an approved patch is reported as missing, this value describes the severity of the compliance violation. The default value is UNSPECIFIED.
  --approved-patches-enable-non-security: oneof<nothing, bool> # Indicates whether the list of approved patches includes non-security updates that should be applied to the managed nodes. The default value is false. Applies to Linux managed nodes only.
  --rejected-patches: list<string> # A list of explicitly rejected patches for the baseline. For information about accepted formats for lists of approved patches and rejected patches, see About package name formats for approved and rejected patch lists (https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-approved-rejected-package-name-formats.html) in the Amazon Web Services Systems Manager User Guide.
  --rejected-patches-action: string@rejected-patches-action-completer # The action for Patch Manager to take on patches included in the RejectedPackages list. ALLOW_AS_DEPENDENCY : A package in the Rejected patches list is installed only if it is a dependency of another package. It is considered compliant with the patch baseline, and its status is reported as InstalledOther. This is the default action if no option is specified. BLOCK : Packages in the RejectedPatches list, and packages that include them as dependencies, aren't installed under any circumstances. If a package was installed before it was added to the Rejected patches list, it is considered non-compliant with the patch baseline, and its status is reported as InstalledRejected.
  --description: string # A description of the patch baseline.
  --sources: list # Information about the patches to use to update the managed nodes, including target operating systems and source repositories. Applies to Linux managed nodes only. — item shape: {Name: string, Products: list<string>, Configuration: string}
  --client-token: string # User-provided idempotency token.
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag a patch baseline to identify the severity level of patches it specifies and the operating system family it applies to. In this case, you could specify the following key-value pairs: Key=PatchSeverity,Value=Critical Key=OS,Value=Windows To add tags to an existing patch baseline, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
]: any -> oneof<record<BaselineId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreatePatchBaseline")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OperatingSystem": $operating_system, "Name": $name, "GlobalFilters": $global_filters, "ApprovalRules": $approval_rules, "ApprovedPatches": $approved_patches, "ApprovedPatchesComplianceLevel": $approved_patches_compliance_level, "ApprovedPatchesEnableNonSecurity": $approved_patches_enable_non_security, "RejectedPatches": $rejected_patches, "RejectedPatchesAction": $rejected_patches_action, "Description": $description, "Sources": $sources, "ClientToken": $client_token, "Tags": $tags} | compact
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

# A resource data sync helps you view data from multiple sources in a single location. Amazon Web Services Systems Manager offers two types of resource data sync: SyncToDestination and SyncFromSource. You can configure Systems Manager Inventory to use the SyncToDestination type to synchronize Inventory data from multiple Amazon Web Services Regions to a single Amazon Simple Storage Service (Amazon S3) bucket. For more information, see Configuring resource data sync for Inventory (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html) in the Amazon Web Services Systems Manager User Guide. You can configure Systems Manager Explorer to use the SyncFromSource type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple Amazon Web Services Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple Amazon Web Services accounts and Amazon Web Services Regions or EntireOrganization by using Organizations. For more information, see Setting up Systems Manager Explorer to display data from multiple accounts and Regions (https://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html) in the Amazon Web Services Systems Manager User Guide. A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the ListResourceDataSync. By default, data isn't encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy.
#
# POST /
# operationId: CreateResourceDataSync
export def "create-resource-data-sync" [
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
  sync_name: string # A name for the configuration.
  --s3-destination: record # Information about the target S3 bucket for the resource data sync. — shape: {BucketName: string, Prefix?: string, SyncFormat: "JsonSerDe", Region: string, AWSKMSKeyARN?: string, DestinationDataSharing?: record}
  --sync-type: string # Specify SyncToDestination to create a resource data sync that synchronizes data to an S3 bucket for Inventory. If you specify SyncToDestination, you must provide a value for S3Destination. Specify SyncFromSource to synchronize data from a single account and multiple Regions, or multiple Amazon Web Services accounts and Amazon Web Services Regions, as listed in Organizations for Explorer. If you specify SyncFromSource, you must provide a value for SyncSource. The default value is SyncToDestination.
  --sync-source: record # Information about the source of the data included in the resource data sync. — shape: {SourceType: string, AwsOrganizationsSource?: record, SourceRegions: list<string>, IncludeFutureRegions?: bool, EnableAllOpsDataSources?: bool}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.CreateResourceDataSync")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SyncName": $sync_name, "S3Destination": $s3_destination, "SyncType": $sync_type, "SyncSource": $sync_source} | compact
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

# Deletes an activation. You aren't required to delete an activation. If you delete an activation, you can no longer use it to register additional managed nodes. Deleting an activation doesn't de-register managed nodes. You must manually de-register managed nodes.
#
# POST /
# operationId: DeleteActivation
export def "delete-activation" [
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
  activation_id: string # The ID of the activation that you want to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteActivation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ActivationId": $activation_id} | compact
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

# Disassociates the specified Amazon Web Services Systems Manager document (SSM document) from the specified managed node. If you created the association by using the Targets parameter, then you must delete the association by using the association ID. When you disassociate a document from a managed node, it doesn't change the configuration of the node. To change the configuration state of a managed node after you disassociate a document, you must create a new document with the desired configuration and associate it with the node.
#
# POST /
# operationId: DeleteAssociation
export def "delete-association" [
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
  --name: string # The name of the SSM document.
  --instance-id: string # The managed node ID. InstanceId has been deprecated. To specify a managed node ID for an association, use the Targets parameter. Requests that include the parameter InstanceID with Systems Manager documents (SSM documents) that use schema version 2.0 or later will fail. In addition, if you use the parameter InstanceId, you can't use the parameters AssociationName, DocumentVersion, MaxErrors, MaxConcurrency, OutputLocation, or ScheduleExpression. To use these parameters, you must use the Targets parameter.
  --association-id: string # The association ID that you want to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "InstanceId": $instance_id, "AssociationId": $association_id} | compact
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

# Deletes the Amazon Web Services Systems Manager document (SSM document) and all managed node associations to the document. Before you delete the document, we recommend that you use DeleteAssociation to disassociate all managed nodes that are associated with the document.
#
# POST /
# operationId: DeleteDocument
export def "delete-document" [
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
  name: string # The name of the document.
  --document-version: string # The version of the document that you want to delete. If not provided, all versions of the document are deleted.
  --version-name: string # The version name of the document that you want to delete. If not provided, all versions of the document are deleted.
  --force: oneof<nothing, bool> # Some SSM document types require that you specify a Force flag before you can delete the document. For example, you must specify a Force flag to delete a document of type ApplicationConfigurationSchema. You can restrict access to the Force flag in an Identity and Access Management (IAM) policy.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteDocument")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "DocumentVersion": $document_version, "VersionName": $version_name, "Force": $force} | compact
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

# Delete a custom inventory type or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
#
# POST /
# operationId: DeleteInventory
export def "delete-inventory" [
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
  type_name: string # The name of the custom inventory type for which you want to delete either all previously collected data or the inventory type itself.
  --schema-delete-option: string@schema-delete-option-completer # Use the SchemaDeleteOption to delete a custom inventory type (schema). If you don't choose this option, the system only deletes existing inventory data associated with the custom inventory type. Choose one of the following options: DisableSchema: If you choose this option, the system ignores all inventory data for the specified version, and any earlier versions. To enable this schema again, you must call the PutInventory operation for a version greater than the disabled version. DeleteSchema: This option deletes the specified custom type from the Inventory service. You can recreate the schema later, if you want.
  --body-dry-run: oneof<nothing, bool> # Use this option to view a summary of the deletion request without deleting any data or the data type. This option is useful when you only want to understand what will be deleted. Once you validate that the data to be deleted is what you intend to delete, you can run the same command without specifying the DryRun option. (spec name: DryRun)
  --client-token: string # User-provided idempotency token.
]: any -> oneof<record<DeletionId: string, TypeName: string, DeletionSummary: record<TotalCount: int, RemainingCount: int, SummaryItems: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteInventory")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"TypeName": $type_name, "SchemaDeleteOption": $schema_delete_option, "DryRun": $body_dry_run, "ClientToken": $client_token} | compact
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

# Deletes a maintenance window.
#
# POST /
# operationId: DeleteMaintenanceWindow
export def "delete-maintenance-window" [
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
  window_id: string # The ID of the maintenance window to delete.
]: any -> oneof<record<WindowId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteMaintenanceWindow")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id} | compact
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

# Delete OpsMetadata related to an application.
#
# POST /
# operationId: DeleteOpsMetadata
export def "delete-ops-metadata" [
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
  ops_metadata_arn: string # The Amazon Resource Name (ARN) of an OpsMetadata Object to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteOpsMetadata")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OpsMetadataArn": $ops_metadata_arn} | compact
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

# Delete a parameter from the system. After deleting a parameter, wait for at least 30 seconds to create a parameter with the same name.
#
# POST /
# operationId: DeleteParameter
export def "delete-parameter" [
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
  name: string # The name of the parameter to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteParameter")
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

# Delete a list of parameters. After deleting a parameter, wait for at least 30 seconds to create a parameter with the same name.
#
# POST /
# operationId: DeleteParameters
export def "delete-parameters" [
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
  names: list<string> # The names of the parameters to delete. After deleting a parameter, wait for at least 30 seconds to create a parameter with the same name.
]: any -> oneof<record<DeletedParameters: list<string>, InvalidParameters: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteParameters")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Names": $names} | compact
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

# Deletes a patch baseline.
#
# POST /
# operationId: DeletePatchBaseline
export def "delete-patch-baseline" [
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
  baseline_id: string # The ID of the patch baseline to delete.
]: any -> oneof<record<BaselineId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeletePatchBaseline")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BaselineId": $baseline_id} | compact
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

# Deletes a resource data sync configuration. After the configuration is deleted, changes to data on managed nodes are no longer synced to or from the target. Deleting a sync configuration doesn't delete data.
#
# POST /
# operationId: DeleteResourceDataSync
export def "delete-resource-data-sync" [
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
  sync_name: string # The name of the configuration to delete.
  --sync-type: string # Specify the type of resource data sync to delete.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteResourceDataSync")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SyncName": $sync_name, "SyncType": $sync_type} | compact
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

# Deletes a Systems Manager resource policy. A resource policy helps you to define the IAM entity (for example, an Amazon Web Services account) that can manage your Systems Manager resources. Currently, OpsItemGroup is the only resource that supports Systems Manager resource policies. The resource policy for OpsItemGroup enables Amazon Web Services accounts to view and interact with OpsCenter operational work items (OpsItems).
#
# POST /
# operationId: DeleteResourcePolicy
export def "delete-resource-policy" [
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
  resource_arn: string # Amazon Resource Name (ARN) of the resource to which the policies are attached.
  policy_id: string # The policy ID.
  policy_hash: string # ID of the current policy version. The hash helps to prevent multiple calls from attempting to overwrite a policy.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeleteResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "PolicyId": $policy_id, "PolicyHash": $policy_hash} | compact
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

# Removes the server or virtual machine from the list of registered servers. You can reregister the node again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
#
# POST /
# operationId: DeregisterManagedInstance
export def "deregister-managed-instance" [
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
  instance_id: string # The ID assigned to the managed node when you registered it using the activation process.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeregisterManagedInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"InstanceId": $instance_id} | compact
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

# Removes a patch group from a patch baseline.
#
# POST /
# operationId: DeregisterPatchBaselineForPatchGroup
export def "deregister-patch-baseline-for-patch-group" [
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
  baseline_id: string # The ID of the patch baseline to deregister the patch group from.
  patch_group: string # The name of the patch group that should be deregistered from the patch baseline.
]: any -> oneof<record<BaselineId: string, PatchGroup: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeregisterPatchBaselineForPatchGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BaselineId": $baseline_id, "PatchGroup": $patch_group} | compact
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

# Removes a target from a maintenance window.
#
# POST /
# operationId: DeregisterTargetFromMaintenanceWindow
export def "deregister-target-from-maintenance-window" [
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
  window_id: string # The ID of the maintenance window the target should be removed from.
  window_target_id: string # The ID of the target definition to remove.
  --safe: oneof<nothing, bool> # The system checks if the target is being referenced by a task. If the target is being referenced, the system returns an error and doesn't deregister the target from the maintenance window.
]: any -> oneof<record<WindowId: string, WindowTargetId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeregisterTargetFromMaintenanceWindow")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id, "WindowTargetId": $window_target_id, "Safe": $safe} | compact
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

# Removes a task from a maintenance window.
#
# POST /
# operationId: DeregisterTaskFromMaintenanceWindow
export def "deregister-task-from-maintenance-window" [
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
  window_id: string # The ID of the maintenance window the task should be removed from.
  window_task_id: string # The ID of the task to remove from the maintenance window.
]: any -> oneof<record<WindowId: string, WindowTaskId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DeregisterTaskFromMaintenanceWindow")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id, "WindowTaskId": $window_task_id} | compact
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

# Describes details about the activation, such as the date and time the activation was created, its expiration date, the Identity and Access Management (IAM) role assigned to the managed nodes in the activation, and the number of nodes registered by using this activation.
#
# POST /
# operationId: DescribeActivations
export def "describe-activations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-28 # required
  --filters: list # A filter to view information about your activations. — item shape: {FilterKey?: "ActivationIds"|"DefaultInstanceName"|"IamRole", FilterValues?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record<ActivationList: table<ActivationId: string, Description: string, DefaultInstanceName: string, IamRole: string, RegistrationLimit: int, RegistrationsCount: int, ExpirationDate: string, Expired: bool, CreatedDate: string, Tags: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeActivations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes the association for the specified target or managed node. If you created the association by using the Targets parameter, then you must retrieve the association by using the association ID.
#
# POST /
# operationId: DescribeAssociation
export def "describe-association" [
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
  --name: string # The name of the SSM document.
  --instance-id: string # The managed node ID.
  --association-id: string # The association ID for which you want information.
  --association-version: string # Specify the association version to retrieve. To view the latest version, either specify $LATEST for this parameter, or omit this parameter. To view a list of all associations for a managed node, use ListAssociations. To get a list of versions for a specific association, use ListAssociationVersions.
]: any -> oneof<record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "InstanceId": $instance_id, "AssociationId": $association_id, "AssociationVersion": $association_version} | compact
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

# Views information about a specific execution of a specific association.
#
# POST /
# operationId: DescribeAssociationExecutionTargets
export def "describe-association-execution-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-30 # required
  association_id: string # The association ID that includes the execution for which you want to view details.
  execution_id: string # The execution ID for which you want to view details.
  --filters: list # Filters for the request. You can specify the following filters and values. Status (EQUAL) ResourceId (EQUAL) ResourceType (EQUAL) — item shape: {Key: "Status"|"ResourceId"|"ResourceType", Value: string}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record<AssociationExecutionTargets: table<AssociationId: string, AssociationVersion: string, ExecutionId: string, ResourceId: string, ResourceType: string, Status: string, DetailedStatus: string, LastExecutionDate: string, OutputSource: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeAssociationExecutionTargets")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AssociationId": $association_id, "ExecutionId": $execution_id, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Views all executions for a specific association ID.
#
# POST /
# operationId: DescribeAssociationExecutions
export def "describe-association-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-31 # required
  association_id: string # The association ID for which you want to view execution history details.
  --filters: list # Filters for the request. You can specify the following filters and values. ExecutionId (EQUAL) Status (EQUAL) CreatedTime (EQUAL, GREATER_THAN, LESS_THAN) — item shape: {Key: "ExecutionId"|"Status"|"CreatedTime", Value: string, Type: "EQUAL"|"LESS_THAN"|"GREATER_THAN"}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record<AssociationExecutions: table<AssociationId: string, AssociationVersion: string, ExecutionId: string, Status: string, DetailedStatus: string, CreatedTime: string, LastExecutionDate: string, ResourceCountByStatus: string, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeAssociationExecutions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AssociationId": $association_id, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Provides details about all active and terminated Automation executions.
#
# POST /
# operationId: DescribeAutomationExecutions
export def "describe-automation-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-32 # required
  --filters: list # Filters used to limit the scope of executions that are requested. — item shape: {Key: "DocumentNamePrefix"|"ExecutionStatus"|"ExecutionId"|"ParentExecutionId"|"CurrentAction"|"StartTimeBefore"|"StartTimeAfter"|"AutomationType"|"TagKey"|"TargetResourceGroup"|"AutomationSubtype"|"OpsItemId", Values: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<AutomationExecutionMetadataList: table<AutomationExecutionId: string, DocumentName: string, DocumentVersion: string, AutomationExecutionStatus: string, ExecutionStartTime: string, ExecutionEndTime: string, ExecutedBy: string, LogFile: string, Outputs: record, Mode: string, ParentAutomationExecutionId: string, CurrentStepName: string, CurrentAction: string, FailureMessage: string, TargetParameterName: string, Targets: list, TargetMaps: list, ResolvedTargets: record, MaxConcurrency: string, MaxErrors: string, Target: string, AutomationType: string, AlarmConfiguration: record, TriggeredAlarms: list, AutomationSubtype: string, ScheduledTime: string, Runbooks: list, OpsItemId: string, AssociationId: string, ChangeRequestName: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeAutomationExecutions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Information about all active and terminated step executions in an Automation workflow.
#
# POST /
# operationId: DescribeAutomationStepExecutions
export def "describe-automation-step-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-33 # required
  automation_execution_id: string # The Automation execution ID for which you want step execution descriptions.
  --filters: list # One or more filters to limit the number of step executions returned by the request. — item shape: {Key: "StartTimeBefore"|"StartTimeAfter"|"StepExecutionStatus"|"StepExecutionId"|"StepName"|"Action", Values: list<string>}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --reverse-order: oneof<nothing, bool> # Indicates whether to list step executions in reverse order by start time. The default value is 'false'.
]: any -> oneof<record<StepExecutions: table<StepName: string, Action: string, TimeoutSeconds: int, OnFailure: string, MaxAttempts: int, ExecutionStartTime: string, ExecutionEndTime: string, StepStatus: string, ResponseCode: string, Inputs: record, Outputs: record, Response: string, FailureMessage: string, FailureDetails: record, StepExecutionId: string, OverriddenParameters: record, IsEnd: bool, NextStep: string, IsCritical: bool, ValidNextSteps: list, Targets: list, TargetLocation: record, TriggeredAlarms: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeAutomationStepExecutions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AutomationExecutionId": $automation_execution_id, "Filters": $filters, "NextToken": $body_next_token, "MaxResults": $body_max_results, "ReverseOrder": $reverse_order} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all patches eligible to be included in a patch baseline.
#
# POST /
# operationId: DescribeAvailablePatches
export def "describe-available-patches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-34 # required
  --filters: list # Each element in the array is a structure containing a key-value pair. Windows Server Supported keys for Windows Server managed node patches include the following: PATCH_SET Sample values: OS | APPLICATION PRODUCT Sample values: WindowsServer2012 | Office 2010 | MicrosoftDefenderAntivirus PRODUCT_FAMILY Sample values: Windows | Office MSRC_SEVERITY Sample values: ServicePacks | Important | Moderate CLASSIFICATION Sample values: ServicePacks | SecurityUpdates | DefinitionUpdates PATCH_ID Sample values: KB123456 | KB4516046 Linux When specifying filters for Linux patches, you must specify a key-pair for PRODUCT. For example, using the Command Line Interface (CLI), the following command fails: aws ssm describe-available-patches --filters Key=CVE_ID,Values=CVE-2018-3615 However, the following command succeeds: aws ssm describe-available-patches --filters Key=PRODUCT,Values=AmazonLinux2018.03 Key=CVE_ID,Values=CVE-2018-3615 Supported keys for Linux managed node patches include the following: PRODUCT Sample values: AmazonLinux2018.03 | AmazonLinux2.0 NAME Sample values: kernel-headers | samba-python | php SEVERITY Sample values: Critical | Important | Medium | Low EPOCH Sample values: 0 | 1 VERSION Sample values: 78.6.1 | 4.10.16 RELEASE Sample values: 9.56.amzn1 | 1.amzn2 ARCH Sample values: i686 | x86_64 REPOSITORY Sample values: Core | Updates ADVISORY_ID Sample values: ALAS-2018-1058 | ALAS2-2021-1594 CVE_ID Sample values: CVE-2018-3615 | CVE-2020-1472 BUGZILLA_ID Sample values: 1463241 — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of patches to return (per page). (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Patches: table<Id: string, ReleaseDate: string, Title: string, Description: string, ContentUrl: string, Vendor: string, ProductFamily: string, Product: string, Classification: string, MsrcSeverity: string, KbNumber: string, MsrcNumber: string, Language: string, AdvisoryIds: list, BugzillaIds: list, CVEIds: list, Name: string, Epoch: int, Version: string, Release: string, Arch: string, Severity: string, Repository: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeAvailablePatches")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes the specified Amazon Web Services Systems Manager document (SSM document).
#
# POST /
# operationId: DescribeDocument
export def "describe-document" [
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
  name: string # The name of the SSM document.
  --document-version: string # The document version for which you want information. Can be a specific version or the default version.
  --version-name: string # An optional field specifying the version of the artifact associated with the document. For example, "Release 12, Update 6". This value is unique across all versions of a document, and can't be changed.
]: any -> oneof<record<Document: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeDocument")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "DocumentVersion": $document_version, "VersionName": $version_name} | compact
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

# Describes the permissions for a Amazon Web Services Systems Manager document (SSM document). If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's Amazon Web Services account ID) or publicly (All).
#
# POST /
# operationId: DescribeDocumentPermission
export def "describe-document-permission" [
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
  --x-amz-target: string@x-amz-target-completer-36 # required
  name: string # The name of the document for which you are the owner.
  permission_type: string@permission-type-completer # The permission type for the document. The permission type can be Share.
  --max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
]: any -> oneof<record<AccountIds: list<string>, AccountSharingInfoList: table<AccountId: string, SharedDocumentVersion: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeDocumentPermission")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "PermissionType": $permission_type, "MaxResults": $max_results, "NextToken": $next_token} | compact
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

# All associations for the managed node(s).
#
# POST /
# operationId: DescribeEffectiveInstanceAssociations
export def "describe-effective-instance-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37 # required
  instance_id: string # The managed node ID for which you want to view all associations.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Associations: table<AssociationId: string, InstanceId: string, Content: string, AssociationVersion: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeEffectiveInstanceAssociations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"InstanceId": $instance_id, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Applies to patch baselines for Windows only.
#
# POST /
# operationId: DescribeEffectivePatchesForPatchBaseline
export def "describe-effective-patches-for-patch-baseline" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38 # required
  baseline_id: string # The ID of the patch baseline to retrieve the effective patches for.
  --body-max-results: int # The maximum number of patches to return (per page). (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<EffectivePatches: table<Patch: record, PatchStatus: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeEffectivePatchesForPatchBaseline")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"BaselineId": $baseline_id, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# The status of the associations for the managed node(s).
#
# POST /
# operationId: DescribeInstanceAssociationsStatus
export def "describe-instance-associations-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-39 # required
  instance_id: string # The managed node IDs for which you want association status information.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<InstanceAssociationStatusInfos: table<AssociationId: string, Name: string, DocumentVersion: string, AssociationVersion: string, InstanceId: string, ExecutionDate: string, Status: string, DetailedStatus: string, ExecutionSummary: string, ErrorCode: string, OutputUrl: record, AssociationName: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeInstanceAssociationsStatus")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"InstanceId": $instance_id, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes one or more of your managed nodes, including information about the operating system platform, the version of SSM Agent installed on the managed node, node status, and so on. If you specify one or more managed node IDs, it returns information for those managed nodes. If you don't specify node IDs, it returns information for all your managed nodes. If you specify a node ID that isn't valid or a node that you don't own, you receive an error. The IamRole field for this API operation is the Identity and Access Management (IAM) role assigned to on-premises managed nodes. This call doesn't return the IAM role for EC2 instances.
#
# POST /
# operationId: DescribeInstanceInformation
export def "describe-instance-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-40 # required
  --instance-information-filter-list: list # This is a legacy method. We recommend that you don't use this method. Instead, use the Filters data type. Filters enables you to return node information by filtering based on tags applied to managed nodes. Attempting to use InstanceInformationFilterList and Filters leads to an exception error. — item shape: {key: "InstanceIds"|"AgentVersion"|"PingStatus"|"PlatformTypes"|"ActivationIds"|"IamRole"|"ResourceType"|"AssociationStatus", valueSet: list<string>}
  --filters: list # One or more filters. Use a filter to return a more specific list of managed nodes. You can filter based on tags applied to your managed nodes. Use this Filters data type instead of InstanceInformationFilterList, which is deprecated. — item shape: {Key: string, Values: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<InstanceInformationList: table<InstanceId: string, PingStatus: string, LastPingDateTime: string, AgentVersion: string, IsLatestVersion: bool, PlatformType: string, PlatformName: string, PlatformVersion: string, ActivationId: string, IamRole: string, RegistrationDate: string, ResourceType: string, Name: string, IPAddress: string, ComputerName: string, AssociationStatus: string, LastAssociationExecutionDate: string, LastSuccessfulAssociationExecutionDate: string, AssociationOverview: record, SourceId: string, SourceType: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeInstanceInformation")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"InstanceInformationFilterList": $instance_information_filter_list, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the high-level patch state of one or more managed nodes.
#
# POST /
# operationId: DescribeInstancePatchStates
export def "describe-instance-patch-states" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-41 # required
  instance_ids: list<string> # The ID of the managed node for which patch state information should be retrieved.
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of managed nodes to return (per page). (spec name: MaxResults)
]: any -> oneof<record<InstancePatchStates: table<InstanceId: string, PatchGroup: string, BaselineId: string, SnapshotId: string, InstallOverrideList: string, OwnerInformation: string, InstalledCount: int, InstalledOtherCount: int, InstalledPendingRebootCount: int, InstalledRejectedCount: int, MissingCount: int, FailedCount: int, UnreportedNotApplicableCount: int, NotApplicableCount: int, OperationStartTime: string, OperationEndTime: string, Operation: string, LastNoRebootInstallOperationTime: string, RebootOption: string, CriticalNonCompliantCount: int, SecurityNonCompliantCount: int, OtherNonCompliantCount: int>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeInstancePatchStates")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"InstanceIds": $instance_ids, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the high-level patch state for the managed nodes in the specified patch group.
#
# POST /
# operationId: DescribeInstancePatchStatesForPatchGroup
export def "describe-instance-patch-states-for-patch-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-42 # required
  patch_group: string # The name of the patch group for which the patch state information should be retrieved.
  --filters: list # Each entry in the array is a structure containing: Key (string between 1 and 200 characters) Values (array containing a single string) Type (string "Equal", "NotEqual", "LessThan", "GreaterThan") — item shape: {Key: string, Values: list<string>, Type: "Equal"|"NotEqual"|"LessThan"|"GreaterThan"}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of patches to return (per page). (spec name: MaxResults)
]: any -> oneof<record<InstancePatchStates: table<InstanceId: string, PatchGroup: string, BaselineId: string, SnapshotId: string, InstallOverrideList: string, OwnerInformation: string, InstalledCount: int, InstalledOtherCount: int, InstalledPendingRebootCount: int, InstalledRejectedCount: int, MissingCount: int, FailedCount: int, UnreportedNotApplicableCount: int, NotApplicableCount: int, OperationStartTime: string, OperationEndTime: string, Operation: string, LastNoRebootInstallOperationTime: string, RebootOption: string, CriticalNonCompliantCount: int, SecurityNonCompliantCount: int, OtherNonCompliantCount: int>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeInstancePatchStatesForPatchGroup")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"PatchGroup": $patch_group, "Filters": $filters, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information about the patches on the specified managed node and their state relative to the patch baseline being used for the node.
#
# POST /
# operationId: DescribeInstancePatches
export def "describe-instance-patches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43 # required
  instance_id: string # The ID of the managed node whose patch state information should be retrieved.
  --filters: list # Each element in the array is a structure containing a key-value pair. Supported keys for DescribeInstancePatchesinclude the following: Classification Sample values: Security | SecurityUpdates KBId Sample values: KB4480056 | java-1.7.0-openjdk.x86_64 Severity Sample values: Important | Medium | Low State Sample values: Installed | InstalledOther | InstalledPendingReboot — item shape: {Key?: string, Values?: list<string>}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of patches to return (per page). (spec name: MaxResults)
]: any -> oneof<record<Patches: table<Title: string, KBId: string, Classification: string, Severity: string, State: string, InstalledTime: string, CVEIds: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeInstancePatches")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"InstanceId": $instance_id, "Filters": $filters, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Describes a specific delete inventory operation.
#
# POST /
# operationId: DescribeInventoryDeletions
export def "describe-inventory-deletions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-44 # required
  --deletion-id: string # Specify the delete inventory ID for which you want information. This ID was returned by the DeleteInventory operation.
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record<InventoryDeletions: table<DeletionId: string, TypeName: string, DeletionStartTime: string, LastStatus: string, LastStatusMessage: string, DeletionSummary: record, LastStatusUpdateTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeInventoryDeletions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"DeletionId": $deletion_id, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
#
# POST /
# operationId: DescribeMaintenanceWindowExecutionTaskInvocations
export def "describe-maintenance-window-execution-task-invocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-45 # required
  window_execution_id: string # The ID of the maintenance window execution the task is part of.
  task_id: string # The ID of the specific task in the maintenance window task that should be retrieved.
  --filters: list # Optional filters used to scope down the returned task invocations. The supported filter key is STATUS with the corresponding values PENDING, IN_PROGRESS, SUCCESS, FAILED, TIMED_OUT, CANCELLING, and CANCELLED. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<WindowExecutionTaskInvocationIdentities: table<WindowExecutionId: string, TaskExecutionId: string, InvocationId: string, ExecutionId: string, TaskType: string, Parameters: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, OwnerInformation: string, WindowTargetId: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"WindowExecutionId": $window_execution_id, "TaskId": $task_id, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# For a given maintenance window execution, lists the tasks that were run.
#
# POST /
# operationId: DescribeMaintenanceWindowExecutionTasks
export def "describe-maintenance-window-execution-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46 # required
  window_execution_id: string # The ID of the maintenance window execution whose task executions should be retrieved.
  --filters: list # Optional filters used to scope down the returned tasks. The supported filter key is STATUS with the corresponding values PENDING, IN_PROGRESS, SUCCESS, FAILED, TIMED_OUT, CANCELLING, and CANCELLED. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<WindowExecutionTaskIdentities: table<WindowExecutionId: string, TaskExecutionId: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, TaskArn: string, TaskType: string, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeMaintenanceWindowExecutionTasks")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"WindowExecutionId": $window_execution_id, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
#
# POST /
# operationId: DescribeMaintenanceWindowExecutions
export def "describe-maintenance-window-executions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47 # required
  window_id: string # The ID of the maintenance window whose executions should be retrieved.
  --filters: list # Each entry in the array is a structure containing: Key. A string between 1 and 128 characters. Supported keys include ExecutedBefore and ExecutedAfter. Values. An array of strings, each between 1 and 256 characters. Supported values are date/time strings in a valid ISO 8601 date/time format, such as 2021-11-04T05:00:00Z. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<WindowExecutions: table<WindowId: string, WindowExecutionId: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeMaintenanceWindowExecutions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"WindowId": $window_id, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information about upcoming executions of a maintenance window.
#
# POST /
# operationId: DescribeMaintenanceWindowSchedule
export def "describe-maintenance-window-schedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-48 # required
  --window-id: string # The ID of the maintenance window to retrieve information about.
  --targets: list # The managed node ID or key-value pair to retrieve information about. — item shape: {Key?: string, Values?: list<string>}
  --resource-type: string@resource-type-completer-1 # The type of resource you want to retrieve information about. For example, INSTANCE.
  --filters: list # Filters used to limit the range of results. For example, you can limit maintenance window executions to only those scheduled before or after a certain date and time. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<ScheduledWindowExecutions: table<WindowId: string, Name: string, ExecutionTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeMaintenanceWindowSchedule")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"WindowId": $window_id, "Targets": $targets, "ResourceType": $resource_type, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the targets registered with the maintenance window.
#
# POST /
# operationId: DescribeMaintenanceWindowTargets
export def "describe-maintenance-window-targets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49 # required
  window_id: string # The ID of the maintenance window whose targets should be retrieved.
  --filters: list # Optional filters that can be used to narrow down the scope of the returned window targets. The supported filter keys are Type, WindowTargetId, and OwnerInformation. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Targets: table<WindowId: string, WindowTargetId: string, ResourceType: string, Targets: list, OwnerInformation: string, Name: string, Description: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeMaintenanceWindowTargets")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"WindowId": $window_id, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the tasks in a maintenance window. For maintenance window tasks without a specified target, you can't supply values for --max-errors and --max-concurrency. Instead, the system inserts a placeholder value of 1, which may be reported in the response to this command. These values don't affect the running of your task and can be ignored.
#
# POST /
# operationId: DescribeMaintenanceWindowTasks
export def "describe-maintenance-window-tasks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50 # required
  window_id: string # The ID of the maintenance window whose tasks should be retrieved.
  --filters: list # Optional filters used to narrow down the scope of the returned tasks. The supported filter keys are WindowTaskId, TaskArn, Priority, and TaskType. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Tasks: table<WindowId: string, WindowTaskId: string, TaskArn: string, Type: string, Targets: list, TaskParameters: record, Priority: int, LoggingInfo: record, ServiceRoleArn: string, MaxConcurrency: string, MaxErrors: string, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeMaintenanceWindowTasks")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"WindowId": $window_id, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves the maintenance windows in an Amazon Web Services account.
#
# POST /
# operationId: DescribeMaintenanceWindows
export def "describe-maintenance-windows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51 # required
  --filters: list # Optional filters used to narrow down the scope of the returned maintenance windows. Supported filter keys are Name and Enabled. For example, Name=MyMaintenanceWindow and Enabled=True. — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<WindowIdentities: table<WindowId: string, Name: string, Description: string, Enabled: bool, Duration: int, Cutoff: int, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, EndDate: string, StartDate: string, NextExecutionTime: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeMaintenanceWindows")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information about the maintenance window targets or tasks that a managed node is associated with.
#
# POST /
# operationId: DescribeMaintenanceWindowsForTarget
export def "describe-maintenance-windows-for-target" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-52 # required
  targets: list # The managed node ID or key-value pair to retrieve information about. — item shape: {Key?: string, Values?: list<string>}
  resource_type: string@resource-type-completer-1 # The type of resource you want to retrieve information about. For example, INSTANCE.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<WindowIdentities: table<WindowId: string, Name: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeMaintenanceWindowsForTarget")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Targets": $targets, "ResourceType": $resource_type, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Query a set of OpsItems. You must have permission in Identity and Access Management (IAM) to query a list of OpsItems. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html) in the Amazon Web Services Systems Manager User Guide. Operations engineers and IT professionals use Amazon Web Services Systems Manager OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their Amazon Web Services resources. For more information, see OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# operationId: DescribeOpsItems
export def "describe-ops-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53 # required
  --ops-item-filters: list # One or more filters to limit the response. Key: CreatedTime Operations: GreaterThan, LessThan Key: LastModifiedBy Operations: Contains, Equals Key: LastModifiedTime Operations: GreaterThan, LessThan Key: Priority Operations: Equals Key: Source Operations: Contains, Equals Key: Status Operations: Equals Key: Title* Operations: Equals,Contains Key: OperationalData** Operations: Equals Key: OperationalDataKey Operations: Equals Key: OperationalDataValue Operations: Equals, Contains Key: OpsItemId Operations: Equals Key: ResourceId Operations: Contains Key: AutomationId Operations: Equals *The Equals operator for Title matches the first 100 characters. If you specify more than 100 characters, they system returns an error that the filter value exceeds the length limit. **If you filter the response by using the OperationalData operator, specify a key-value pair by using the following JSON format: {"key":"key_name","value":"a_value"} — item shape: {Key: "Status"|"CreatedBy"|"Source"|"Priority"|"Title"|"OpsItemId"|"CreatedTime"|"LastModifiedTime"|"ActualStartTime"|"ActualEndTime"|"PlannedStartTime"|"PlannedEndTime"|"OperationalData"|"OperationalDataKey"|"OperationalDataValue"|"ResourceId"|"AutomationId"|"Category"|"Severity"|"OpsItemType"|"ChangeRequestByRequesterArn"|"ChangeRequestByRequesterName"|"ChangeRequestByApproverArn"|"ChangeRequestByApproverName"|"ChangeRequestByTemplate"|"ChangeRequestByTargetsResourceGroup"|"InsightByType"|"AccountId", ... (2 more fields)}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record<NextToken: string, OpsItemSummaries: table<CreatedBy: string, CreatedTime: string, LastModifiedBy: string, LastModifiedTime: string, Priority: int, Source: string, Status: string, OpsItemId: string, Title: string, OperationalData: record, Category: string, Severity: string, OpsItemType: string, ActualStartTime: string, ActualEndTime: string, PlannedStartTime: string, PlannedEndTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeOpsItems")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OpsItemFilters": $ops_item_filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get information about a parameter. Request results are returned on a best-effort basis. If you specify MaxResults in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of MaxResults. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a NextToken. You can specify the NextToken in a subsequent call to get the next set of results. If you change the KMS key alias for the KMS key used to encrypt a parameter, then you must also update the key alias the parameter uses to reference KMS. Otherwise, DescribeParameters retrieves whatever the original key alias was referencing.
#
# POST /
# operationId: DescribeParameters
export def "describe-parameters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54 # required
  --filters: list # This data type is deprecated. Instead, use ParameterFilters. — item shape: {Key: "Name"|"Type"|"KeyId", Values: list<string>}
  --parameter-filters: list # Filters to limit the request results. — item shape: {Key: string, Option?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Parameters: table<Name: string, Type: string, KeyId: string, LastModifiedDate: string, LastModifiedUser: string, Description: string, AllowedPattern: string, Version: int, Tier: string, Policies: list, DataType: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeParameters")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "ParameterFilters": $parameter_filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the patch baselines in your Amazon Web Services account.
#
# POST /
# operationId: DescribePatchBaselines
export def "describe-patch-baselines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55 # required
  --filters: list # Each element in the array is a structure containing a key-value pair. Supported keys for DescribePatchBaselines include the following: NAME_PREFIX Sample values: AWS- | My- OWNER Sample values: AWS | Self OPERATING_SYSTEM Sample values: AMAZON_LINUX | SUSE | WINDOWS — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of patch baselines to return (per page). (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<BaselineIdentities: table<BaselineId: string, BaselineName: string, OperatingSystem: string, BaselineDescription: string, DefaultBaseline: bool>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribePatchBaselines")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns high-level aggregated patch compliance state information for a patch group.
#
# POST /
# operationId: DescribePatchGroupState
export def "describe-patch-group-state" [
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
  patch_group: string # The name of the patch group whose patch snapshot should be retrieved.
]: any -> oneof<record<Instances: int, InstancesWithInstalledPatches: int, InstancesWithInstalledOtherPatches: int, InstancesWithInstalledPendingRebootPatches: int, InstancesWithInstalledRejectedPatches: int, InstancesWithMissingPatches: int, InstancesWithFailedPatches: int, InstancesWithNotApplicablePatches: int, InstancesWithUnreportedNotApplicablePatches: int, InstancesWithCriticalNonCompliantPatches: int, InstancesWithSecurityNonCompliantPatches: int, InstancesWithOtherNonCompliantPatches: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribePatchGroupState")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PatchGroup": $patch_group} | compact
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

# Lists all patch groups that have been registered with patch baselines.
#
# POST /
# operationId: DescribePatchGroups
export def "describe-patch-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57 # required
  --body-max-results: int # The maximum number of patch groups to return (per page). (spec name: MaxResults)
  --filters: list # Each element in the array is a structure containing a key-value pair. Supported keys for DescribePatchGroups include the following: NAME_PREFIX Sample values: AWS- | My-. OPERATING_SYSTEM Sample values: AMAZON_LINUX | SUSE | WINDOWS — item shape: {Key?: string, Values?: list<string>}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Mappings: table<PatchGroup: string, BaselineIdentity: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribePatchGroups")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"MaxResults": $body_max_results, "Filters": $filters, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for operations such as CreatePatchBaseline, UpdatePatchBaseline, DescribeAvailablePatches, and DescribePatchBaselines. The following section lists the properties that can be used in filters for each major operating system type: AMAZON_LINUX Valid properties: PRODUCT | CLASSIFICATION | SEVERITY AMAZON_LINUX_2 Valid properties: PRODUCT | CLASSIFICATION | SEVERITY CENTOS Valid properties: PRODUCT | CLASSIFICATION | SEVERITY DEBIAN Valid properties: PRODUCT | PRIORITY MACOS Valid properties: PRODUCT | CLASSIFICATION ORACLE_LINUX Valid properties: PRODUCT | CLASSIFICATION | SEVERITY REDHAT_ENTERPRISE_LINUX Valid properties: PRODUCT | CLASSIFICATION | SEVERITY SUSE Valid properties: PRODUCT | CLASSIFICATION | SEVERITY UBUNTU Valid properties: PRODUCT | PRIORITY WINDOWS Valid properties: PRODUCT | PRODUCT_FAMILY | CLASSIFICATION | MSRC_SEVERITY
#
# POST /
# operationId: DescribePatchProperties
export def "describe-patch-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-58 # required
  operating_system: string@operating-system-completer # The operating system type for which to list patches.
  property: string@property-completer # The patch property for which you want to view patch details.
  --patch-set: string@patch-set-completer # Indicates whether to list patches for the Windows operating system or for applications released by Microsoft. Not applicable for the Linux or macOS operating systems.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Properties: list<record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribePatchProperties")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OperatingSystem": $operating_system, "Property": $property, "PatchSet": $patch_set, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
#
# POST /
# operationId: DescribeSessions
export def "describe-sessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-59 # required
  state: string@state-completer # The session status to retrieve a list of sessions for. For example, "Active".
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --filters: list # One or more filters to limit the type of sessions returned by the request. — item shape: {key: "InvokedAfter"|"InvokedBefore"|"Target"|"Owner"|"Status"|"SessionId", value: string}
]: any -> oneof<record<Sessions: table<SessionId: string, Target: string, Status: string, StartDate: string, EndDate: string, DocumentName: string, Owner: string, Reason: string, Details: string, OutputUrl: record, MaxSessionDuration: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DescribeSessions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"State": $state, "MaxResults": $body_max_results, "NextToken": $body_next_token, "Filters": $filters} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Deletes the association between an OpsItem and a related item. For example, this API operation can delete an Incident Manager incident from an OpsItem. Incident Manager is a capability of Amazon Web Services Systems Manager.
#
# POST /
# operationId: DisassociateOpsItemRelatedItem
export def "disassociate-ops-item-related-item" [
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
  ops_item_id: string # The ID of the OpsItem for which you want to delete an association between the OpsItem and a related item.
  association_id: string # The ID of the association for which you want to delete an association between the OpsItem and a related item.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.DisassociateOpsItemRelatedItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OpsItemId": $ops_item_id, "AssociationId": $association_id} | compact
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

# Get detailed information about a particular Automation execution.
#
# POST /
# operationId: GetAutomationExecution
export def "get-automation-execution" [
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
  automation_execution_id: string # The unique identifier for an existing automation execution to examine. The execution ID is returned by StartAutomationExecution when the execution of an Automation runbook is initiated.
]: any -> oneof<record<AutomationExecution: record<AutomationExecutionId: string, DocumentName: string, DocumentVersion: string, ExecutionStartTime: string, ExecutionEndTime: string, AutomationExecutionStatus: string, StepExecutions: list<record>, StepExecutionsTruncated: bool, Parameters: record, Outputs: record, FailureMessage: string, Mode: string, ParentAutomationExecutionId: string, ExecutedBy: string, CurrentStepName: string, CurrentAction: string, TargetParameterName: string, Targets: list<record>, TargetMaps: list<record>, ResolvedTargets: record<ParameterValues: list, Truncated: bool>, MaxConcurrency: string, MaxErrors: string, Target: string, TargetLocations: list<record>, ProgressCounters: record<TotalSteps: int, SuccessSteps: int, FailedSteps: int, CancelledSteps: int, TimedOutSteps: int>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>, AutomationSubtype: string, ScheduledTime: string, Runbooks: list<record>, OpsItemId: string, AssociationId: string, ChangeRequestName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetAutomationExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AutomationExecutionId": $automation_execution_id} | compact
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

# Gets the state of a Amazon Web Services Systems Manager change calendar at the current time or a specified time. If you specify a time, GetCalendarState returns the state of the calendar at that specific time, and returns the next time that the change calendar state will transition. If you don't specify a time, GetCalendarState uses the current time. Change Calendar entries have two possible states: OPEN or CLOSED. If you specify more than one calendar in a request, the command returns the status of OPEN only if all calendars in the request are open. If one or more calendars in the request are closed, the status returned is CLOSED. For more information about Change Calendar, a capability of Amazon Web Services Systems Manager, see Amazon Web Services Systems Manager Change Calendar (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# operationId: GetCalendarState
export def "get-calendar-state" [
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
  calendar_names: list<string> # The names or Amazon Resource Names (ARNs) of the Systems Manager documents (SSM documents) that represent the calendar entries for which you want to get the state.
  --at-time: string # (Optional) The specific time for which you want to get calendar state information, in ISO 8601 (https://en.wikipedia.org/wiki/ISO_8601) format. If you don't specify a value or AtTime, the current time is used.
]: any -> oneof<record<State: string, AtTime: string, NextTransitionTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetCalendarState")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CalendarNames": $calendar_names, "AtTime": $at_time} | compact
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

# Returns detailed information about command execution for an invocation or plugin. GetCommandInvocation only gives the execution status of a plugin in a document. To get the command execution status on a specific managed node, use ListCommandInvocations. To get the command execution status across managed nodes, use ListCommands.
#
# POST /
# operationId: GetCommandInvocation
export def "get-command-invocation" [
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
  command_id: string # (Required) The parent command ID of the invocation plugin.
  instance_id: string # (Required) The ID of the managed node targeted by the command. A managed node can be an Amazon Elastic Compute Cloud (Amazon EC2) instance, edge device, and on-premises server or VM in your hybrid environment that is configured for Amazon Web Services Systems Manager.
  --plugin-name: string # The name of the step for which you want detailed results. If the document contains only one step, you can omit the name and details for that step. If the document contains more than one step, you must specify the name of the step for which you want to view details. Be sure to specify the name of the step, not the name of a plugin like aws:RunShellScript. To find the PluginName, check the document content and find the name of the step you want details for. Alternatively, use ListCommandInvocations with the CommandId and Details parameters. The PluginName is the Name attribute of the CommandPlugin object in the CommandPlugins list.
]: any -> oneof<record<CommandId: string, InstanceId: string, Comment: string, DocumentName: string, DocumentVersion: string, PluginName: string, ResponseCode: int, ExecutionStartDateTime: string, ExecutionElapsedTime: string, ExecutionEndDateTime: string, Status: string, StatusDetails: string, StandardOutputContent: string, StandardOutputUrl: string, StandardErrorContent: string, StandardErrorUrl: string, CloudWatchOutputConfig: record<CloudWatchLogGroupName: string, CloudWatchOutputEnabled: bool>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetCommandInvocation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"CommandId": $command_id, "InstanceId": $instance_id, "PluginName": $plugin_name} | compact
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

# Retrieves the Session Manager connection status for a managed node to determine whether it is running and ready to receive Session Manager connections.
#
# POST /
# operationId: GetConnectionStatus
export def "get-connection-status" [
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
  target: string # The managed node ID.
]: any -> oneof<record<Target: string, Status: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetConnectionStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Target": $target} | compact
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

# Retrieves the default patch baseline. Amazon Web Services Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system. If you don't specify an operating system value, the default patch baseline for Windows is returned.
#
# POST /
# operationId: GetDefaultPatchBaseline
export def "get-default-patch-baseline" [
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
  --x-amz-target: string@x-amz-target-completer-65 # required
  --operating-system: string@operating-system-completer # Returns the default patch baseline for the specified operating system.
]: any -> oneof<record<BaselineId: string, OperatingSystem: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetDefaultPatchBaseline")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OperatingSystem": $operating_system} | compact
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

# Retrieves the current snapshot for the patch baseline the managed node uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document (SSM document). If you run the command locally, such as with the Command Line Interface (CLI), the system attempts to use your local Amazon Web Services credentials and the operation fails. To avoid this, you can run the command in the Amazon Web Services Systems Manager console. Use Run Command, a capability of Amazon Web Services Systems Manager, with an SSM document that enables you to target a managed node with a script or command. For example, run the command using the AWS-RunShellScript document or the AWS-RunPowerShellScript document.
#
# POST /
# operationId: GetDeployablePatchSnapshotForInstance
export def "get-deployable-patch-snapshot-for-instance" [
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
  --x-amz-target: string@x-amz-target-completer-66 # required
  instance_id: string # The ID of the managed node for which the appropriate patch snapshot should be retrieved.
  snapshot_id: string # The snapshot ID provided by the user when running AWS-RunPatchBaseline.
  --baseline-override: record # Defines the basic information about a patch baseline override. — shape: {OperatingSystem?: "WINDOWS"|"AMAZON_LINUX"|"AMAZON_LINUX_2"|"AMAZON_LINUX_2022"|"UBUNTU"|"REDHAT_ENTERPRISE_LINUX"|"SUSE"|"CENTOS"|"ORACLE_LINUX"|"DEBIAN"|"MACOS"|"RASPBIAN"|"ROCKY_LINUX"|"ALMA_LINUX"|"AMAZON_LINUX_2023", GlobalFilters?: record, ApprovalRules?: record, ApprovedPatches?: list<string>, ApprovedPatchesComplianceLevel?: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW"|"INFORMATIONAL"|"UNSPECIFIED", RejectedPatches?: list<string>, RejectedPatchesAction?: "ALLOW_AS_DEPENDENCY"|"BLOCK", ... (2 more fields)}
]: any -> oneof<record<InstanceId: string, SnapshotId: string, SnapshotDownloadUrl: string, Product: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetDeployablePatchSnapshotForInstance")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"InstanceId": $instance_id, "SnapshotId": $snapshot_id, "BaselineOverride": $baseline_override} | compact
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

# Gets the contents of the specified Amazon Web Services Systems Manager document (SSM document).
#
# POST /
# operationId: GetDocument
export def "get-document" [
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
  --x-amz-target: string@x-amz-target-completer-67 # required
  name: string # The name of the SSM document.
  --version-name: string # An optional field specifying the version of the artifact associated with the document. For example, "Release 12, Update 6". This value is unique across all versions of a document and can't be changed.
  --document-version: string # The document version for which you want information.
  --document-format: string@document-format-completer # Returns the document in the specified format. The document format can be either JSON or YAML. JSON is the default format.
]: any -> oneof<record<Name: string, CreatedDate: string, DisplayName: string, VersionName: string, DocumentVersion: string, Status: string, StatusInformation: string, Content: string, DocumentType: string, DocumentFormat: string, Requires: table<Name: string, Version: string, RequireType: string, VersionName: string>, AttachmentsContent: table<Name: string, Size: int, Hash: string, HashType: string, Url: string>, ReviewStatus: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetDocument")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "VersionName": $version_name, "DocumentVersion": $document_version, "DocumentFormat": $document_format} | compact
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

# Query inventory information. This includes managed node status, such as Stopped or Terminated.
#
# POST /
# operationId: GetInventory
export def "get-inventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68 # required
  --filters: list # One or more filters. Use a filter to return a more specific list of results. — item shape: {Key: string, Values: list<string>, Type?: "Equal"|"NotEqual"|"BeginWith"|"LessThan"|"GreaterThan"|"Exists"}
  --aggregators: list # Returns counts of inventory types based on one or more expressions. For example, if you aggregate by using an expression that uses the AWS:InstanceInformation.PlatformType type, you can see a count of how many Windows and Linux managed nodes exist in your inventoried fleet. — item shape: {Expression?: string, Aggregators?: list, Groups?: list}
  --result-attributes: list # The list of inventory item types to return. — item shape: {TypeName: string}
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record<Entities: table<Id: string, Data: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetInventory")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "Aggregators": $aggregators, "ResultAttributes": $result_attributes, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type.
#
# POST /
# operationId: GetInventorySchema
export def "get-inventory-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-69 # required
  --type-name: string # The type of inventory item to return.
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --aggregator: oneof<nothing, bool> # Returns inventory schemas that support aggregation. For example, this call returns the AWS:InstanceInformation type, because it supports aggregation based on the PlatformName, PlatformType, and PlatformVersion attributes.
  --sub-type: oneof<nothing, bool> # Returns the sub-type schema for a specified inventory type.
]: any -> oneof<record<Schemas: table<TypeName: string, Version: string, Attributes: list, DisplayName: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetInventorySchema")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"TypeName": $type_name, "NextToken": $body_next_token, "MaxResults": $body_max_results, "Aggregator": $aggregator, "SubType": $sub_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves a maintenance window.
#
# POST /
# operationId: GetMaintenanceWindow
export def "get-maintenance-window" [
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
  --x-amz-target: string@x-amz-target-completer-70 # required
  window_id: string # The ID of the maintenance window for which you want to retrieve information.
]: any -> oneof<record<WindowId: string, Name: string, Description: string, StartDate: string, EndDate: string, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, NextExecutionTime: string, Duration: int, Cutoff: int, AllowUnassociatedTargets: bool, Enabled: bool, CreatedDate: string, ModifiedDate: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetMaintenanceWindow")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id} | compact
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

# Retrieves details about a specific a maintenance window execution.
#
# POST /
# operationId: GetMaintenanceWindowExecution
export def "get-maintenance-window-execution" [
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
  --x-amz-target: string@x-amz-target-completer-71 # required
  window_execution_id: string # The ID of the maintenance window execution that includes the task.
]: any -> oneof<record<WindowExecutionId: string, TaskIds: list<string>, Status: string, StatusDetails: string, StartTime: string, EndTime: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetMaintenanceWindowExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowExecutionId": $window_execution_id} | compact
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

# Retrieves the details about a specific task run as part of a maintenance window execution.
#
# POST /
# operationId: GetMaintenanceWindowExecutionTask
export def "get-maintenance-window-execution-task" [
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
  --x-amz-target: string@x-amz-target-completer-72 # required
  window_execution_id: string # The ID of the maintenance window execution that includes the task.
  task_id: string # The ID of the specific task execution in the maintenance window task that should be retrieved.
]: any -> oneof<record<WindowExecutionId: string, TaskExecutionId: string, TaskArn: string, ServiceRole: string, Type: string, TaskParameters: list<record>, Priority: int, MaxConcurrency: string, MaxErrors: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>, TriggeredAlarms: table<Name: string, State: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetMaintenanceWindowExecutionTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowExecutionId": $window_execution_id, "TaskId": $task_id} | compact
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

# Retrieves information about a specific task running on a specific target.
#
# POST /
# operationId: GetMaintenanceWindowExecutionTaskInvocation
export def "get-maintenance-window-execution-task-invocation" [
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
  window_execution_id: string # The ID of the maintenance window execution for which the task is a part.
  task_id: string # The ID of the specific task in the maintenance window task that should be retrieved.
  invocation_id: string # The invocation ID to retrieve.
]: any -> oneof<record<WindowExecutionId: string, TaskExecutionId: string, InvocationId: string, ExecutionId: string, TaskType: string, Parameters: string, Status: string, StatusDetails: string, StartTime: string, EndTime: string, OwnerInformation: string, WindowTargetId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowExecutionId": $window_execution_id, "TaskId": $task_id, "InvocationId": $invocation_id} | compact
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

# Retrieves the details of a maintenance window task. For maintenance window tasks without a specified target, you can't supply values for --max-errors and --max-concurrency. Instead, the system inserts a placeholder value of 1, which may be reported in the response to this command. These values don't affect the running of your task and can be ignored. To retrieve a list of tasks in a maintenance window, instead use the DescribeMaintenanceWindowTasks command.
#
# POST /
# operationId: GetMaintenanceWindowTask
export def "get-maintenance-window-task" [
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
  window_id: string # The maintenance window ID that includes the task to retrieve.
  window_task_id: string # The maintenance window task ID to retrieve.
]: any -> oneof<record<WindowId: string, WindowTaskId: string, Targets: table<Key: string, Values: list>, TaskArn: string, ServiceRoleArn: string, TaskType: string, TaskParameters: record, TaskInvocationParameters: record<RunCommand: record<Comment: string, CloudWatchOutputConfig: record, DocumentHash: string, DocumentHashType: string, DocumentVersion: string, NotificationConfig: record, OutputS3BucketName: string, OutputS3KeyPrefix: string, Parameters: record, ServiceRoleArn: string, TimeoutSeconds: int>, Automation: record<DocumentVersion: string, Parameters: record>, StepFunctions: record<Input: string, Name: string>, Lambda: record<ClientContext: string, Qualifier: string, Payload: string>>, Priority: int, MaxConcurrency: string, MaxErrors: string, LoggingInfo: record<S3BucketName: string, S3KeyPrefix: string, S3Region: string>, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetMaintenanceWindowTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id, "WindowTaskId": $window_task_id} | compact
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

# Get information about an OpsItem by using the ID. You must have permission in Identity and Access Management (IAM) to view information about an OpsItem. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html) in the Amazon Web Services Systems Manager User Guide. Operations engineers and IT professionals use Amazon Web Services Systems Manager OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their Amazon Web Services resources. For more information, see OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# operationId: GetOpsItem
export def "get-ops-item" [
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
  ops_item_id: string # The ID of the OpsItem that you want to get.
  --ops-item-arn: string # The OpsItem Amazon Resource Name (ARN).
]: any -> oneof<record<OpsItem: record<CreatedBy: string, OpsItemType: string, CreatedTime: string, Description: string, LastModifiedBy: string, LastModifiedTime: string, Notifications: list<record>, Priority: int, RelatedOpsItems: list<record>, Status: string, OpsItemId: string, Version: string, Title: string, Source: string, OperationalData: record, Category: string, Severity: string, ActualStartTime: string, ActualEndTime: string, PlannedStartTime: string, PlannedEndTime: string, OpsItemArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetOpsItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OpsItemId": $ops_item_id, "OpsItemArn": $ops_item_arn} | compact
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

# View operational metadata related to an application in Application Manager.
#
# POST /
# operationId: GetOpsMetadata
export def "get-ops-metadata" [
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
  ops_metadata_arn: string # The Amazon Resource Name (ARN) of an OpsMetadata Object to view.
  --max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
  --next-token: string # A token to start the list. Use this token to get the next set of results.
]: any -> oneof<record<ResourceId: string, Metadata: record, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetOpsMetadata")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OpsMetadataArn": $ops_metadata_arn, "MaxResults": $max_results, "NextToken": $next_token} | compact
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

# View a summary of operations metadata (OpsData) based on specified filters and aggregators. OpsData can include information about Amazon Web Services Systems Manager OpsCenter operational workitems (OpsItems) as well as information about any Amazon Web Services resource or service configured to report OpsData to Amazon Web Services Systems Manager Explorer.
#
# POST /
# operationId: GetOpsSummary
export def "get-ops-summary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-77 # required
  --sync-name: string # Specify the name of a resource data sync to get.
  --filters: list # Optional filters used to scope down the returned OpsData. — item shape: {Key: string, Values: list<string>, Type?: "Equal"|"NotEqual"|"BeginWith"|"LessThan"|"GreaterThan"|"Exists"}
  --aggregators: list # Optional aggregators that return counts of OpsData based on one or more expressions. — item shape: {AggregatorType?: string, TypeName?: string, AttributeName?: string, Values?: record, Filters?: list, Aggregators?: list}
  --result-attributes: list # The OpsData data type to return. — item shape: {TypeName: string}
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record<Entities: table<Id: string, Data: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetOpsSummary")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"SyncName": $sync_name, "Filters": $filters, "Aggregators": $aggregators, "ResultAttributes": $result_attributes, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get information about a single parameter by specifying the parameter name. To get information about more than one parameter at a time, use the GetParameters operation.
#
# POST /
# operationId: GetParameter
export def "get-parameter" [
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
  name: string # The name of the parameter you want to query. To query by parameter label, use "Name": "name:label". To query by parameter version, use "Name": "name:version".
  --with-decryption: oneof<nothing, bool> # Return decrypted values for secure string parameters. This flag is ignored for String and StringList parameter types.
]: any -> oneof<record<Parameter: record<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetParameter")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "WithDecryption": $with_decryption} | compact
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

# Retrieves the history of all changes to a parameter. If you change the KMS key alias for the KMS key used to encrypt a parameter, then you must also update the key alias the parameter uses to reference KMS. Otherwise, GetParameterHistory retrieves whatever the original key alias was referencing.
#
# POST /
# operationId: GetParameterHistory
export def "get-parameter-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-79 # required
  name: string # The name of the parameter for which you want to review history.
  --with-decryption: oneof<nothing, bool> # Return decrypted values for secure string parameters. This flag is ignored for String and StringList parameter types.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Parameters: table<Name: string, Type: string, KeyId: string, LastModifiedDate: string, LastModifiedUser: string, Description: string, Value: string, AllowedPattern: string, Version: int, Labels: list, Tier: string, Policies: list, DataType: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetParameterHistory")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Name": $name, "WithDecryption": $with_decryption, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get information about one or more parameters by specifying multiple parameter names. To get information about a single parameter, you can use the GetParameter operation instead.
#
# POST /
# operationId: GetParameters
export def "get-parameters" [
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
  --x-amz-target: string@x-amz-target-completer-80 # required
  names: list<string> # Names of the parameters for which you want to query information. To query by parameter label, use "Name": "name:label". To query by parameter version, use "Name": "name:version".
  --with-decryption: oneof<nothing, bool> # Return decrypted secure string value. Return decrypted values for secure string parameters. This flag is ignored for String and StringList parameter types.
]: any -> oneof<record<Parameters: table<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>, InvalidParameters: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetParameters")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Names": $names, "WithDecryption": $with_decryption} | compact
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

# Retrieve information about one or more parameters in a specific hierarchy. Request results are returned on a best-effort basis. If you specify MaxResults in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of MaxResults. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a NextToken. You can specify the NextToken in a subsequent call to get the next set of results.
#
# POST /
# operationId: GetParametersByPath
export def "get-parameters-by-path" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-81 # required
  path: string # The hierarchy for the parameter. Hierarchies start with a forward slash (/). The hierarchy is the parameter name except the last part of the parameter. For the API call to succeed, the last part of the parameter name can't be in the path. A parameter name hierarchy can have a maximum of 15 levels. Here is an example of a hierarchy: /Finance/Prod/IAD/WinServ2016/license33
  --recursive: oneof<nothing, bool> # Retrieve all parameters within a hierarchy. If a user has access to a path, then the user can access all levels of that path. For example, if a user has permission to access path /a, then the user can also access /a/b. Even if a user has explicitly been denied access in IAM for parameter /a/b, they can still call the GetParametersByPath API operation recursively for /a and view /a/b.
  --parameter-filters: list # Filters to limit the request results. The following Key values are supported for GetParametersByPath: Type, KeyId, and Label. The following Key values aren't supported for GetParametersByPath: tag, DataType, Name, Path, and Tier. — item shape: {Key: string, Option?: string, Values?: list<string>}
  --with-decryption: oneof<nothing, bool> # Retrieve all parameters in a hierarchy with their value decrypted.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record<Parameters: table<Name: string, Type: string, Value: string, Version: int, Selector: string, SourceResult: string, LastModifiedDate: string, ARN: string, DataType: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetParametersByPath")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Path": $path, "Recursive": $recursive, "ParameterFilters": $parameter_filters, "WithDecryption": $with_decryption, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieves information about a patch baseline.
#
# POST /
# operationId: GetPatchBaseline
export def "get-patch-baseline" [
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
  baseline_id: string # The ID of the patch baseline to retrieve. To retrieve information about an Amazon Web Services managed patch baseline, specify the full Amazon Resource Name (ARN) of the baseline. For example, for the baseline AWS-AmazonLinuxDefaultPatchBaseline, specify arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0e392de35e7c563b7 instead of pb-0e392de35e7c563b7.
]: any -> oneof<record<BaselineId: string, Name: string, OperatingSystem: string, GlobalFilters: record<PatchFilters: list<record>>, ApprovalRules: record<PatchRules: list<record>>, ApprovedPatches: list<string>, ApprovedPatchesComplianceLevel: string, ApprovedPatchesEnableNonSecurity: bool, RejectedPatches: list<string>, RejectedPatchesAction: string, PatchGroups: list<string>, CreatedDate: string, ModifiedDate: string, Description: string, Sources: table<Name: string, Products: list, Configuration: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetPatchBaseline")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BaselineId": $baseline_id} | compact
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

# Retrieves the patch baseline that should be used for the specified patch group.
#
# POST /
# operationId: GetPatchBaselineForPatchGroup
export def "get-patch-baseline-for-patch-group" [
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
  patch_group: string # The name of the patch group whose patch baseline should be retrieved.
  --operating-system: string@operating-system-completer # Returns the operating system rule specified for patch groups using the patch baseline.
]: any -> oneof<record<BaselineId: string, PatchGroup: string, OperatingSystem: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetPatchBaselineForPatchGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"PatchGroup": $patch_group, "OperatingSystem": $operating_system} | compact
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

# Returns an array of the Policy object.
#
# POST /
# operationId: GetResourcePolicies
export def "get-resource-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-84 # required
  resource_arn: string # Amazon Resource Name (ARN) of the resource to which the policies are attached.
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record<NextToken: string, Policies: table<PolicyId: string, PolicyHash: string, Policy: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetResourcePolicies")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# ServiceSetting is an account-level setting for an Amazon Web Services service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an Amazon Web Services service charges money to the account based on feature or service usage, then the Amazon Web Services service team might create a default setting of false. This means the user can't use this feature unless they change the setting to true and intentionally opt in for a paid feature. Services map a SettingId object to a setting value. Amazon Web Services services teams define the default value for a SettingId. You can't create a new SettingId, but you can overwrite the default value if you have the ssm:UpdateServiceSetting permission for the setting. Use the UpdateServiceSetting API operation to change the default setting. Or use the ResetServiceSetting to change the value back to the original value defined by the Amazon Web Services service team. Query the current service setting for the Amazon Web Services account.
#
# POST /
# operationId: GetServiceSetting
export def "get-service-setting" [
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
  setting_id: string # The ID of the service setting to get. The setting ID can be one of the following. /ssm/managed-instance/default-ec2-instance-management-role /ssm/automation/customer-script-log-destination /ssm/automation/customer-script-log-group-name /ssm/documents/console/public-sharing-permission /ssm/managed-instance/activation-tier /ssm/opsinsights/opscenter /ssm/parameter-store/default-parameter-tier /ssm/parameter-store/high-throughput-enabled
]: any -> oneof<record<ServiceSetting: record<SettingId: string, SettingValue: string, LastModifiedDate: string, LastModifiedUser: string, ARN: string, Status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.GetServiceSetting")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SettingId": $setting_id} | compact
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

# A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Amazon Web Services Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. Parameter labels have the following requirements and restrictions. A version of a parameter can have a maximum of 10 labels. You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2. You can move a label from one version of a parameter to another. You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter. If you no longer want to use a parameter label, then you can either delete it or move it to a different version of a parameter. A label can have a maximum of 100 characters. Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_). Labels can't begin with a number, "aws" or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label isn't associated with a parameter and the system displays it in the list of InvalidLabels.
#
# POST /
# operationId: LabelParameterVersion
export def "label-parameter-version" [
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
  name: string # The parameter name on which you want to attach one or more labels.
  --parameter-version: int # The specific version of the parameter on which you want to attach one or more labels. If no version is specified, the system attaches the label to the latest version.
  labels: list<string> # One or more labels to attach to the specified parameter version.
]: any -> oneof<record<InvalidLabels: list<string>, ParameterVersion: int>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.LabelParameterVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ParameterVersion": $parameter_version, "Labels": $labels} | compact
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

# Retrieves all versions of an association for a specific association ID.
#
# POST /
# operationId: ListAssociationVersions
export def "list-association-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-87 # required
  association_id: string # The association ID for which you want to view all versions.
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record<AssociationVersions: table<AssociationId: string, AssociationVersion: string, CreatedDate: string, Name: string, DocumentVersion: string, Parameters: record, Targets: list, ScheduleExpression: string, OutputLocation: record, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list, TargetLocations: list, ScheduleOffset: int, TargetMaps: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListAssociationVersions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AssociationId": $association_id, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all State Manager associations in the current Amazon Web Services account and Amazon Web Services Region. You can limit the results to a specific State Manager association document or managed node by specifying a filter. State Manager is a capability of Amazon Web Services Systems Manager.
#
# POST /
# operationId: ListAssociations
export def "list-associations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-88 # required
  --association-filter-list: list # One or more filters. Use a filter to return a more specific list of results. Filtering associations using the InstanceID attribute only returns legacy associations created using the InstanceID attribute. Associations targeting the managed node that are part of the Target Attributes ResourceGroup or Tags aren't returned. — item shape: {key: "InstanceId"|"Name"|"AssociationId"|"AssociationStatusName"|"LastExecutedBefore"|"LastExecutedAfter"|"AssociationName"|"ResourceGroupName", value: string}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<Associations: table<Name: string, InstanceId: string, AssociationId: string, AssociationVersion: string, DocumentVersion: string, Targets: list, LastExecutionDate: string, Overview: record, ScheduleExpression: string, AssociationName: string, ScheduleOffset: int, TargetMaps: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListAssociations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"AssociationFilterList": $association_filter_list, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# An invocation is copy of a command sent to a specific managed node. A command can apply to one or more managed nodes. A command invocation applies to one managed node. For example, if a user runs SendCommand against three managed nodes, then a command invocation is created for each requested managed node ID. ListCommandInvocations provide status about command execution.
#
# POST /
# operationId: ListCommandInvocations
export def "list-command-invocations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-89 # required
  --command-id: string # (Optional) The invocations for a specific command ID.
  --instance-id: string # (Optional) The command execution details for a specific managed node ID.
  --body-max-results: int # (Optional) The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # (Optional) The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --filters: list # (Optional) One or more filters. Use a filter to return a more specific list of results. — item shape: {key: "InvokedAfter"|"InvokedBefore"|"Status"|"ExecutionStage"|"DocumentName", value: string}
  --details: oneof<nothing, bool> # (Optional) If set this returns the response of the command executions and any command output. The default value is false.
]: any -> oneof<record<CommandInvocations: table<CommandId: string, InstanceId: string, InstanceName: string, Comment: string, DocumentName: string, DocumentVersion: string, RequestedDateTime: string, Status: string, StatusDetails: string, TraceOutput: string, StandardOutputUrl: string, StandardErrorUrl: string, CommandPlugins: list, ServiceRole: string, NotificationConfig: record, CloudWatchOutputConfig: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListCommandInvocations")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"CommandId": $command_id, "InstanceId": $instance_id, "MaxResults": $body_max_results, "NextToken": $body_next_token, "Filters": $filters, "Details": $details} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists the commands requested by users of the Amazon Web Services account.
#
# POST /
# operationId: ListCommands
export def "list-commands" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-90 # required
  --command-id: string # (Optional) If provided, lists only the specified command.
  --instance-id: string # (Optional) Lists commands issued against this managed node ID. You can't specify a managed node ID in the same command that you specify Status = Pending. This is because the command hasn't reached the managed node yet.
  --body-max-results: int # (Optional) The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # (Optional) The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
  --filters: list # (Optional) One or more filters. Use a filter to return a more specific list of results. — item shape: {key: "InvokedAfter"|"InvokedBefore"|"Status"|"ExecutionStage"|"DocumentName", value: string}
]: any -> oneof<record<Commands: table<CommandId: string, DocumentName: string, DocumentVersion: string, Comment: string, ExpiresAfter: string, Parameters: record, InstanceIds: list, Targets: list, RequestedDateTime: string, Status: string, StatusDetails: string, OutputS3Region: string, OutputS3BucketName: string, OutputS3KeyPrefix: string, MaxConcurrency: string, MaxErrors: string, TargetCount: int, CompletedCount: int, ErrorCount: int, DeliveryTimedOutCount: int, ServiceRole: string, NotificationConfig: record, CloudWatchOutputConfig: record, TimeoutSeconds: int, AlarmConfiguration: record, TriggeredAlarms: list>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListCommands")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"CommandId": $command_id, "InstanceId": $instance_id, "MaxResults": $body_max_results, "NextToken": $body_next_token, "Filters": $filters} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# For a specified resource ID, this API operation returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter.
#
# POST /
# operationId: ListComplianceItems
export def "list-compliance-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-91 # required
  --filters: list # One or more compliance filters. Use a filter to return a more specific list of results. — item shape: {Key?: string, Values?: list<string>, Type?: "EQUAL"|"NOT_EQUAL"|"BEGIN_WITH"|"LESS_THAN"|"GREATER_THAN"}
  --resource-ids: list<string> # The ID for the resources from which to get compliance information. Currently, you can only specify one resource ID.
  --resource-types: list<string> # The type of resource from which to get compliance information. Currently, the only supported resource type is ManagedInstance.
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record<ComplianceItems: table<ComplianceType: string, ResourceType: string, ResourceId: string, Id: string, Title: string, Status: string, Severity: string, ExecutionSummary: record, Details: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListComplianceItems")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "ResourceIds": $resource_ids, "ResourceTypes": $resource_types, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify.
#
# POST /
# operationId: ListComplianceSummaries
export def "list-compliance-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-92 # required
  --filters: list # One or more compliance or inventory filters. Use a filter to return a more specific list of results. — item shape: {Key?: string, Values?: list<string>, Type?: "EQUAL"|"NOT_EQUAL"|"BEGIN_WITH"|"LESS_THAN"|"GREATER_THAN"}
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. Currently, you can specify null or 50. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record<ComplianceSummaryItems: table<ComplianceType: string, CompliantSummary: record, NonCompliantSummary: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListComplianceSummaries")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Information about approval reviews for a version of a change template in Change Manager.
#
# POST /
# operationId: ListDocumentMetadataHistory
export def "list-document-metadata-history" [
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
  name: string # The name of the change template.
  --document-version: string # The version of the change template.
  metadata: string@metadata-completer # The type of data for which details are being requested. Currently, the only supported value is DocumentReviews.
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
]: any -> oneof<record<Name: string, DocumentVersion: string, Author: string, Metadata: record<ReviewerResponse: list<record>>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListDocumentMetadataHistory")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "DocumentVersion": $document_version, "Metadata": $metadata, "NextToken": $next_token, "MaxResults": $max_results} | compact
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

# List all versions for a document.
#
# POST /
# operationId: ListDocumentVersions
export def "list-document-versions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-94 # required
  name: string # The name of the document. You can specify an Amazon Resource Name (ARN).
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<DocumentVersions: table<Name: string, DisplayName: string, DocumentVersion: string, VersionName: string, CreatedDate: string, IsDefaultVersion: bool, DocumentFormat: string, Status: string, StatusInformation: string, ReviewStatus: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListDocumentVersions")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Name": $name, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all Systems Manager (SSM) documents in the current Amazon Web Services account and Amazon Web Services Region. You can limit the results of this request by using a filter.
#
# POST /
# operationId: ListDocuments
export def "list-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-95 # required
  --document-filter-list: list # This data type is deprecated. Instead, use Filters. — item shape: {key: "Name"|"Owner"|"PlatformTypes"|"DocumentType", value: string}
  --filters: list # One or more DocumentKeyValuesFilter objects. Use a filter to return a more specific list of results. For keys, you can specify one or more key-value pair tags that have been applied to a document. Other valid keys include Owner, Name, PlatformTypes, DocumentType, and TargetType. For example, to return documents you own use Key=Owner,Values=Self. To specify a custom key-value pair, use the format Key=tag:tagName,Values=valueName. This API operation only supports filtering documents by using a single tag key and one or more tag values. For example: Key=tag:tagName,Values=valueName1,valueName2 — item shape: {Key?: string, Values?: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<DocumentIdentifiers: table<Name: string, CreatedDate: string, DisplayName: string, Owner: string, VersionName: string, PlatformTypes: list, DocumentVersion: string, DocumentType: string, SchemaVersion: string, DocumentFormat: string, TargetType: string, Tags: list, Requires: list, ReviewStatus: string, Author: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListDocuments")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"DocumentFilterList": $document_filter_list, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# A list of inventory items returned by the request.
#
# POST /
# operationId: ListInventoryEntries
export def "list-inventory-entries" [
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
  instance_id: string # The managed node ID for which you want inventory information.
  type_name: string # The type of inventory item for which you want information.
  --filters: list # One or more filters. Use a filter to return a more specific list of results. — item shape: {Key: string, Values: list<string>, Type?: "Equal"|"NotEqual"|"BeginWith"|"LessThan"|"GreaterThan"|"Exists"}
  --next-token: string # The token for the next set of items to return. (You received this token from a previous call.)
  --max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results.
]: any -> oneof<record<TypeName: string, InstanceId: string, SchemaVersion: string, CaptureTime: string, Entries: list<record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListInventoryEntries")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"InstanceId": $instance_id, "TypeName": $type_name, "Filters": $filters, "NextToken": $next_token, "MaxResults": $max_results} | compact
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

# Returns a list of all OpsItem events in the current Amazon Web Services Region and Amazon Web Services account. You can limit the results to events associated with specific OpsItems by specifying a filter.
#
# POST /
# operationId: ListOpsItemEvents
export def "list-ops-item-events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-97 # required
  --filters: list # One or more OpsItem filters. Use a filter to return a more specific list of results. — item shape: {Key: "OpsItemId", Values: list<string>, Operator: "Equal"}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record<NextToken: string, Summaries: table<OpsItemId: string, EventId: string, Source: string, DetailType: string, Detail: string, CreatedBy: record, CreatedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListOpsItemEvents")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists all related-item resources associated with a Systems Manager OpsCenter OpsItem. OpsCenter is a capability of Amazon Web Services Systems Manager.
#
# POST /
# operationId: ListOpsItemRelatedItems
export def "list-ops-item-related-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-98 # required
  --ops-item-id: string # The ID of the OpsItem for which you want to list all related-item resources.
  --filters: list # One or more OpsItem filters. Use a filter to return a more specific list of results. — item shape: {Key: "ResourceType"|"AssociationId"|"ResourceUri", Values: list<string>, Operator: "Equal"}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # The token for the next set of items to return. (You received this token from a previous call.) (spec name: NextToken)
]: any -> oneof<record<NextToken: string, Summaries: table<OpsItemId: string, AssociationId: string, ResourceType: string, AssociationType: string, ResourceUri: string, CreatedBy: record, CreatedTime: string, LastModifiedBy: record, LastModifiedTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListOpsItemRelatedItems")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"OpsItemId": $ops_item_id, "Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Amazon Web Services Systems Manager calls this API operation when displaying all Application Manager OpsMetadata objects or blobs.
#
# POST /
# operationId: ListOpsMetadata
export def "list-ops-metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-99 # required
  --filters: list # One or more filters to limit the number of OpsMetadata objects returned by the call. — item shape: {Key: string, Values: list<string>}
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
]: any -> oneof<record<OpsMetadataList: table<ResourceId: string, OpsMetadataArn: string, LastModifiedDate: string, LastModifiedUser: string, CreationDate: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListOpsMetadata")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "MaxResults": $body_max_results, "NextToken": $body_next_token} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
#
# POST /
# operationId: ListResourceComplianceSummaries
export def "list-resource-compliance-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-100 # required
  --filters: list # One or more filters. Use a filter to return a more specific list of results. — item shape: {Key?: string, Values?: list<string>, Type?: "EQUAL"|"NOT_EQUAL"|"BEGIN_WITH"|"LESS_THAN"|"GREATER_THAN"}
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record<ResourceComplianceSummaryItems: table<ComplianceType: string, ResourceType: string, ResourceId: string, Status: string, OverallSeverity: string, ExecutionSummary: record, CompliantSummary: record, NonCompliantSummary: record>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListResourceComplianceSummaries")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"Filters": $filters, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed. The number of sync configurations might be too large to return using a single call to ListResourceDataSync. You can limit the number of sync configurations returned by using the MaxResults parameter. To determine whether there are more sync configurations to list, check the value of NextToken in the output. If there are more sync configurations to list, you can request them by specifying the NextToken returned in the call to the parameter of a subsequent call.
#
# POST /
# operationId: ListResourceDataSync
export def "list-resource-data-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-results: string # Pagination limit
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-101 # required
  --sync-type: string # View a list of resource data syncs according to the sync type. Specify SyncToDestination to view resource data syncs that synchronize data to an Amazon S3 bucket. Specify SyncFromSource to view resource data syncs from Organizations or from multiple Amazon Web Services Regions.
  --body-next-token: string # A token to start the list. Use this token to get the next set of results. (spec name: NextToken)
  --body-max-results: int # The maximum number of items to return for this call. The call also returns a token that you can specify in a subsequent call to get the next set of results. (spec name: MaxResults)
]: any -> oneof<record<ResourceDataSyncItems: table<SyncName: string, SyncType: string, SyncSource: record, S3Destination: record, LastSyncTime: string, LastSuccessfulSyncTime: string, SyncLastModifiedTime: string, LastStatus: string, SyncCreatedTime: string, LastSyncStatusMessage: string>, NextToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListResourceDataSync")
  let qp = [(serialize-qp "MaxResults" $max_results "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp $auth.query)
  let req_body = {"SyncType": $sync_type, "NextToken": $body_next_token, "MaxResults": $body_max_results} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "X-Amz-Target": $x_amz_target} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: ({"MaxResults": $max_results, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns a list of the tags assigned to the specified resource. For information about the ID format for each supported resource type, see AddTagsToResource.
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
  --x-amz-target: string@x-amz-target-completer-102 # required
  resource_type: string@resource-type-completer # Returns a list of tags for a specific resource type.
  resource_id: string # The resource ID for which you want to see a list of tags.
]: any -> oneof<record<TagList: table<Key: string, Value: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceType": $resource_type, "ResourceId": $resource_id} | compact
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

# Shares a Amazon Web Services Systems Manager document (SSM document)publicly or privately. If you share a document privately, you must specify the Amazon Web Services user IDs for those people who can use the document. If you share a document publicly, you must specify All as the account ID.
#
# POST /
# operationId: ModifyDocumentPermission
export def "modify-document-permission" [
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
  name: string # The name of the document that you want to share.
  permission_type: string@permission-type-completer # The permission type for the document. The permission type can be Share.
  --account-ids-to-add: list<string> # The Amazon Web Services users that should have access to the document. The account IDs can either be a group of account IDs or All.
  --account-ids-to-remove: list<string> # The Amazon Web Services users that should no longer have access to the document. The Amazon Web Services user can either be a group of account IDs or All. This action has a higher priority than AccountIdsToAdd. If you specify an ID to add and the same ID to remove, the system removes access to the document.
  --shared-document-version: string # The document version shared with other Amazon Web Services accounts. You can share Latest, Default or All versions.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ModifyDocumentPermission")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "PermissionType": $permission_type, "AccountIdsToAdd": $account_ids_to_add, "AccountIdsToRemove": $account_ids_to_remove, "SharedDocumentVersion": $shared_document_version} | compact
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

# Registers a compliance type and other compliance details on a designated resource. This operation lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request. ComplianceType can be one of the following: ExecutionId: The execution ID when the patch, association, or custom compliance item was applied. ExecutionType: Specify patch, association, or Custom:string. ExecutionTime. The time the patch, association, or custom compliance item was applied to the managed node. Id: The patch, association, or custom compliance ID. Title: A title. Status: The status of the compliance item. For example, approved for patches, or Failed for associations. Severity: A patch severity. For example, Critical. DocumentName: An SSM document name. For example, AWS-RunPatchBaseline. DocumentVersion: An SSM document version number. For example, 4. Classification: A patch classification. For example, security updates. PatchBaselineId: A patch baseline ID. PatchSeverity: A patch severity. For example, Critical. PatchState: A patch state. For example, InstancesWithFailedPatches. PatchGroup: The name of a patch group. InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'
#
# POST /
# operationId: PutComplianceItems
export def "put-compliance-items" [
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
  --x-amz-target: string@x-amz-target-completer-104 # required
  resource_id: string # Specify an ID for this resource. For a managed node, this is the node ID.
  resource_type: string # Specify the type of resource. ManagedInstance is currently the only supported resource type.
  compliance_type: string # Specify the compliance type. For example, specify Association (for a State Manager association), Patch, or Custom:string.
  execution_summary: record # A summary of the call execution that includes an execution ID, the type of execution (for example, Command), and the date/time of the execution using a datetime object that is saved in the following format: yyyy-MM-dd'T'HH:mm:ss'Z'. — shape: {ExecutionTime: string, ExecutionId?: string, ExecutionType?: string}
  items: list # Information about the compliance as defined by the resource type. For example, for a patch compliance type, Items includes information about the PatchSeverity, Classification, and so on. — item shape: {Id?: string, Title?: string, Severity: "CRITICAL"|"HIGH"|"MEDIUM"|"LOW"|"INFORMATIONAL"|"UNSPECIFIED", Status: "COMPLIANT"|"NON_COMPLIANT", Details?: record}
  --item-content-hash: string # MD5 or SHA-256 content hash. The content hash is used to determine if existing information should be overwritten or ignored. If the content hashes match, the request to put compliance information is ignored.
  --upload-type: string@upload-type-completer # The mode for uploading compliance items. You can specify COMPLETE or PARTIAL. In COMPLETE mode, the system overwrites all existing compliance information for the resource. You must provide a full list of compliance items each time you send the request. In PARTIAL mode, the system overwrites compliance information for a specific association. The association must be configured with SyncCompliance set to MANUAL. By default, all requests use COMPLETE mode. This attribute is only valid for association compliance.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.PutComplianceItems")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceId": $resource_id, "ResourceType": $resource_type, "ComplianceType": $compliance_type, "ExecutionSummary": $execution_summary, "Items": $items, "ItemContentHash": $item_content_hash, "UploadType": $upload_type} | compact
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

# Bulk update custom inventory items on one or more managed nodes. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
#
# POST /
# operationId: PutInventory
export def "put-inventory" [
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
  --x-amz-target: string@x-amz-target-completer-105 # required
  instance_id: string # An managed node ID where you want to add or update inventory items.
  items: list # The inventory items that you want to add or update on managed nodes. — item shape: {TypeName: string, SchemaVersion: string, CaptureTime: string, ContentHash?: string, Content?: list, Context?: record}
]: any -> oneof<record<Message: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.PutInventory")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"InstanceId": $instance_id, "Items": $items} | compact
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

# Add a parameter to the system.
#
# POST /
# operationId: PutParameter
export def "put-parameter" [
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
  --x-amz-target: string@x-amz-target-completer-106 # required
  name: string # The fully qualified name of the parameter that you want to add to the system. The fully qualified name includes the complete hierarchy of the parameter path and name. For parameters in a hierarchy, you must include a leading forward slash character (/) when you create or reference a parameter. For example: /Dev/DBServer/MySQL/db-string13 Naming Constraints: Parameter names are case sensitive. A parameter name must be unique within an Amazon Web Services Region A parameter name can't be prefixed with "aws" or "ssm" (case-insensitive). Parameter names can include only the following symbols and letters: a-zA-Z0-9_.- In addition, the slash character ( / ) is used to delineate hierarchies in parameter names. For example: /Dev/Production/East/Project-ABC/MyParameter A parameter name can't include spaces. Parameter hierarchies are limited to a maximum depth of fifteen levels. For additional information about valid values for parameter names, see Creating Systems Manager parameters (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-su-create.html) in the Amazon Web Services Systems Manager User Guide. The maximum length constraint of 2048 characters listed below includes 1037 characters reserved for internal use by Systems Manager. The maximum length for a parameter name that you create is 1011 characters. This includes the characters in the ARN that precede the name you specify, such as arn:aws:ssm:us-east-2:111122223333:parameter/.
  --description: string # Information about the parameter that you want to add to the system. Optional but recommended. Don't enter personally identifiable information in this field.
  value: string # The parameter value that you want to add to the system. Standard parameters have a value limit of 4 KB. Advanced parameters have a value limit of 8 KB. Parameters can't be referenced or nested in the values of other parameters. You can't include {{}} or {{ssm:parameter-name}} in a parameter value. (format: password)
  --type: string@type-completer # The type of parameter that you want to add to the system. SecureString isn't currently supported for CloudFormation templates. Items in a StringList must be separated by a comma (,). You can't use other punctuation or special character to escape items in the list. If you have a parameter value that requires a comma, then use the String data type. Specifying a parameter type isn't required when updating a parameter. You must specify a parameter type when creating a parameter.
  --key-id: string # The Key Management Service (KMS) ID that you want to use to encrypt a parameter. Use a custom key for better security. Required for parameters that use the SecureString data type. If you don't specify a key ID, the system uses the default key associated with your Amazon Web Services account which is not as secure as using a custom key. To use a custom KMS key, choose the SecureString data type with the Key ID parameter.
  --overwrite: oneof<nothing, bool> # Overwrite an existing parameter. The default value is false.
  --allowed-pattern: string # A regular expression used to validate the parameter value. For example, for String types with values restricted to numbers, you can specify the following: AllowedPattern=^\d+$
  --tags: list # Optional metadata that you assign to a resource. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag a Systems Manager parameter to identify the type of resource to which it applies, the environment, or the type of configuration data referenced by the parameter. In this case, you could specify the following key-value pairs: Key=Resource,Value=S3bucket Key=OS,Value=Windows Key=ParameterType,Value=LicenseKey To add tags to an existing Systems Manager parameter, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
  --tier: string@tier-completer # The parameter tier to assign to a parameter. Parameter Store offers a standard tier and an advanced tier for parameters. Standard parameters have a content size limit of 4 KB and can't be configured to use parameter policies. You can create a maximum of 10,000 standard parameters for each Region in an Amazon Web Services account. Standard parameters are offered at no additional cost. Advanced parameters have a content size limit of 8 KB and can be configured to use parameter policies. You can create a maximum of 100,000 advanced parameters for each Region in an Amazon Web Services account. Advanced parameters incur a charge. For more information, see Standard and advanced parameter tiers (https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-advanced-parameters.html) in the Amazon Web Services Systems Manager User Guide. You can change a standard parameter to an advanced parameter any time. But you can't revert an advanced parameter to a standard parameter. Reverting an advanced parameter to a standard parameter would result in data loss because the system would truncate the size of the parameter from 8 KB to 4 KB. Reverting would also remove any policies attached to the parameter. Lastly, advanced parameters use a different form of encryption than standard parameters. If you no longer need an advanced parameter, or if you no longer want to incur charges for an advanced parameter, you must delete it and recreate it as a new standard parameter. Using the Default Tier Configuration In PutParameter requests, you can specify the tier to create the parameter in. Whenever you specify a tier in the request, Parameter Store creates or updates the parameter according to that request. However, if you don't specify a tier in a request, Parameter Store assigns the tier based on the current Parameter Store default tier configuration. The default tier when you begin using Parameter Store is the standard-parameter tier. If you use the advanced-parameter tier, you can specify one of the following as the default: Advanced: With this option, Parameter Store evaluates all requests as advanced parameters. Intelligent-Tiering: With this option, Parameter Store evaluates each request to determine if the parameter is standard or advanced. If the request doesn't include any options that require an advanced parameter, the parameter is created in the standard-parameter tier. If one or more options requiring an advanced parameter are included in the request, Parameter Store create a parameter in the advanced-parameter tier. This approach helps control your parameter-related costs by always creating standard parameters unless an advanced parameter is necessary. Options that require an advanced parameter include the following: The content size of the parameter is more than 4 KB. The parameter uses a parameter policy. More than 10,000 parameters already exist in your Amazon Web Services account in the current Amazon Web Services Region. For more information about configuring the default tier option, see Specifying a default parameter tier (https://docs.aws.amazon.com/systems-manager/latest/userguide/ps-default-tier.html) in the Amazon Web Services Systems Manager User Guide.
  --policies: string # One or more policies to apply to a parameter. This operation takes a JSON array. Parameter Store, a capability of Amazon Web Services Systems Manager supports the following policy types: Expiration: This policy deletes the parameter after it expires. When you create the policy, you specify the expiration date. You can update the expiration date and time by updating the policy. Updating the parameter doesn't affect the expiration date and time. When the expiration time is reached, Parameter Store deletes the parameter. ExpirationNotification: This policy initiates an event in Amazon CloudWatch Events that notifies you about the expiration. By using this policy, you can receive notification before or after the expiration time is reached, in units of days or hours. NoChangeNotification: This policy initiates a CloudWatch Events event if a parameter hasn't been modified for a specified period of time. This policy type is useful when, for example, a secret needs to be changed within a period of time, but it hasn't been changed. All existing policies are preserved until you send new policies or an empty policy. For more information about parameter policies, see Assigning parameter policies (https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-policies.html).
  --data-type: string # The data type for a String parameter. Supported data types include plain text and Amazon Machine Image (AMI) IDs. The following data type values are supported. text aws:ec2:image aws:ssm:integration When you create a String parameter and specify aws:ec2:image, Amazon Web Services Systems Manager validates the parameter value is in the required format, such as ami-12345abcdeEXAMPLE, and that the specified AMI is available in your Amazon Web Services account. If the action is successful, the service sends back an HTTP 200 response which indicates a successful PutParameter call for all cases except for data type aws:ec2:image. If you call PutParameter with aws:ec2:image data type, a successful HTTP 200 response does not guarantee that your parameter was successfully created or updated. The aws:ec2:image value is validated asynchronously, and the PutParameter call returns before the validation is complete. If you submit an invalid AMI value, the PutParameter operation will return success, but the asynchronous validation will fail and the parameter will not be created or updated. To monitor whether your aws:ec2:image parameters are created successfully, see Setting up notifications or trigger actions based on Parameter Store events (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-cwe.html). For more information about AMI format validation , see Native parameter support for Amazon Machine Image (AMI) IDs (https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-store-ec2-aliases.html).
]: any -> oneof<record<Version: int, Tier: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.PutParameter")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "Description": $description, "Value": $value, "Type": $type, "KeyId": $key_id, "Overwrite": $overwrite, "AllowedPattern": $allowed_pattern, "Tags": $tags, "Tier": $tier, "Policies": $policies, "DataType": $data_type} | compact
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

# Creates or updates a Systems Manager resource policy. A resource policy helps you to define the IAM entity (for example, an Amazon Web Services account) that can manage your Systems Manager resources. Currently, OpsItemGroup is the only resource that supports Systems Manager resource policies. The resource policy for OpsItemGroup enables Amazon Web Services accounts to view and interact with OpsCenter operational work items (OpsItems).
#
# POST /
# operationId: PutResourcePolicy
export def "put-resource-policy" [
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
  --x-amz-target: string@x-amz-target-completer-107 # required
  resource_arn: string # Amazon Resource Name (ARN) of the resource to which you want to attach a policy.
  policy: string # A policy you want to associate with a resource.
  --policy-id: string # The policy ID.
  --policy-hash: string # ID of the current policy version. The hash helps to prevent a situation where multiple users attempt to overwrite a policy. You must provide this hash when updating or deleting a policy.
]: any -> oneof<record<PolicyId: string, PolicyHash: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.PutResourcePolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Policy": $policy, "PolicyId": $policy_id, "PolicyHash": $policy_hash} | compact
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

# Defines the default patch baseline for the relevant operating system. To reset the Amazon Web Services-predefined patch baseline as the default, specify the full patch baseline Amazon Resource Name (ARN) as the baseline ID value. For example, for CentOS, specify arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed instead of pb-0574b43a65ea646ed.
#
# POST /
# operationId: RegisterDefaultPatchBaseline
export def "register-default-patch-baseline" [
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
  --x-amz-target: string@x-amz-target-completer-108 # required
  baseline_id: string # The ID of the patch baseline that should be the default patch baseline.
]: any -> oneof<record<BaselineId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.RegisterDefaultPatchBaseline")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BaselineId": $baseline_id} | compact
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

# Registers a patch baseline for a patch group.
#
# POST /
# operationId: RegisterPatchBaselineForPatchGroup
export def "register-patch-baseline-for-patch-group" [
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
  --x-amz-target: string@x-amz-target-completer-109 # required
  baseline_id: string # The ID of the patch baseline to register with the patch group.
  patch_group: string # The name of the patch group to be registered with the patch baseline.
]: any -> oneof<record<BaselineId: string, PatchGroup: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.RegisterPatchBaselineForPatchGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BaselineId": $baseline_id, "PatchGroup": $patch_group} | compact
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

# Registers a target with a maintenance window.
#
# POST /
# operationId: RegisterTargetWithMaintenanceWindow
export def "register-target-with-maintenance-window" [
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
  --x-amz-target: string@x-amz-target-completer-110 # required
  window_id: string # The ID of the maintenance window the target should be registered with.
  resource_type: string@resource-type-completer-1 # The type of target being registered with the maintenance window.
  targets: list # The targets to register with the maintenance window. In other words, the managed nodes to run commands on when the maintenance window runs. If a single maintenance window task is registered with multiple targets, its task invocations occur sequentially and not in parallel. If your task must run on multiple targets at the same time, register a task for each target individually and assign each task the same priority level. You can specify targets using managed node IDs, resource group names, or tags that have been applied to managed nodes. Example 1: Specify managed node IDs Key=InstanceIds,Values=<instance-id-1>,<instance-id-2>,<instance-id-3> Example 2: Use tag key-pairs applied to managed nodes Key=tag:<my-tag-key>,Values=<my-tag-value-1>,<my-tag-value-2> Example 3: Use tag-keys applied to managed nodes Key=tag-key,Values=<my-tag-key-1>,<my-tag-key-2> Example 4: Use resource group names Key=resource-groups:Name,Values=<resource-group-name> Example 5: Use filters for resource group types Key=resource-groups:ResourceTypeFilters,Values=<resource-type-1>,<resource-type-2> For Key=resource-groups:ResourceTypeFilters, specify resource types in the following format Key=resource-groups:ResourceTypeFilters,Values=AWS::EC2::INSTANCE,AWS::EC2::VPC For more information about these examples formats, including the best use case for each one, see Examples: Register targets with a maintenance window (https://docs.aws.amazon.com/systems-manager/latest/userguide/mw-cli-tutorial-targets-examples.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Key?: string, Values?: list<string>}
  --owner-information: string # User-provided value that will be included in any Amazon CloudWatch Events events raised while running tasks for these targets in this maintenance window. (format: password)
  --name: string # An optional name for the target.
  --description: string # An optional description for the target. (format: password)
  --client-token: string # User-provided idempotency token.
]: any -> oneof<record<WindowTargetId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.RegisterTargetWithMaintenanceWindow")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id, "ResourceType": $resource_type, "Targets": $targets, "OwnerInformation": $owner_information, "Name": $name, "Description": $description, "ClientToken": $client_token} | compact
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

# Adds a new task to a maintenance window.
#
# POST /
# operationId: RegisterTaskWithMaintenanceWindow
export def "register-task-with-maintenance-window" [
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
  --x-amz-target: string@x-amz-target-completer-111 # required
  window_id: string # The ID of the maintenance window the task should be added to.
  --targets: list # The targets (either managed nodes or maintenance window targets). One or more targets must be specified for maintenance window Run Command-type tasks. Depending on the task, targets are optional for other maintenance window task types (Automation, Lambda, and Step Functions). For more information about running tasks that don't specify targets, see Registering maintenance window tasks without targets (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) in the Amazon Web Services Systems Manager User Guide. Specify managed nodes using the following format: Key=InstanceIds,Values=<instance-id-1>,<instance-id-2> Specify maintenance window targets using the following format: Key=WindowTargetIds,Values=<window-target-id-1>,<window-target-id-2> — item shape: {Key?: string, Values?: list<string>}
  task_arn: string # The ARN of the task to run.
  --service-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role for Amazon Web Services Systems Manager to assume when running a maintenance window task. If you do not specify a service role ARN, Systems Manager uses your account's service-linked role. If no service-linked role for Systems Manager exists in your account, it is created when you run RegisterTaskWithMaintenanceWindow. For more information, see the following topics in the in the Amazon Web Services Systems Manager User Guide: Using service-linked roles for Systems Manager (https://docs.aws.amazon.com/systems-manager/latest/userguide/using-service-linked-roles.html#slr-permissions) Should I use a service-linked role or a custom service role to run maintenance window tasks? (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-maintenance-permissions.html#maintenance-window-tasks-service-role)
  task_type: string@task-type-completer # The type of task being registered.
  --task-parameters: record # The parameters that should be passed to the task when it is run. TaskParameters has been deprecated. To specify parameters to pass to a task when it runs, instead use the Parameters option in the TaskInvocationParameters structure. For information about how Systems Manager handles these options for the supported maintenance window task types, see MaintenanceWindowTaskInvocationParameters.
  --task-invocation-parameters: record # The parameters for task execution. — shape: {RunCommand?: record, Automation?: record, StepFunctions?: record, Lambda?: record}
  --priority: int # The priority of the task in the maintenance window, the lower the number the higher the priority. Tasks in a maintenance window are scheduled in priority order with tasks that have the same priority scheduled in parallel.
  --max-concurrency: string # The maximum number of targets this task can be run for, in parallel. Although this element is listed as "Required: No", a value can be omitted only when you are registering or updating a targetless task (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) You must provide a value in all other cases. For maintenance window tasks without a target specified, you can't supply a value for this option. Instead, the system inserts a placeholder value of 1. This value doesn't affect the running of your task.
  --max-errors: string # The maximum number of errors allowed before this task stops being scheduled. Although this element is listed as "Required: No", a value can be omitted only when you are registering or updating a targetless task (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) You must provide a value in all other cases. For maintenance window tasks without a target specified, you can't supply a value for this option. Instead, the system inserts a placeholder value of 1. This value doesn't affect the running of your task.
  --logging-info: record # Information about an Amazon Simple Storage Service (Amazon S3) bucket to write managed node-level logs to. LoggingInfo has been deprecated. To specify an Amazon Simple Storage Service (Amazon S3) bucket to contain logs, instead use the OutputS3BucketName and OutputS3KeyPrefix options in the TaskInvocationParameters structure. For information about how Amazon Web Services Systems Manager handles these options for the supported maintenance window task types, see MaintenanceWindowTaskInvocationParameters. — shape: {S3BucketName: string, S3KeyPrefix?: string, S3Region: string}
  --name: string # An optional name for the task.
  --description: string # An optional description for the task. (format: password)
  --client-token: string # User-provided idempotency token.
  --cutoff-behavior: string@cutoff-behavior-completer # Indicates whether tasks should continue to run after the cutoff time specified in the maintenance windows is reached. CONTINUE_TASK: When the cutoff time is reached, any tasks that are running continue. The default value. CANCEL_TASK: For Automation, Lambda, Step Functions tasks: When the cutoff time is reached, any task invocations that are already running continue, but no new task invocations are started. For Run Command tasks: When the cutoff time is reached, the system sends a CancelCommand operation that attempts to cancel the command associated with the task. However, there is no guarantee that the command will be terminated and the underlying process stopped. The status for tasks that are not completed is TIMED_OUT.
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record<WindowTaskId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.RegisterTaskWithMaintenanceWindow")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id, "Targets": $targets, "TaskArn": $task_arn, "ServiceRoleArn": $service_role_arn, "TaskType": $task_type, "TaskParameters": $task_parameters, "TaskInvocationParameters": $task_invocation_parameters, "Priority": $priority, "MaxConcurrency": $max_concurrency, "MaxErrors": $max_errors, "LoggingInfo": $logging_info, "Name": $name, "Description": $description, "ClientToken": $client_token, "CutoffBehavior": $cutoff_behavior, "AlarmConfiguration": $alarm_configuration} | compact
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

# Removes tag keys from the specified resource.
#
# POST /
# operationId: RemoveTagsFromResource
export def "remove-tags-from-resource" [
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
  --x-amz-target: string@x-amz-target-completer-112 # required
  resource_type: string@resource-type-completer # The type of resource from which you want to remove a tag. The ManagedInstance type for this API operation is only for on-premises managed nodes. Specify the name of the managed node in the following format: mi-ID_number . For example, mi-1a2b3c4d5e6f.
  resource_id: string # The ID of the resource from which you want to remove tags. For example: ManagedInstance: mi-012345abcde MaintenanceWindow: mw-012345abcde Automation: example-c160-4567-8519-012345abcde PatchBaseline: pb-012345abcde OpsMetadata object: ResourceID for tagging is created from the Amazon Resource Name (ARN) for the object. Specifically, ResourceID is created from the strings that come after the word opsmetadata in the ARN. For example, an OpsMetadata object with an ARN of arn:aws:ssm:us-east-2:1234567890:opsmetadata/aws/ssm/MyGroup/appmanager has a ResourceID of either aws/ssm/MyGroup/appmanager or /aws/ssm/MyGroup/appmanager. For the Document and Parameter values, use the name of the resource. The ManagedInstance type for this API operation is only for on-premises managed nodes. Specify the name of the managed node in the following format: mi-ID_number. For example, mi-1a2b3c4d5e6f.
  tag_keys: list<string> # Tag keys that you want to remove from the specified resource.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.RemoveTagsFromResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceType": $resource_type, "ResourceId": $resource_id, "TagKeys": $tag_keys} | compact
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

# ServiceSetting is an account-level setting for an Amazon Web Services service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an Amazon Web Services service charges money to the account based on feature or service usage, then the Amazon Web Services service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature. Services map a SettingId object to a setting value. Amazon Web Services services teams define the default value for a SettingId. You can't create a new SettingId, but you can overwrite the default value if you have the ssm:UpdateServiceSetting permission for the setting. Use the GetServiceSetting API operation to view the current value. Use the UpdateServiceSetting API operation to change the default setting. Reset the service setting for the account to the default value as provisioned by the Amazon Web Services service team.
#
# POST /
# operationId: ResetServiceSetting
export def "reset-service-setting" [
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
  --x-amz-target: string@x-amz-target-completer-113 # required
  setting_id: string # The Amazon Resource Name (ARN) of the service setting to reset. The setting ID can be one of the following. /ssm/managed-instance/default-ec2-instance-management-role /ssm/automation/customer-script-log-destination /ssm/automation/customer-script-log-group-name /ssm/documents/console/public-sharing-permission /ssm/managed-instance/activation-tier /ssm/opsinsights/opscenter /ssm/parameter-store/default-parameter-tier /ssm/parameter-store/high-throughput-enabled
]: any -> oneof<record<ServiceSetting: record<SettingId: string, SettingValue: string, LastModifiedDate: string, LastModifiedUser: string, ARN: string, Status: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ResetServiceSetting")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SettingId": $setting_id} | compact
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

# Reconnects a session to a managed node after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions. This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It isn't intended for any other use.
#
# POST /
# operationId: ResumeSession
export def "resume-session" [
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
  --x-amz-target: string@x-amz-target-completer-114 # required
  session_id: string # The ID of the disconnected session to resume.
]: any -> oneof<record<SessionId: string, TokenValue: string, StreamUrl: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.ResumeSession")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SessionId": $session_id} | compact
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

# Sends a signal to an Automation execution to change the current behavior or status of the execution.
#
# POST /
# operationId: SendAutomationSignal
export def "send-automation-signal" [
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
  --x-amz-target: string@x-amz-target-completer-115 # required
  automation_execution_id: string # The unique identifier for an existing Automation execution that you want to send the signal to.
  signal_type: string@signal-type-completer # The type of signal to send to an Automation execution.
  --payload: record # The data sent with the signal. The data schema depends on the type of signal used in the request. For Approve and Reject signal types, the payload is an optional comment that you can send with the signal type. For example: Comment="Looks good" For StartStep and Resume signal types, you must send the name of the Automation step to start or resume as the payload. For example: StepName="step1" For the StopStep signal type, you must send the step execution ID as the payload. For example: StepExecutionId="97fff367-fc5a-4299-aed8-0123456789ab"
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.SendAutomationSignal")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AutomationExecutionId": $automation_execution_id, "SignalType": $signal_type, "Payload": $payload} | compact
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

# Runs commands on one or more managed nodes.
#
# POST /
# operationId: SendCommand
export def "send-command" [
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
  --x-amz-target: string@x-amz-target-completer-116 # required
  --instance-ids: list<string> # The IDs of the managed nodes where the command should run. Specifying managed node IDs is most useful when you are targeting a limited number of managed nodes, though you can specify up to 50 IDs. To target a larger number of managed nodes, or if you prefer not to list individual node IDs, we recommend using the Targets option instead. Using Targets, which accepts tag key-value pairs to identify the managed nodes to send commands to, you can a send command to tens, hundreds, or thousands of nodes at once. For more information about how to use targets, see Using targets and rate controls to send commands to a fleet (https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html) in the Amazon Web Services Systems Manager User Guide.
  --targets: list # An array of search criteria that targets managed nodes using a Key,Value combination that you specify. Specifying targets is most useful when you want to send a command to a large number of managed nodes at once. Using Targets, which accepts tag key-value pairs to identify managed nodes, you can send a command to tens, hundreds, or thousands of nodes at once. To send a command to a smaller number of managed nodes, you can use the InstanceIds option instead. For more information about how to use targets, see Sending commands to a fleet (https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Key?: string, Values?: list<string>}
  document_name: string # The name of the Amazon Web Services Systems Manager document (SSM document) to run. This can be a public document or a custom document. To run a shared document belonging to another account, specify the document Amazon Resource Name (ARN). For more information about how to use shared documents, see Using shared SSM documents (https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-using-shared.html) in the Amazon Web Services Systems Manager User Guide. If you specify a document name or ARN that hasn't been shared with your account, you receive an InvalidDocument error.
  --document-version: string # The SSM document version to use in the request. You can specify $DEFAULT, $LATEST, or a specific version number. If you run commands by using the Command Line Interface (Amazon Web Services CLI), then you must escape the first two options by using a backslash. If you specify a version number, then you don't need to use the backslash. For example: --document-version "\$DEFAULT" --document-version "\$LATEST" --document-version "3"
  --document-hash: string # The Sha256 or Sha1 hash created by the system when the document was created. Sha1 hashes have been deprecated.
  --document-hash-type: string@document-hash-type-completer # Sha256 or Sha1. Sha1 hashes have been deprecated.
  --timeout-seconds: int # If this time is reached and the command hasn't already started running, it won't run.
  --comment: string # User-specified information about the command, such as a brief description of what the command should do.
  --parameters: record # The required and optional parameters specified in the document being run.
  --output-s3-region: string # (Deprecated) You can no longer specify this parameter. The system ignores it. Instead, Systems Manager automatically determines the Amazon Web Services Region of the S3 bucket.
  --output-s3-bucket-name: string # The name of the S3 bucket where command execution responses should be stored.
  --output-s3-key-prefix: string # The directory structure within the S3 bucket where the responses should be stored.
  --max-concurrency: string # (Optional) The maximum number of managed nodes that are allowed to run the command at the same time. You can specify a number such as 10 or a percentage such as 10%. The default value is 50. For more information about how to use MaxConcurrency, see Using concurrency controls (https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html#send-commands-velocity) in the Amazon Web Services Systems Manager User Guide.
  --max-errors: string # The maximum number of errors allowed without the command failing. When the command fails one more time beyond the value of MaxErrors, the systems stops sending the command to additional targets. You can specify a number like 10 or a percentage like 10%. The default value is 0. For more information about how to use MaxErrors, see Using error controls (https://docs.aws.amazon.com/systems-manager/latest/userguide/send-commands-multiple.html#send-commands-maxerrors) in the Amazon Web Services Systems Manager User Guide.
  --service-role-arn: string # The ARN of the Identity and Access Management (IAM) service role to use to publish Amazon Simple Notification Service (Amazon SNS) notifications for Run Command commands. This role must provide the sns:Publish permission for your notification topic. For information about creating and using this service role, see Monitoring Systems Manager status changes using Amazon SNS notifications (https://docs.aws.amazon.com/systems-manager/latest/userguide/monitoring-sns-notifications.html) in the Amazon Web Services Systems Manager User Guide.
  --notification-config: record # Configurations for sending notifications. — shape: {NotificationArn?: string, NotificationEvents?: list<string>, NotificationType?: "Command"|"Invocation"}
  --cloud-watch-output-config: record # Configuration options for sending command output to Amazon CloudWatch Logs. — shape: {CloudWatchLogGroupName?: string, CloudWatchOutputEnabled?: bool}
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record<Command: record<CommandId: string, DocumentName: string, DocumentVersion: string, Comment: string, ExpiresAfter: string, Parameters: record, InstanceIds: list<string>, Targets: list<record>, RequestedDateTime: string, Status: string, StatusDetails: string, OutputS3Region: string, OutputS3BucketName: string, OutputS3KeyPrefix: string, MaxConcurrency: string, MaxErrors: string, TargetCount: int, CompletedCount: int, ErrorCount: int, DeliveryTimedOutCount: int, ServiceRole: string, NotificationConfig: record<NotificationArn: string, NotificationEvents: list, NotificationType: string>, CloudWatchOutputConfig: record<CloudWatchLogGroupName: string, CloudWatchOutputEnabled: bool>, TimeoutSeconds: int, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.SendCommand")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"InstanceIds": $instance_ids, "Targets": $targets, "DocumentName": $document_name, "DocumentVersion": $document_version, "DocumentHash": $document_hash, "DocumentHashType": $document_hash_type, "TimeoutSeconds": $timeout_seconds, "Comment": $comment, "Parameters": $parameters, "OutputS3Region": $output_s3_region, "OutputS3BucketName": $output_s3_bucket_name, "OutputS3KeyPrefix": $output_s3_key_prefix, "MaxConcurrency": $max_concurrency, "MaxErrors": $max_errors, "ServiceRoleArn": $service_role_arn, "NotificationConfig": $notification_config, "CloudWatchOutputConfig": $cloud_watch_output_config, "AlarmConfiguration": $alarm_configuration} | compact
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

# Runs an association immediately and only one time. This operation can be helpful when troubleshooting associations.
#
# POST /
# operationId: StartAssociationsOnce
export def "start-associations-once" [
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
  --x-amz-target: string@x-amz-target-completer-117 # required
  association_ids: list<string> # The association IDs that you want to run immediately and only one time.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.StartAssociationsOnce")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AssociationIds": $association_ids} | compact
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

# Initiates execution of an Automation runbook.
#
# POST /
# operationId: StartAutomationExecution
export def "start-automation-execution" [
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
  --x-amz-target: string@x-amz-target-completer-118 # required
  document_name: string # The name of the SSM document to run. This can be a public document or a custom document. To run a shared document belonging to another account, specify the document ARN. For more information about how to use shared documents, see Using shared SSM documents (https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-using-shared.html) in the Amazon Web Services Systems Manager User Guide.
  --document-version: string # The version of the Automation runbook to use for this execution.
  --parameters: record # A key-value map of execution parameters, which match the declared parameters in the Automation runbook.
  --client-token: string # User-provided idempotency token. The token must be unique, is case insensitive, enforces the UUID format, and can't be reused.
  --mode: string@mode-completer # The execution mode of the automation. Valid modes include the following: Auto and Interactive. The default mode is Auto.
  --target-parameter-name: string # The name of the parameter used as the target resource for the rate-controlled execution. Required if you specify targets.
  --targets: list # A key-value mapping to target resources. Required if you specify TargetParameterName. — item shape: {Key?: string, Values?: list<string>}
  --target-maps: list # A key-value mapping of document parameters to target resources. Both Targets and TargetMaps can't be specified together.
  --max-concurrency: string # The maximum number of targets allowed to run this task in parallel. You can specify a number, such as 10, or a percentage, such as 10%. The default value is 10.
  --max-errors: string # The number of errors that are allowed before the system stops running the automation on additional targets. You can specify either an absolute number of errors, for example 10, or a percentage of the target set, for example 10%. If you specify 3, for example, the system stops running the automation when the fourth error is received. If you specify 0, then the system stops running the automation on additional targets after the first error result is returned. If you run an automation on 50 resources and set max-errors to 10%, then the system stops running the automation on additional targets when the sixth error is received. Executions that are already running an automation when max-errors is reached are allowed to complete, but some of these executions may fail as well. If you need to ensure that there won't be more than max-errors failed executions, set max-concurrency to 1 so the executions proceed one at a time.
  --target-locations: list # A location is a combination of Amazon Web Services Regions and/or Amazon Web Services accounts where you want to run the automation. Use this operation to start an automation in multiple Amazon Web Services Regions and multiple Amazon Web Services accounts. For more information, see Running Automation workflows in multiple Amazon Web Services Regions and Amazon Web Services accounts (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-automation-multiple-accounts-and-regions.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Accounts?: list<string>, Regions?: list<string>, TargetLocationMaxConcurrency?: string, TargetLocationMaxErrors?: string, ExecutionRoleName?: string, TargetLocationAlarmConfiguration?: record}
  --tags: list # Optional metadata that you assign to a resource. You can specify a maximum of five tags for an automation. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag an automation to identify an environment or operating system. In this case, you could specify the following key-value pairs: Key=environment,Value=test Key=OS,Value=Windows To add tags to an existing automation, use the AddTagsToResource operation. — item shape: {Key: string, Value: string}
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record<AutomationExecutionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.StartAutomationExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"DocumentName": $document_name, "DocumentVersion": $document_version, "Parameters": $parameters, "ClientToken": $client_token, "Mode": $mode, "TargetParameterName": $target_parameter_name, "Targets": $targets, "TargetMaps": $target_maps, "MaxConcurrency": $max_concurrency, "MaxErrors": $max_errors, "TargetLocations": $target_locations, "Tags": $tags, "AlarmConfiguration": $alarm_configuration} | compact
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

# Creates a change request for Change Manager. The Automation runbooks specified in the change request run only after all required approvals for the change request have been received.
#
# POST /
# operationId: StartChangeRequestExecution
export def "start-change-request-execution" [
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
  --x-amz-target: string@x-amz-target-completer-119 # required
  --scheduled-time: string # The date and time specified in the change request to run the Automation runbooks. The Automation runbooks specified for the runbook workflow can't run until all required approvals for the change request have been received. (format: date-time)
  document_name: string # The name of the change template document to run during the runbook workflow.
  --document-version: string # The version of the change template document to run during the runbook workflow.
  --parameters: record # A key-value map of parameters that match the declared parameters in the change template document.
  --change-request-name: string # The name of the change request associated with the runbook workflow to be run.
  --client-token: string # The user-provided idempotency token. The token must be unique, is case insensitive, enforces the UUID format, and can't be reused.
  --auto-approve: oneof<nothing, bool> # Indicates whether the change request can be approved automatically without the need for manual approvals. If AutoApprovable is enabled in a change template, then setting AutoApprove to true in StartChangeRequestExecution creates a change request that bypasses approver review. Change Calendar restrictions are not bypassed in this scenario. If the state of an associated calendar is CLOSED, change freeze approvers must still grant permission for this change request to run. If they don't, the change won't be processed until the calendar state is again OPEN.
  runbooks: list # Information about the Automation runbooks that are run during the runbook workflow. The Automation runbooks specified for the runbook workflow can't run until all required approvals for the change request have been received. — item shape: {DocumentName: string, DocumentVersion?: string, Parameters?: record, TargetParameterName?: string, Targets?: list, TargetMaps?: list, MaxConcurrency?: string, MaxErrors?: string, TargetLocations?: list}
  --tags: list # Optional metadata that you assign to a resource. You can specify a maximum of five tags for a change request. Tags enable you to categorize a resource in different ways, such as by purpose, owner, or environment. For example, you might want to tag a change request to identify an environment or target Amazon Web Services Region. In this case, you could specify the following key-value pairs: Key=Environment,Value=Production Key=Region,Value=us-east-2 — item shape: {Key: string, Value: string}
  --scheduled-end-time: string # The time that the requester expects the runbook workflow related to the change request to complete. The time is an estimate only that the requester provides for reviewers. (format: date-time)
  --change-details: string # User-provided details about the change. If no details are provided, content specified in the Template information section of the associated change template is added.
]: any -> oneof<record<AutomationExecutionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.StartChangeRequestExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ScheduledTime": $scheduled_time, "DocumentName": $document_name, "DocumentVersion": $document_version, "Parameters": $parameters, "ChangeRequestName": $change_request_name, "ClientToken": $client_token, "AutoApprove": $auto_approve, "Runbooks": $runbooks, "Tags": $tags, "ScheduledEndTime": $scheduled_end_time, "ChangeDetails": $change_details} | compact
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

# Initiates a connection to a target (for example, a managed node) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs. Amazon Web Services CLI usage: start-session is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see Install the Session Manager plugin for the Amazon Web Services CLI (https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) in the Amazon Web Services Systems Manager User Guide. Amazon Web Services Tools for PowerShell usage: Start-SSMSession isn't currently supported by Amazon Web Services Tools for PowerShell on Windows local machines.
#
# POST /
# operationId: StartSession
export def "start-session" [
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
  --x-amz-target: string@x-amz-target-completer-120 # required
  target: string # The managed node to connect to for the session.
  --document-name: string # The name of the SSM document you want to use to define the type of session, input parameters, or preferences for the session. For example, SSM-SessionManagerRunShell. You can call the GetDocument API to verify the document exists before attempting to start a session. If no document name is provided, a shell to the managed node is launched by default. For more information, see Start a session (https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html) in the Amazon Web Services Systems Manager User Guide.
  --reason: string # The reason for connecting to the instance. This value is included in the details for the Amazon CloudWatch Events event created when you start the session.
  --parameters: record # The values you want to specify for the parameters defined in the Session document.
]: any -> oneof<record<SessionId: string, TokenValue: string, StreamUrl: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.StartSession")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Target": $target, "DocumentName": $document_name, "Reason": $reason, "Parameters": $parameters} | compact
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

# Stop an Automation that is currently running.
#
# POST /
# operationId: StopAutomationExecution
export def "stop-automation-execution" [
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
  --x-amz-target: string@x-amz-target-completer-121 # required
  automation_execution_id: string # The execution ID of the Automation to stop.
  --type: string@type-completer-1 # The stop request type. Valid types include the following: Cancel and Complete. The default type is Cancel.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.StopAutomationExecution")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AutomationExecutionId": $automation_execution_id, "Type": $type} | compact
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

# Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the managed node. A terminated session can't be resumed.
#
# POST /
# operationId: TerminateSession
export def "terminate-session" [
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
  --x-amz-target: string@x-amz-target-completer-122 # required
  session_id: string # The ID of the session to terminate.
]: any -> oneof<record<SessionId: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.TerminateSession")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SessionId": $session_id} | compact
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

# Remove a label or labels from a parameter.
#
# POST /
# operationId: UnlabelParameterVersion
export def "unlabel-parameter-version" [
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
  --x-amz-target: string@x-amz-target-completer-123 # required
  name: string # The name of the parameter from which you want to delete one or more labels.
  parameter_version: int # The specific version of the parameter which you want to delete one or more labels from. If it isn't present, the call will fail.
  labels: list<string> # One or more labels to delete from the specified parameter version.
]: any -> oneof<record<RemovedLabels: list<string>, InvalidLabels: list<string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UnlabelParameterVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ParameterVersion": $parameter_version, "Labels": $labels} | compact
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

# Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon Simple Storage Service (Amazon S3) output. When you call UpdateAssociation, the system removes all optional parameters from the request and overwrites the association with null values for those parameters. This is by design. You must specify all optional parameters in the call, even if you are not changing the parameters. This includes the Name parameter. Before calling this API action, we recommend that you call the DescribeAssociation API operation and make a note of all optional parameters required for your UpdateAssociation call. In order to call this API operation, a user, group, or role must be granted permission to call the DescribeAssociation API operation. If you don't have permission to call DescribeAssociation, then you receive the following error: An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: <user_arn> isn't authorized to perform: ssm:DescribeAssociation on resource: <resource_arn> When you update an association, the association immediately runs against the specified targets. You can add the ApplyOnlyAtCronInterval parameter to run the association during the next schedule run.
#
# POST /
# operationId: UpdateAssociation
export def "update-association" [
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
  --x-amz-target: string@x-amz-target-completer-124 # required
  association_id: string # The ID of the association you want to update.
  --parameters: record # The parameters you want to update for the association. If you create a parameter using Parameter Store, a capability of Amazon Web Services Systems Manager, you can reference the parameter using {{ssm:parameter-name}}.
  --document-version: string # The document version you want update for the association. State Manager doesn't support running associations that use a new version of a document if that document is shared from another account. State Manager always runs the default version of a document if shared from another account, even though the Systems Manager console shows that a new version was processed. If you want to run an association using a new version of a document shared form another account, you must set the document version to default.
  --schedule-expression: string # The cron expression used to schedule the association that you want to update.
  --output-location: record # An S3 bucket where you want to store the results of this request. For the minimal permissions required to enable Amazon S3 output for an association, see Creating associations (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-state-assoc.html) in the Systems Manager User Guide. — shape: {S3Location?: record}
  --name: string # The name of the SSM Command document or Automation runbook that contains the configuration information for the managed node. You can specify Amazon Web Services-predefined documents, documents you created, or a document that is shared with you from another account. For Systems Manager document (SSM document) that are shared with you from other Amazon Web Services accounts, you must specify the complete SSM document ARN, in the following format: arn:aws:ssm:region:account-id:document/document-name For example: arn:aws:ssm:us-east-2:12345678912:document/My-Shared-Document For Amazon Web Services-predefined documents and SSM documents you created in your account, you only need to specify the document name. For example, AWS-ApplyPatchBaseline or My-Document.
  --targets: list # The targets of the association. — item shape: {Key?: string, Values?: list<string>}
  --association-name: string # The name of the association that you want to update.
  --association-version: string # This parameter is provided for concurrency control purposes. You must specify the latest association version in the service. If you want to ensure that this request succeeds, either specify $LATEST, or omit this parameter.
  --automation-target-parameter-name: string # Choose the parameter that will define how your automation will branch out. This target is required for associations that use an Automation runbook and target resources by using rate controls. Automation is a capability of Amazon Web Services Systems Manager.
  --max-errors: string # The number of errors that are allowed before the system stops sending requests to run the association on additional targets. You can specify either an absolute number of errors, for example 10, or a percentage of the target set, for example 10%. If you specify 3, for example, the system stops sending requests when the fourth error is received. If you specify 0, then the system stops sending requests after the first error is returned. If you run an association on 50 managed nodes and set MaxError to 10%, then the system stops sending the request when the sixth error is received. Executions that are already running an association when MaxErrors is reached are allowed to complete, but some of these executions may fail as well. If you need to ensure that there won't be more than max-errors failed executions, set MaxConcurrency to 1 so that executions proceed one at a time.
  --max-concurrency: string # The maximum number of targets allowed to run the association at the same time. You can specify a number, for example 10, or a percentage of the target set, for example 10%. The default value is 100%, which means all targets run the association at the same time. If a new managed node starts and attempts to run an association while Systems Manager is running MaxConcurrency associations, the association is allowed to run. During the next association interval, the new managed node will process its association within the limit specified for MaxConcurrency.
  --compliance-severity: string@compliance-severity-completer # The severity level to assign to the association.
  --sync-compliance: string@sync-compliance-completer # The mode for generating association compliance. You can specify AUTO or MANUAL. In AUTO mode, the system uses the status of the association execution to determine the compliance status. If the association execution runs successfully, then the association is COMPLIANT. If the association execution doesn't run successfully, the association is NON-COMPLIANT. In MANUAL mode, you must specify the AssociationId as a parameter for the PutComplianceItems API operation. In this case, compliance data isn't managed by State Manager, a capability of Amazon Web Services Systems Manager. It is managed by your direct call to the PutComplianceItems API operation. By default, all associations use AUTO mode.
  --apply-only-at-cron-interval: oneof<nothing, bool> # By default, when you update an association, the system runs it immediately after it is updated and then according to the schedule you specified. Specify this option if you don't want an association to run immediately after you update it. This parameter isn't supported for rate expressions. If you chose this option when you created an association and later you edit that association or you make changes to the SSM document on which that association is based (by using the Documents page in the console), State Manager applies the association at the next specified cron interval. For example, if you chose the Latest version of an SSM document when you created an association and you edit the association by choosing a different document version on the Documents page, State Manager applies the association at the next specified cron interval if you previously selected this option. If this option wasn't selected, State Manager immediately runs the association. You can reset this option. To do so, specify the no-apply-only-at-cron-interval parameter when you update the association from the command line. This parameter forces the association to run immediately after updating it and according to the interval specified.
  --calendar-names: list<string> # The names or Amazon Resource Names (ARNs) of the Change Calendar type documents you want to gate your associations under. The associations only run when that change calendar is open. For more information, see Amazon Web Services Systems Manager Change Calendar (https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar).
  --target-locations: list # A location is a combination of Amazon Web Services Regions and Amazon Web Services accounts where you want to run the association. Use this action to update an association in multiple Regions and multiple accounts. — item shape: {Accounts?: list<string>, Regions?: list<string>, TargetLocationMaxConcurrency?: string, TargetLocationMaxErrors?: string, ExecutionRoleName?: string, TargetLocationAlarmConfiguration?: record}
  --schedule-offset: int # Number of days to wait after the scheduled day to run an association. For example, if you specified a cron schedule of cron(0 0 ? * THU#2 *), you could specify an offset of 3 to run the association each Sunday after the second Thursday of the month. For more information about cron schedules for associations, see Reference: Cron and rate expressions for Systems Manager (https://docs.aws.amazon.com/systems-manager/latest/userguide/reference-cron-and-rate-expressions.html) in the Amazon Web Services Systems Manager User Guide. To use offsets, you must specify the ApplyOnlyAtCronInterval parameter. This option tells the system not to run an association immediately after you create it.
  --target-maps: list # A key-value mapping of document parameters to target resources. Both Targets and TargetMaps can't be specified together.
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateAssociation")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"AssociationId": $association_id, "Parameters": $parameters, "DocumentVersion": $document_version, "ScheduleExpression": $schedule_expression, "OutputLocation": $output_location, "Name": $name, "Targets": $targets, "AssociationName": $association_name, "AssociationVersion": $association_version, "AutomationTargetParameterName": $automation_target_parameter_name, "MaxErrors": $max_errors, "MaxConcurrency": $max_concurrency, "ComplianceSeverity": $compliance_severity, "SyncCompliance": $sync_compliance, "ApplyOnlyAtCronInterval": $apply_only_at_cron_interval, "CalendarNames": $calendar_names, "TargetLocations": $target_locations, "ScheduleOffset": $schedule_offset, "TargetMaps": $target_maps, "AlarmConfiguration": $alarm_configuration} | compact
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

# Updates the status of the Amazon Web Services Systems Manager document (SSM document) associated with the specified managed node. UpdateAssociationStatus is primarily used by the Amazon Web Services Systems Manager Agent (SSM Agent) to report status updates about your associations and is only used for associations created with the InstanceId legacy parameter.
#
# POST /
# operationId: UpdateAssociationStatus
export def "update-association-status" [
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
  --x-amz-target: string@x-amz-target-completer-125 # required
  name: string # The name of the SSM document.
  instance_id: string # The managed node ID.
  association_status: record # Describes an association status. — shape: {Date: string, Name: "Pending"|"Success"|"Failed", Message: string, AdditionalInfo?: string}
]: any -> oneof<record<AssociationDescription: record<Name: string, InstanceId: string, AssociationVersion: string, Date: string, LastUpdateAssociationDate: string, Status: record<Date: string, Name: string, Message: string, AdditionalInfo: string>, Overview: record<Status: string, DetailedStatus: string, AssociationStatusAggregatedCount: record>, DocumentVersion: string, AutomationTargetParameterName: string, Parameters: record, AssociationId: string, Targets: list<record>, ScheduleExpression: string, OutputLocation: record<S3Location: record>, LastExecutionDate: string, LastSuccessfulExecutionDate: string, AssociationName: string, MaxErrors: string, MaxConcurrency: string, ComplianceSeverity: string, SyncCompliance: string, ApplyOnlyAtCronInterval: bool, CalendarNames: list<string>, TargetLocations: list<record>, ScheduleOffset: int, TargetMaps: list<record>, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list>, TriggeredAlarms: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateAssociationStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "InstanceId": $instance_id, "AssociationStatus": $association_status} | compact
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

# Updates one or more values for an SSM document.
#
# POST /
# operationId: UpdateDocument
export def "update-document" [
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
  --x-amz-target: string@x-amz-target-completer-126 # required
  content: string # A valid JSON or YAML string.
  --attachments: list # A list of key-value pairs that describe attachments to a version of a document. — item shape: {Key?: "SourceUrl"|"S3FileUrl"|"AttachmentReference", Values?: list<string>, Name?: string}
  name: string # The name of the SSM document that you want to update.
  --display-name: string # The friendly name of the SSM document that you want to update. This value can differ for each version of the document. If you don't specify a value for this parameter in your request, the existing value is applied to the new document version.
  --version-name: string # An optional field specifying the version of the artifact you are updating with the document. For example, "Release 12, Update 6". This value is unique across all versions of a document, and can't be changed.
  --document-version: string # The version of the document that you want to update. Currently, Systems Manager supports updating only the latest version of the document. You can specify the version number of the latest version or use the $LATEST variable. If you change a document version for a State Manager association, Systems Manager immediately runs the association unless you previously specifed the apply-only-at-cron-interval parameter.
  --document-format: string@document-format-completer # Specify the document format for the new document version. Systems Manager supports JSON and YAML documents. JSON is the default format.
  --target-type: string # Specify a new target type for the document.
]: any -> oneof<record<DocumentDescription: record<Sha1: string, Hash: string, HashType: string, Name: string, DisplayName: string, VersionName: string, Owner: string, CreatedDate: string, Status: string, StatusInformation: string, DocumentVersion: string, Description: string, Parameters: list<record>, PlatformTypes: list<string>, DocumentType: string, SchemaVersion: string, LatestVersion: string, DefaultVersion: string, DocumentFormat: string, TargetType: string, Tags: list<record>, AttachmentsInformation: list<record>, Requires: list<record>, Author: string, ReviewInformation: list<record>, ApprovedVersion: string, PendingReviewVersion: string, ReviewStatus: string, Category: list<string>, CategoryEnum: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateDocument")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Content": $content, "Attachments": $attachments, "Name": $name, "DisplayName": $display_name, "VersionName": $version_name, "DocumentVersion": $document_version, "DocumentFormat": $document_format, "TargetType": $target_type} | compact
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

# Set the default version of a document. If you change a document version for a State Manager association, Systems Manager immediately runs the association unless you previously specifed the apply-only-at-cron-interval parameter.
#
# POST /
# operationId: UpdateDocumentDefaultVersion
export def "update-document-default-version" [
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
  --x-amz-target: string@x-amz-target-completer-127 # required
  name: string # The name of a custom document that you want to set as the default version.
  document_version: string # The version of a custom document that you want to set as the default version.
]: any -> oneof<record<Description: record<Name: string, DefaultVersion: string, DefaultVersionName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateDocumentDefaultVersion")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "DocumentVersion": $document_version} | compact
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

# Updates information related to approval reviews for a specific version of a change template in Change Manager.
#
# POST /
# operationId: UpdateDocumentMetadata
export def "update-document-metadata" [
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
  --x-amz-target: string@x-amz-target-completer-128 # required
  name: string # The name of the change template for which a version's metadata is to be updated.
  --document-version: string # The version of a change template in which to update approval metadata.
  document_reviews: record # Information about a document approval review. — shape: {Action: "SendForReview"|"UpdateReview"|"Approve"|"Reject", Comment?: list}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateDocumentMetadata")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "DocumentVersion": $document_version, "DocumentReviews": $document_reviews} | compact
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

# Updates an existing maintenance window. Only specified parameters are modified. The value you specify for Duration determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for Cutoff. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for Cutoff is one hour, no maintenance window tasks can start after 5 PM.
#
# POST /
# operationId: UpdateMaintenanceWindow
export def "update-maintenance-window" [
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
  --x-amz-target: string@x-amz-target-completer-129 # required
  window_id: string # The ID of the maintenance window to update.
  --name: string # The name of the maintenance window.
  --description: string # An optional description for the update request. (format: password)
  --start-date: string # The date and time, in ISO-8601 Extended format, for when you want the maintenance window to become active. StartDate allows you to delay activation of the maintenance window until the specified future date.
  --end-date: string # The date and time, in ISO-8601 Extended format, for when you want the maintenance window to become inactive. EndDate allows you to set a date and time in the future when the maintenance window will no longer run.
  --schedule: string # The schedule of the maintenance window in the form of a cron or rate expression.
  --schedule-timezone: string # The time zone that the scheduled maintenance window executions are based on, in Internet Assigned Numbers Authority (IANA) format. For example: "America/Los_Angeles", "UTC", or "Asia/Seoul". For more information, see the Time Zone Database (https://www.iana.org/time-zones) on the IANA website.
  --schedule-offset: int # The number of days to wait after the date and time specified by a cron expression before running the maintenance window. For example, the following cron expression schedules a maintenance window to run the third Tuesday of every month at 11:30 PM. cron(30 23 ? * TUE#3 *) If the schedule offset is 2, the maintenance window won't run until two days later.
  --duration: int # The duration of the maintenance window in hours.
  --cutoff: int # The number of hours before the end of the maintenance window that Amazon Web Services Systems Manager stops scheduling new tasks for execution.
  --allow-unassociated-targets: oneof<nothing, bool> # Whether targets must be registered with the maintenance window before tasks can be defined for those targets.
  --enabled: oneof<nothing, bool> # Whether the maintenance window is enabled.
  --replace: oneof<nothing, bool> # If True, then all fields that are required by the CreateMaintenanceWindow operation are also required for this API request. Optional fields that aren't specified are set to null.
]: any -> oneof<record<WindowId: string, Name: string, Description: string, StartDate: string, EndDate: string, Schedule: string, ScheduleTimezone: string, ScheduleOffset: int, Duration: int, Cutoff: int, AllowUnassociatedTargets: bool, Enabled: bool>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateMaintenanceWindow")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id, "Name": $name, "Description": $description, "StartDate": $start_date, "EndDate": $end_date, "Schedule": $schedule, "ScheduleTimezone": $schedule_timezone, "ScheduleOffset": $schedule_offset, "Duration": $duration, "Cutoff": $cutoff, "AllowUnassociatedTargets": $allow_unassociated_targets, "Enabled": $enabled, "Replace": $replace} | compact
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

# Modifies the target of an existing maintenance window. You can change the following: Name Description Owner IDs for an ID target Tags for a Tag target From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see Target. If a parameter is null, then the corresponding field isn't modified.
#
# POST /
# operationId: UpdateMaintenanceWindowTarget
export def "update-maintenance-window-target" [
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
  --x-amz-target: string@x-amz-target-completer-130 # required
  window_id: string # The maintenance window ID with which to modify the target.
  window_target_id: string # The target ID to modify.
  --targets: list # The targets to add or replace. — item shape: {Key?: string, Values?: list<string>}
  --owner-information: string # User-provided value that will be included in any Amazon CloudWatch Events events raised while running tasks for these targets in this maintenance window. (format: password)
  --name: string # A name for the update.
  --description: string # An optional description for the update. (format: password)
  --replace: oneof<nothing, bool> # If True, then all fields that are required by the RegisterTargetWithMaintenanceWindow operation are also required for this API request. Optional fields that aren't specified are set to null.
]: any -> oneof<record<WindowId: string, WindowTargetId: string, Targets: table<Key: string, Values: list>, OwnerInformation: string, Name: string, Description: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateMaintenanceWindowTarget")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id, "WindowTargetId": $window_target_id, "Targets": $targets, "OwnerInformation": $owner_information, "Name": $name, "Description": $description, "Replace": $replace} | compact
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

# Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values: TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript. ServiceRoleArn TaskInvocationParameters Priority MaxConcurrency MaxErrors One or more targets must be specified for maintenance window Run Command-type tasks. Depending on the task, targets are optional for other maintenance window task types (Automation, Lambda, and Step Functions). For more information about running tasks that don't specify targets, see Registering maintenance window tasks without targets (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) in the Amazon Web Services Systems Manager User Guide. If the value for a parameter in UpdateMaintenanceWindowTask is null, then the corresponding field isn't modified. If you set Replace to true, then all fields required by the RegisterTaskWithMaintenanceWindow operation are required for this request. Optional fields that aren't specified are set to null. When you update a maintenance window task that has options specified in TaskInvocationParameters, you must provide again all the TaskInvocationParameters values that you want to retain. The values you don't specify again are removed. For example, suppose that when you registered a Run Command task, you specified TaskInvocationParameters values for Comment, NotificationConfig, and OutputS3BucketName. If you update the maintenance window task and specify only a different OutputS3BucketName value, the values for Comment and NotificationConfig are removed.
#
# POST /
# operationId: UpdateMaintenanceWindowTask
export def "update-maintenance-window-task" [
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
  --x-amz-target: string@x-amz-target-completer-131 # required
  window_id: string # The maintenance window ID that contains the task to modify.
  window_task_id: string # The task ID to modify.
  --targets: list # The targets (either managed nodes or tags) to modify. Managed nodes are specified using the format Key=instanceids,Values=instanceID_1,instanceID_2. Tags are specified using the format Key=tag_name,Values=tag_value. One or more targets must be specified for maintenance window Run Command-type tasks. Depending on the task, targets are optional for other maintenance window task types (Automation, Lambda, and Step Functions). For more information about running tasks that don't specify targets, see Registering maintenance window tasks without targets (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) in the Amazon Web Services Systems Manager User Guide. — item shape: {Key?: string, Values?: list<string>}
  --task-arn: string # The task ARN to modify.
  --service-role-arn: string # The Amazon Resource Name (ARN) of the IAM service role for Amazon Web Services Systems Manager to assume when running a maintenance window task. If you do not specify a service role ARN, Systems Manager uses your account's service-linked role. If no service-linked role for Systems Manager exists in your account, it is created when you run RegisterTaskWithMaintenanceWindow. For more information, see the following topics in the in the Amazon Web Services Systems Manager User Guide: Using service-linked roles for Systems Manager (https://docs.aws.amazon.com/systems-manager/latest/userguide/using-service-linked-roles.html#slr-permissions) Should I use a service-linked role or a custom service role to run maintenance window tasks? (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-maintenance-permissions.html#maintenance-window-tasks-service-role)
  --task-parameters: record # The parameters to modify. TaskParameters has been deprecated. To specify parameters to pass to a task when it runs, instead use the Parameters option in the TaskInvocationParameters structure. For information about how Systems Manager handles these options for the supported maintenance window task types, see MaintenanceWindowTaskInvocationParameters. The map has the following format: Key: string, between 1 and 255 characters Value: an array of strings, each string is between 1 and 255 characters
  --task-invocation-parameters: record # The parameters for task execution. — shape: {RunCommand?: record, Automation?: record, StepFunctions?: record, Lambda?: record}
  --priority: int # The new task priority to specify. The lower the number, the higher the priority. Tasks that have the same priority are scheduled in parallel.
  --max-concurrency: string # The new MaxConcurrency value you want to specify. MaxConcurrency is the number of targets that are allowed to run this task, in parallel. Although this element is listed as "Required: No", a value can be omitted only when you are registering or updating a targetless task (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) You must provide a value in all other cases. For maintenance window tasks without a target specified, you can't supply a value for this option. Instead, the system inserts a placeholder value of 1. This value doesn't affect the running of your task.
  --max-errors: string # The new MaxErrors value to specify. MaxErrors is the maximum number of errors that are allowed before the task stops being scheduled. Although this element is listed as "Required: No", a value can be omitted only when you are registering or updating a targetless task (https://docs.aws.amazon.com/systems-manager/latest/userguide/maintenance-windows-targetless-tasks.html) You must provide a value in all other cases. For maintenance window tasks without a target specified, you can't supply a value for this option. Instead, the system inserts a placeholder value of 1. This value doesn't affect the running of your task.
  --logging-info: record # Information about an Amazon Simple Storage Service (Amazon S3) bucket to write managed node-level logs to. LoggingInfo has been deprecated. To specify an Amazon Simple Storage Service (Amazon S3) bucket to contain logs, instead use the OutputS3BucketName and OutputS3KeyPrefix options in the TaskInvocationParameters structure. For information about how Amazon Web Services Systems Manager handles these options for the supported maintenance window task types, see MaintenanceWindowTaskInvocationParameters. — shape: {S3BucketName: string, S3KeyPrefix?: string, S3Region: string}
  --name: string # The new task name to specify.
  --description: string # The new task description to specify. (format: password)
  --replace: oneof<nothing, bool> # If True, then all fields that are required by the RegisterTaskWithMaintenanceWindow operation are also required for this API request. Optional fields that aren't specified are set to null.
  --cutoff-behavior: string@cutoff-behavior-completer # Indicates whether tasks should continue to run after the cutoff time specified in the maintenance windows is reached. CONTINUE_TASK: When the cutoff time is reached, any tasks that are running continue. The default value. CANCEL_TASK: For Automation, Lambda, Step Functions tasks: When the cutoff time is reached, any task invocations that are already running continue, but no new task invocations are started. For Run Command tasks: When the cutoff time is reached, the system sends a CancelCommand operation that attempts to cancel the command associated with the task. However, there is no guarantee that the command will be terminated and the underlying process stopped. The status for tasks that are not completed is TIMED_OUT.
  --alarm-configuration: record # The details for the CloudWatch alarm you want to apply to an automation or command. — shape: {IgnorePollAlarmFailure?: bool, Alarms: list}
]: any -> oneof<record<WindowId: string, WindowTaskId: string, Targets: table<Key: string, Values: list>, TaskArn: string, ServiceRoleArn: string, TaskParameters: record, TaskInvocationParameters: record<RunCommand: record<Comment: string, CloudWatchOutputConfig: record, DocumentHash: string, DocumentHashType: string, DocumentVersion: string, NotificationConfig: record, OutputS3BucketName: string, OutputS3KeyPrefix: string, Parameters: record, ServiceRoleArn: string, TimeoutSeconds: int>, Automation: record<DocumentVersion: string, Parameters: record>, StepFunctions: record<Input: string, Name: string>, Lambda: record<ClientContext: string, Qualifier: string, Payload: string>>, Priority: int, MaxConcurrency: string, MaxErrors: string, LoggingInfo: record<S3BucketName: string, S3KeyPrefix: string, S3Region: string>, Name: string, Description: string, CutoffBehavior: string, AlarmConfiguration: record<IgnorePollAlarmFailure: bool, Alarms: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateMaintenanceWindowTask")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WindowId": $window_id, "WindowTaskId": $window_task_id, "Targets": $targets, "TaskArn": $task_arn, "ServiceRoleArn": $service_role_arn, "TaskParameters": $task_parameters, "TaskInvocationParameters": $task_invocation_parameters, "Priority": $priority, "MaxConcurrency": $max_concurrency, "MaxErrors": $max_errors, "LoggingInfo": $logging_info, "Name": $name, "Description": $description, "Replace": $replace, "CutoffBehavior": $cutoff_behavior, "AlarmConfiguration": $alarm_configuration} | compact
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

# Changes the Identity and Access Management (IAM) role that is assigned to the on-premises server, edge device, or virtual machines (VM). IAM roles are first assigned to these hybrid nodes during the activation process. For more information, see CreateActivation.
#
# POST /
# operationId: UpdateManagedInstanceRole
export def "update-managed-instance-role" [
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
  --x-amz-target: string@x-amz-target-completer-132 # required
  instance_id: string # The ID of the managed node where you want to update the role.
  iam_role: string # The name of the Identity and Access Management (IAM) role that you want to assign to the managed node. This IAM role must provide AssumeRole permissions for the Amazon Web Services Systems Manager service principal ssm.amazonaws.com. For more information, see Create an IAM service role for a hybrid environment (https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-service-role.html) in the Amazon Web Services Systems Manager User Guide. You can't specify an IAM service-linked role for this parameter. You must create a unique role.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateManagedInstanceRole")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"InstanceId": $instance_id, "IamRole": $iam_role} | compact
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

# Edit or change an OpsItem. You must have permission in Identity and Access Management (IAM) to update an OpsItem. For more information, see Getting started with OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html) in the Amazon Web Services Systems Manager User Guide. Operations engineers and IT professionals use Amazon Web Services Systems Manager OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their Amazon Web Services resources. For more information, see OpsCenter (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html) in the Amazon Web Services Systems Manager User Guide.
#
# POST /
# operationId: UpdateOpsItem
export def "update-ops-item" [
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
  --x-amz-target: string@x-amz-target-completer-133 # required
  --description: string # Update the information about the OpsItem. Provide enough information so that users reading this OpsItem for the first time understand the issue.
  --operational-data: record # Add new keys or edit existing key-value pairs of the OperationalData map in the OpsItem object. Operational data is custom data that provides useful reference details about the OpsItem. For example, you can specify log files, error strings, license keys, troubleshooting tips, or other relevant data. You enter operational data as key-value pairs. The key has a maximum length of 128 characters. The value has a maximum size of 20 KB. Operational data keys can't begin with the following: amazon, aws, amzn, ssm, /amazon, /aws, /amzn, /ssm. You can choose to make the data searchable by other users in the account or you can restrict search access. Searchable data means that all users with access to the OpsItem Overview page (as provided by the DescribeOpsItems API operation) can view and search on the specified data. Operational data that isn't searchable is only viewable by users who have access to the OpsItem (as provided by the GetOpsItem API operation). Use the /aws/resources key in OperationalData to specify a related resource in the request. Use the /aws/automations key in OperationalData to associate an Automation runbook with the OpsItem. To view Amazon Web Services CLI example commands that use these keys, see Creating OpsItems manually (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-creating-OpsItems.html#OpsCenter-manually-create-OpsItems) in the Amazon Web Services Systems Manager User Guide.
  --operational-data-to-delete: list<string> # Keys that you want to remove from the OperationalData map.
  --notifications: list # The Amazon Resource Name (ARN) of an SNS topic where notifications are sent when this OpsItem is edited or changed. — item shape: {Arn?: string}
  --priority: int # The importance of this OpsItem in relation to other OpsItems in the system.
  --related-ops-items: list # One or more OpsItems that share something in common with the current OpsItems. For example, related OpsItems can include OpsItems with similar error messages, impacted resources, or statuses for the impacted resource. — item shape: {OpsItemId: string}
  --status: string@status-completer # The OpsItem status. Status can be Open, In Progress, or Resolved. For more information, see Editing OpsItem details (https://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-working-with-OpsItems.html#OpsCenter-working-with-OpsItems-editing-details) in the Amazon Web Services Systems Manager User Guide.
  ops_item_id: string # The ID of the OpsItem.
  --title: string # A short heading that describes the nature of the OpsItem and the impacted resource.
  --category: string # Specify a new category for an OpsItem.
  --severity: string # Specify a new severity for an OpsItem.
  --actual-start-time: string # The time a runbook workflow started. Currently reported only for the OpsItem type /aws/changerequest. (format: date-time)
  --actual-end-time: string # The time a runbook workflow ended. Currently reported only for the OpsItem type /aws/changerequest. (format: date-time)
  --planned-start-time: string # The time specified in a change request for a runbook workflow to start. Currently supported only for the OpsItem type /aws/changerequest. (format: date-time)
  --planned-end-time: string # The time specified in a change request for a runbook workflow to end. Currently supported only for the OpsItem type /aws/changerequest. (format: date-time)
  --ops-item-arn: string # The OpsItem Amazon Resource Name (ARN).
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateOpsItem")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Description": $description, "OperationalData": $operational_data, "OperationalDataToDelete": $operational_data_to_delete, "Notifications": $notifications, "Priority": $priority, "RelatedOpsItems": $related_ops_items, "Status": $status, "OpsItemId": $ops_item_id, "Title": $title, "Category": $category, "Severity": $severity, "ActualStartTime": $actual_start_time, "ActualEndTime": $actual_end_time, "PlannedStartTime": $planned_start_time, "PlannedEndTime": $planned_end_time, "OpsItemArn": $ops_item_arn} | compact
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

# Amazon Web Services Systems Manager calls this API operation when you edit OpsMetadata in Application Manager.
#
# POST /
# operationId: UpdateOpsMetadata
export def "update-ops-metadata" [
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
  --x-amz-target: string@x-amz-target-completer-134 # required
  ops_metadata_arn: string # The Amazon Resource Name (ARN) of the OpsMetadata Object to update.
  --metadata-to-update: record # Metadata to add to an OpsMetadata object.
  --keys-to-delete: list<string> # The metadata keys to delete from the OpsMetadata object.
]: any -> oneof<record<OpsMetadataArn: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateOpsMetadata")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"OpsMetadataArn": $ops_metadata_arn, "MetadataToUpdate": $metadata_to_update, "KeysToDelete": $keys_to_delete} | compact
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

# Modifies an existing patch baseline. Fields not specified in the request are left unchanged. For information about valid key-value pairs in PatchFilters for each supported operating system type, see PatchFilter.
#
# POST /
# operationId: UpdatePatchBaseline
export def "update-patch-baseline" [
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
  --x-amz-target: string@x-amz-target-completer-135 # required
  baseline_id: string # The ID of the patch baseline to update.
  --name: string # The name of the patch baseline.
  --global-filters: record # A set of patch filters, typically used for approval rules. — shape: {PatchFilters: list}
  --approval-rules: record # A set of rules defining the approval rules for a patch baseline. — shape: {PatchRules: list}
  --approved-patches: list<string> # A list of explicitly approved patches for the baseline. For information about accepted formats for lists of approved patches and rejected patches, see About package name formats for approved and rejected patch lists (https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-approved-rejected-package-name-formats.html) in the Amazon Web Services Systems Manager User Guide.
  --approved-patches-compliance-level: string@approved-patches-compliance-level-completer # Assigns a new compliance severity level to an existing patch baseline.
  --approved-patches-enable-non-security: oneof<nothing, bool> # Indicates whether the list of approved patches includes non-security updates that should be applied to the managed nodes. The default value is false. Applies to Linux managed nodes only.
  --rejected-patches: list<string> # A list of explicitly rejected patches for the baseline. For information about accepted formats for lists of approved patches and rejected patches, see About package name formats for approved and rejected patch lists (https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-approved-rejected-package-name-formats.html) in the Amazon Web Services Systems Manager User Guide.
  --rejected-patches-action: string@rejected-patches-action-completer # The action for Patch Manager to take on patches included in the RejectedPackages list. ALLOW_AS_DEPENDENCY : A package in the Rejected patches list is installed only if it is a dependency of another package. It is considered compliant with the patch baseline, and its status is reported as InstalledOther. This is the default action if no option is specified. BLOCK : Packages in the RejectedPatches list, and packages that include them as dependencies, aren't installed under any circumstances. If a package was installed before it was added to the Rejected patches list, it is considered non-compliant with the patch baseline, and its status is reported as InstalledRejected.
  --description: string # A description of the patch baseline.
  --sources: list # Information about the patches to use to update the managed nodes, including target operating systems and source repositories. Applies to Linux managed nodes only. — item shape: {Name: string, Products: list<string>, Configuration: string}
  --replace: oneof<nothing, bool> # If True, then all fields that are required by the CreatePatchBaseline operation are also required for this API request. Optional fields that aren't specified are set to null.
]: any -> oneof<record<BaselineId: string, Name: string, OperatingSystem: string, GlobalFilters: record<PatchFilters: list<record>>, ApprovalRules: record<PatchRules: list<record>>, ApprovedPatches: list<string>, ApprovedPatchesComplianceLevel: string, ApprovedPatchesEnableNonSecurity: bool, RejectedPatches: list<string>, RejectedPatchesAction: string, CreatedDate: string, ModifiedDate: string, Description: string, Sources: table<Name: string, Products: list, Configuration: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdatePatchBaseline")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"BaselineId": $baseline_id, "Name": $name, "GlobalFilters": $global_filters, "ApprovalRules": $approval_rules, "ApprovedPatches": $approved_patches, "ApprovedPatchesComplianceLevel": $approved_patches_compliance_level, "ApprovedPatchesEnableNonSecurity": $approved_patches_enable_non_security, "RejectedPatches": $rejected_patches, "RejectedPatchesAction": $rejected_patches_action, "Description": $description, "Sources": $sources, "Replace": $replace} | compact
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

# Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one. This API operation only supports a resource data sync that was created with a SyncFromSource SyncType.
#
# POST /
# operationId: UpdateResourceDataSync
export def "update-resource-data-sync" [
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
  --x-amz-target: string@x-amz-target-completer-136 # required
  sync_name: string # The name of the resource data sync you want to update.
  sync_type: string # The type of resource data sync. The supported SyncType is SyncFromSource.
  sync_source: record # Information about the source of the data included in the resource data sync. — shape: {SourceType: string, AwsOrganizationsSource?: record, SourceRegions: list<string>, IncludeFutureRegions?: bool, EnableAllOpsDataSources?: bool}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateResourceDataSync")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SyncName": $sync_name, "SyncType": $sync_type, "SyncSource": $sync_source} | compact
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

# ServiceSetting is an account-level setting for an Amazon Web Services service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an Amazon Web Services service charges money to the account based on feature or service usage, then the Amazon Web Services service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature. Services map a SettingId object to a setting value. Amazon Web Services services teams define the default value for a SettingId. You can't create a new SettingId, but you can overwrite the default value if you have the ssm:UpdateServiceSetting permission for the setting. Use the GetServiceSetting API operation to view the current value. Or, use the ResetServiceSetting to change the value back to the original value defined by the Amazon Web Services service team. Update the service setting for the account.
#
# POST /
# operationId: UpdateServiceSetting
export def "update-service-setting" [
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
  --x-amz-target: string@x-amz-target-completer-137 # required
  setting_id: string # The Amazon Resource Name (ARN) of the service setting to update. For example, arn:aws:ssm:us-east-1:111122223333:servicesetting/ssm/parameter-store/high-throughput-enabled. The setting ID can be one of the following. /ssm/managed-instance/default-ec2-instance-management-role /ssm/automation/customer-script-log-destination /ssm/automation/customer-script-log-group-name /ssm/documents/console/public-sharing-permission /ssm/managed-instance/activation-tier /ssm/opsinsights/opscenter /ssm/parameter-store/default-parameter-tier /ssm/parameter-store/high-throughput-enabled Permissions to update the /ssm/managed-instance/default-ec2-instance-management-role setting should only be provided to administrators. Implement least privilege access when allowing individuals to configure or modify the Default Host Management Configuration.
  setting_value: string # The new value to specify for the service setting. The following list specifies the available values for each setting. /ssm/managed-instance/default-ec2-instance-management-role: The name of an IAM role /ssm/automation/customer-script-log-destination: CloudWatch /ssm/automation/customer-script-log-group-name: The name of an Amazon CloudWatch Logs log group /ssm/documents/console/public-sharing-permission: Enable or Disable /ssm/managed-instance/activation-tier: standard or advanced /ssm/opsinsights/opscenter: Enabled or Disabled /ssm/parameter-store/default-parameter-tier: Standard, Advanced, Intelligent-Tiering /ssm/parameter-store/high-throughput-enabled: true or false
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AmazonSSM.UpdateServiceSetting")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SettingId": $setting_id, "SettingValue": $setting_value} | compact
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
