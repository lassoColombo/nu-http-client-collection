# Auto-generated client for Amazon Elastic Block Store v2019-11-02
# Source: https://api.apis.guru/v2/specs/amazonaws.com/ebs/2019-11-02/openapi.json
# Auth: --token flag or $env.AMAZON_ELASTIC_BLOCK_STORE_TOKEN

const BASE_URL = "http://ebs.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AMAZON_ELASTIC_BLOCK_STORE_TOKEN | default "" }
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

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://ebs.us-east-1.amazonaws.com" "http://ebs.us-east-2.amazonaws.com" "http://ebs.us-west-1.amazonaws.com" "http://ebs.us-west-2.amazonaws.com" "http://ebs.us-gov-west-1.amazonaws.com" "http://ebs.us-gov-east-1.amazonaws.com" "http://ebs.ca-central-1.amazonaws.com" "http://ebs.eu-north-1.amazonaws.com" "http://ebs.eu-west-1.amazonaws.com" "http://ebs.eu-west-2.amazonaws.com" "http://ebs.eu-west-3.amazonaws.com" "http://ebs.eu-central-1.amazonaws.com" "http://ebs.eu-south-1.amazonaws.com" "http://ebs.af-south-1.amazonaws.com" "http://ebs.ap-northeast-1.amazonaws.com" "http://ebs.ap-northeast-2.amazonaws.com" "http://ebs.ap-northeast-3.amazonaws.com" "http://ebs.ap-southeast-1.amazonaws.com" "http://ebs.ap-southeast-2.amazonaws.com" "http://ebs.ap-east-1.amazonaws.com" "http://ebs.ap-south-1.amazonaws.com" "http://ebs.sa-east-1.amazonaws.com" "http://ebs.me-south-1.amazonaws.com" "https://ebs.us-east-1.amazonaws.com" "https://ebs.us-east-2.amazonaws.com" "https://ebs.us-west-1.amazonaws.com" "https://ebs.us-west-2.amazonaws.com" "https://ebs.us-gov-west-1.amazonaws.com" "https://ebs.us-gov-east-1.amazonaws.com" "https://ebs.ca-central-1.amazonaws.com" "https://ebs.eu-north-1.amazonaws.com" "https://ebs.eu-west-1.amazonaws.com" "https://ebs.eu-west-2.amazonaws.com" "https://ebs.eu-west-3.amazonaws.com" "https://ebs.eu-central-1.amazonaws.com" "https://ebs.eu-south-1.amazonaws.com" "https://ebs.af-south-1.amazonaws.com" "https://ebs.ap-northeast-1.amazonaws.com" "https://ebs.ap-northeast-2.amazonaws.com" "https://ebs.ap-northeast-3.amazonaws.com" "https://ebs.ap-southeast-1.amazonaws.com" "https://ebs.ap-southeast-2.amazonaws.com" "https://ebs.ap-east-1.amazonaws.com" "https://ebs.ap-south-1.amazonaws.com" "https://ebs.sa-east-1.amazonaws.com" "https://ebs.me-south-1.amazonaws.com" "http://ebs.cn-north-1.amazonaws.com.cn" "http://ebs.cn-northwest-1.amazonaws.com.cn" "https://ebs.cn-north-1.amazonaws.com.cn" "https://ebs.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-checksum-algorithm-completer [] { ["SHA256"] }
def x-amz-checksum-aggregation-method-completer [] { ["LINEAR"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "snapshots-completion complete" } } | get name | first)
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

# Seals and completes the snapshot after all of the required blocks of data have been written to it. Completing the snapshot changes the status to completed. You cannot write new blocks to a snapshot after it has been completed.
#
# POST /snapshots/completion/{snapshotId}
# operationId: CompleteSnapshot
export def "snapshots-completion complete" [
  snapshot_id: string
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
  --x-amz-changed-blocks-count: int # The number of blocks that were written to the snapshot.
  --x-amz-checksum: string # An aggregated Base-64 SHA256 checksum based on the checksums of each written block. To generate the aggregated checksum using the linear aggregation method, arrange the checksums for each written block in ascending order of their block index, concatenate them to form a single string, and then generate the checksum on the entire string using the SHA256 algorithm.
  --x-amz-checksum-algorithm: string@x-amz-checksum-algorithm-completer # The algorithm used to generate the checksum. Currently, the only supported algorithm is SHA256.
  --x-amz-checksum-aggregation-method: string@x-amz-checksum-aggregation-method-completer # The aggregation method used to generate the checksum. Currently, the only supported aggregation method is LINEAR.
]: nothing -> record<Status: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/snapshots/completion/{snapshot_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-ChangedBlocksCount": $x_amz_changed_blocks_count, "x-amz-Checksum": $x_amz_checksum, "x-amz-Checksum-Algorithm": $x_amz_checksum_algorithm, "x-amz-Checksum-Aggregation-Method": $x_amz_checksum_aggregation_method} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [202]
}

# Returns the data in a block in an Amazon Elastic Block Store snapshot.
#
# GET /snapshots/{snapshotId}/blocks/{blockIndex}
# operationId: GetSnapshotBlock
export def "snapshots-blocks get" [
  snapshot_id: string
  block_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --block-token: string # The block token of the block from which to get data. You can obtain the BlockToken by running the ListChangedBlocks or ListSnapshotBlocks operations.
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<BlockData: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  if ($block_index | is-empty) { error make --unspanned { msg: "path parameter 'blockIndex' must be non-empty" } }
  let qp = [(serialize-qp "blockToken" $block_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id), block_index: (encode-path-segment $block_index)} | format pattern "/snapshots/{snapshot_id}/blocks/{block_index}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"blockToken": $block_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about the blocks that are different between two Amazon Elastic Block Store snapshots of the same volume/snapshot lineage.
#
# GET /snapshots/{secondSnapshotId}/changedblocks
# operationId: ListChangedBlocks
export def "snapshots-changedblocks list-changed-blocks" [
  second_snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-snapshot-id: string # The ID of the first snapshot to use for the comparison. The FirstSnapshotID parameter must be specified with a SecondSnapshotId parameter; otherwise, an error occurs.
  --page-token: string # The token to request the next page of results. If you specify NextToken, then StartingBlockIndex is ignored.
  --max-results: int # The maximum number of blocks to be returned by the request. Even if additional blocks can be retrieved from the snapshot, the request can return less blocks than MaxResults or an empty array of blocks. To retrieve the next set of blocks from the snapshot, make another request with the returned NextToken value. The value of NextToken is null when there are no more blocks to return.
  --starting-block-index: int # The block index from which the comparison should start. The list in the response will start from this block index or the next valid block index in the snapshots. If you specify NextToken, then StartingBlockIndex is ignored.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<ChangedBlocks: record, ExpiryTime: record, VolumeSize: record, BlockSize: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($second_snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'secondSnapshotId' must be non-empty" } }
  let qp = [(serialize-qp "firstSnapshotId" $first_snapshot_id "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "startingBlockIndex" $starting_block_index "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({second_snapshot_id: (encode-path-segment $second_snapshot_id)} | format pattern "/snapshots/{second_snapshot_id}/changedblocks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"firstSnapshotId": $first_snapshot_id, "pageToken": $page_token, "maxResults": $max_results, "startingBlockIndex": $starting_block_index, "MaxResults": $max_results_2, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns information about the blocks in an Amazon Elastic Block Store snapshot.
#
# GET /snapshots/{snapshotId}/blocks
# operationId: ListSnapshotBlocks
export def "snapshots-blocks list" [
  snapshot_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-token: string # The token to request the next page of results. If you specify NextToken, then StartingBlockIndex is ignored.
  --max-results: int # The maximum number of blocks to be returned by the request. Even if additional blocks can be retrieved from the snapshot, the request can return less blocks than MaxResults or an empty array of blocks. To retrieve the next set of blocks from the snapshot, make another request with the returned NextToken value. The value of NextToken is null when there are no more blocks to return.
  --starting-block-index: int # The block index from which the list should start. The list in the response will start from this block index or the next valid block index in the snapshot. If you specify NextToken, then StartingBlockIndex is ignored.
  --max-results-2: string # Pagination limit (disambiguated-2)
  --next-token: string # Pagination token
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
]: nothing -> record<Blocks: record, ExpiryTime: record, VolumeSize: record, BlockSize: record, NextToken: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  let qp = [(serialize-qp "pageToken" $page_token "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "startingBlockIndex" $starting_block_index "scalar") (serialize-qp "MaxResults" $max_results_2 "scalar") (serialize-qp "NextToken" $next_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id)} | format pattern "/snapshots/{snapshot_id}/blocks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pageToken": $page_token, "maxResults": $max_results, "startingBlockIndex": $starting_block_index, "MaxResults": $max_results_2, "NextToken": $next_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Writes a block of data to a snapshot. If the specified block contains data, the existing data is overwritten. The target snapshot must be in the pending state. Data written to a snapshot must be aligned with 512-KiB sectors.
#
# PUT /snapshots/{snapshotId}/blocks/{blockIndex}
# operationId: PutSnapshotBlock
export def "snapshots-blocks update" [
  snapshot_id: string
  block_index: int
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
  --x-amz-data-length: int # The size of the data to write to the block, in bytes. Currently, the only supported size is 524288 bytes. Valid values: 524288
  --x-amz-progress: int # The progress of the write process, as a percentage.
  --x-amz-checksum: string # A Base64-encoded SHA256 checksum of the data. Only SHA256 checksums are supported.
  --x-amz-checksum-algorithm: string@x-amz-checksum-algorithm-completer # The algorithm used to generate the checksum. Currently, the only supported algorithm is SHA256.
  block_data: string # The data to write to the block. The block data is not signed as part of the Signature Version 4 signing process. As a result, you must generate and provide a Base64-encoded SHA256 checksum for the block data using the x-amz-Checksum header. Also, you must specify the checksum algorithm using the x-amz-Checksum-Algorithm header. The checksum that you provide is part of the Signature Version 4 signing process. It is validated against a checksum generated by Amazon EBS to ensure the validity and authenticity of the data. If the checksums do not correspond, the request fails. For more information, see Using checksums with the EBS direct APIs (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-accessing-snapshot.html#ebsapis-using-checksums) in the Amazon Elastic Compute Cloud User Guide. (format: password)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($snapshot_id | is-empty) { error make --unspanned { msg: "path parameter 'snapshotId' must be non-empty" } }
  if ($block_index | is-empty) { error make --unspanned { msg: "path parameter 'blockIndex' must be non-empty" } }
  let full_url = (build-url $base ({snapshot_id: (encode-path-segment $snapshot_id), block_index: (encode-path-segment $block_index)} | format pattern "/snapshots/{snapshot_id}/blocks/{block_index}") $auth.query)
  let req_body = {"BlockData": $block_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers, "x-amz-Data-Length": $x_amz_data_length, "x-amz-Progress": $x_amz_progress, "x-amz-Checksum": $x_amz_checksum, "x-amz-Checksum-Algorithm": $x_amz_checksum_algorithm} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [201]
}

# Creates a new Amazon EBS snapshot. The new snapshot enters the pending state after the request completes. After creating the snapshot, use PutSnapshotBlock (https://docs.aws.amazon.com/ebs/latest/APIReference/API_PutSnapshotBlock.html) to write blocks of data to the snapshot.
#
# POST /snapshots
# operationId: StartSnapshot
# --Tags item shape: {Key?: any, Value?: any}
export def "snapshots start" [
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
  volume_size: int # The size of the volume, in GiB. The maximum size is 65536 GiB (64 TiB).
  --parent-snapshot-id: string # The ID of the parent snapshot. If there is no parent snapshot, or if you are creating the first snapshot for an on-premises volume, omit this parameter. You can't specify ParentSnapshotId and Encrypted in the same request. If you specify both parameters, the request fails with ValidationException. The encryption status of the snapshot depends on the values that you specify for Encrypted, KmsKeyArn, and ParentSnapshotId, and whether your Amazon Web Services account is enabled for encryption by default (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html#encryption-by-default). For more information, see Using encryption (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebsapis-using-encryption.html) in the Amazon Elastic Compute Cloud User Guide. If you specify an encrypted parent snapshot, you must have permission to use the KMS key that was used to encrypt the parent snapshot. For more information, see Permissions to use Key Management Service keys (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebsapi-permissions.html#ebsapi-kms-permissions) in the Amazon Elastic Compute Cloud User Guide.
  --tags: list # The tags to apply to the snapshot. — item shape: {Key?: any, Value?: any}
  --description: string # A description for the snapshot.
  --client-token: string # A unique, case-sensitive identifier that you provide to ensure the idempotency of the request. Idempotency ensures that an API request completes only once. With an idempotent request, if the original request completes successfully. The subsequent retries with the same client token return the result from the original successful request and they have no additional effect. If you do not specify a client token, one is automatically generated by the Amazon Web Services SDK. For more information, see Idempotency for StartSnapshot API (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-direct-api-idempotency.html) in the Amazon Elastic Compute Cloud User Guide.
  --encrypted: oneof<nothing, bool> # Indicates whether to encrypt the snapshot. You can't specify Encrypted and ParentSnapshotId in the same request. If you specify both parameters, the request fails with ValidationException. The encryption status of the snapshot depends on the values that you specify for Encrypted, KmsKeyArn, and ParentSnapshotId, and whether your Amazon Web Services account is enabled for encryption by default (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html#encryption-by-default). For more information, see Using encryption (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebsapis-using-encryption.html) in the Amazon Elastic Compute Cloud User Guide. To create an encrypted snapshot, you must have permission to use the KMS key. For more information, see Permissions to use Key Management Service keys (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebsapi-permissions.html#ebsapi-kms-permissions) in the Amazon Elastic Compute Cloud User Guide.
  --kms-key-arn: string # The Amazon Resource Name (ARN) of the Key Management Service (KMS) key to be used to encrypt the snapshot. The encryption status of the snapshot depends on the values that you specify for Encrypted, KmsKeyArn, and ParentSnapshotId, and whether your Amazon Web Services account is enabled for encryption by default (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html#encryption-by-default). For more information, see Using encryption (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebsapis-using-encryption.html) in the Amazon Elastic Compute Cloud User Guide. To create an encrypted snapshot, you must have permission to use the KMS key. For more information, see Permissions to use Key Management Service keys (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebsapi-permissions.html#ebsapi-kms-permissions) in the Amazon Elastic Compute Cloud User Guide. (format: password)
  --timeout: int # The amount of time (in minutes) after which the snapshot is automatically cancelled if: No blocks are written to the snapshot. The snapshot is not completed after writing the last block of data. If no value is specified, the timeout defaults to 60 minutes.
]: any -> record<Description: record, SnapshotId: record, OwnerId: record, Status: record, StartTime: record, VolumeSize: record, BlockSize: record, Tags: record, ParentSnapshotId: record, KmsKeyArn: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/snapshots" $auth.query)
  let req_body = {"VolumeSize": $volume_size, "ParentSnapshotId": $parent_snapshot_id, "Tags": $tags, "Description": $description, "ClientToken": $client_token, "Encrypted": $encrypted, "KmsKeyArn": $kms_key_arn, "Timeout": $timeout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}
