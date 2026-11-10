# Auto-generated client for AWS WAF v2015-08-24
# Source: https://api.apis.guru/v2/specs/amazonaws.com/waf/2015-08-24/openapi.json
# Auth: --token flag or $env.AWS_WAF_TOKEN

const BASE_URL = "https://waf.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o AWS_WAF_TOKEN | default "" }
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

def base-url-completer [] { ["https://waf.amazonaws.com" "http://waf.cn-north-1.amazonaws.com.cn" "http://waf.cn-northwest-1.amazonaws.com.cn" "https://waf.cn-north-1.amazonaws.com.cn" "https://waf.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSWAF_20150824.CreateByteMatchSet"] }
def x-amz-target-completer-1 [] { ["AWSWAF_20150824.CreateGeoMatchSet"] }
def x-amz-target-completer-2 [] { ["AWSWAF_20150824.CreateIPSet"] }
def rate-key-completer [] { ["IP"] }
def x-amz-target-completer-3 [] { ["AWSWAF_20150824.CreateRateBasedRule"] }
def x-amz-target-completer-4 [] { ["AWSWAF_20150824.CreateRegexMatchSet"] }
def x-amz-target-completer-5 [] { ["AWSWAF_20150824.CreateRegexPatternSet"] }
def x-amz-target-completer-6 [] { ["AWSWAF_20150824.CreateRule"] }
def x-amz-target-completer-7 [] { ["AWSWAF_20150824.CreateRuleGroup"] }
def x-amz-target-completer-8 [] { ["AWSWAF_20150824.CreateSizeConstraintSet"] }
def x-amz-target-completer-9 [] { ["AWSWAF_20150824.CreateSqlInjectionMatchSet"] }
def x-amz-target-completer-10 [] { ["AWSWAF_20150824.CreateWebACL"] }
def x-amz-target-completer-11 [] { ["AWSWAF_20150824.CreateWebACLMigrationStack"] }
def x-amz-target-completer-12 [] { ["AWSWAF_20150824.CreateXssMatchSet"] }
def x-amz-target-completer-13 [] { ["AWSWAF_20150824.DeleteByteMatchSet"] }
def x-amz-target-completer-14 [] { ["AWSWAF_20150824.DeleteGeoMatchSet"] }
def x-amz-target-completer-15 [] { ["AWSWAF_20150824.DeleteIPSet"] }
def x-amz-target-completer-16 [] { ["AWSWAF_20150824.DeleteLoggingConfiguration"] }
def x-amz-target-completer-17 [] { ["AWSWAF_20150824.DeletePermissionPolicy"] }
def x-amz-target-completer-18 [] { ["AWSWAF_20150824.DeleteRateBasedRule"] }
def x-amz-target-completer-19 [] { ["AWSWAF_20150824.DeleteRegexMatchSet"] }
def x-amz-target-completer-20 [] { ["AWSWAF_20150824.DeleteRegexPatternSet"] }
def x-amz-target-completer-21 [] { ["AWSWAF_20150824.DeleteRule"] }
def x-amz-target-completer-22 [] { ["AWSWAF_20150824.DeleteRuleGroup"] }
def x-amz-target-completer-23 [] { ["AWSWAF_20150824.DeleteSizeConstraintSet"] }
def x-amz-target-completer-24 [] { ["AWSWAF_20150824.DeleteSqlInjectionMatchSet"] }
def x-amz-target-completer-25 [] { ["AWSWAF_20150824.DeleteWebACL"] }
def x-amz-target-completer-26 [] { ["AWSWAF_20150824.DeleteXssMatchSet"] }
def x-amz-target-completer-27 [] { ["AWSWAF_20150824.GetByteMatchSet"] }
def x-amz-target-completer-28 [] { ["AWSWAF_20150824.GetChangeToken"] }
def x-amz-target-completer-29 [] { ["AWSWAF_20150824.GetChangeTokenStatus"] }
def x-amz-target-completer-30 [] { ["AWSWAF_20150824.GetGeoMatchSet"] }
def x-amz-target-completer-31 [] { ["AWSWAF_20150824.GetIPSet"] }
def x-amz-target-completer-32 [] { ["AWSWAF_20150824.GetLoggingConfiguration"] }
def x-amz-target-completer-33 [] { ["AWSWAF_20150824.GetPermissionPolicy"] }
def x-amz-target-completer-34 [] { ["AWSWAF_20150824.GetRateBasedRule"] }
def x-amz-target-completer-35 [] { ["AWSWAF_20150824.GetRateBasedRuleManagedKeys"] }
def x-amz-target-completer-36 [] { ["AWSWAF_20150824.GetRegexMatchSet"] }
def x-amz-target-completer-37 [] { ["AWSWAF_20150824.GetRegexPatternSet"] }
def x-amz-target-completer-38 [] { ["AWSWAF_20150824.GetRule"] }
def x-amz-target-completer-39 [] { ["AWSWAF_20150824.GetRuleGroup"] }
def x-amz-target-completer-40 [] { ["AWSWAF_20150824.GetSampledRequests"] }
def x-amz-target-completer-41 [] { ["AWSWAF_20150824.GetSizeConstraintSet"] }
def x-amz-target-completer-42 [] { ["AWSWAF_20150824.GetSqlInjectionMatchSet"] }
def x-amz-target-completer-43 [] { ["AWSWAF_20150824.GetWebACL"] }
def x-amz-target-completer-44 [] { ["AWSWAF_20150824.GetXssMatchSet"] }
def x-amz-target-completer-45 [] { ["AWSWAF_20150824.ListActivatedRulesInRuleGroup"] }
def x-amz-target-completer-46 [] { ["AWSWAF_20150824.ListByteMatchSets"] }
def x-amz-target-completer-47 [] { ["AWSWAF_20150824.ListGeoMatchSets"] }
def x-amz-target-completer-48 [] { ["AWSWAF_20150824.ListIPSets"] }
def x-amz-target-completer-49 [] { ["AWSWAF_20150824.ListLoggingConfigurations"] }
def x-amz-target-completer-50 [] { ["AWSWAF_20150824.ListRateBasedRules"] }
def x-amz-target-completer-51 [] { ["AWSWAF_20150824.ListRegexMatchSets"] }
def x-amz-target-completer-52 [] { ["AWSWAF_20150824.ListRegexPatternSets"] }
def x-amz-target-completer-53 [] { ["AWSWAF_20150824.ListRuleGroups"] }
def x-amz-target-completer-54 [] { ["AWSWAF_20150824.ListRules"] }
def x-amz-target-completer-55 [] { ["AWSWAF_20150824.ListSizeConstraintSets"] }
def x-amz-target-completer-56 [] { ["AWSWAF_20150824.ListSqlInjectionMatchSets"] }
def x-amz-target-completer-57 [] { ["AWSWAF_20150824.ListSubscribedRuleGroups"] }
def x-amz-target-completer-58 [] { ["AWSWAF_20150824.ListTagsForResource"] }
def x-amz-target-completer-59 [] { ["AWSWAF_20150824.ListWebACLs"] }
def x-amz-target-completer-60 [] { ["AWSWAF_20150824.ListXssMatchSets"] }
def x-amz-target-completer-61 [] { ["AWSWAF_20150824.PutLoggingConfiguration"] }
def x-amz-target-completer-62 [] { ["AWSWAF_20150824.PutPermissionPolicy"] }
def x-amz-target-completer-63 [] { ["AWSWAF_20150824.TagResource"] }
def x-amz-target-completer-64 [] { ["AWSWAF_20150824.UntagResource"] }
def x-amz-target-completer-65 [] { ["AWSWAF_20150824.UpdateByteMatchSet"] }
def x-amz-target-completer-66 [] { ["AWSWAF_20150824.UpdateGeoMatchSet"] }
def x-amz-target-completer-67 [] { ["AWSWAF_20150824.UpdateIPSet"] }
def x-amz-target-completer-68 [] { ["AWSWAF_20150824.UpdateRateBasedRule"] }
def x-amz-target-completer-69 [] { ["AWSWAF_20150824.UpdateRegexMatchSet"] }
def x-amz-target-completer-70 [] { ["AWSWAF_20150824.UpdateRegexPatternSet"] }
def x-amz-target-completer-71 [] { ["AWSWAF_20150824.UpdateRule"] }
def x-amz-target-completer-72 [] { ["AWSWAF_20150824.UpdateRuleGroup"] }
def x-amz-target-completer-73 [] { ["AWSWAF_20150824.UpdateSizeConstraintSet"] }
def x-amz-target-completer-74 [] { ["AWSWAF_20150824.UpdateSqlInjectionMatchSet"] }
def x-amz-target-completer-75 [] { ["AWSWAF_20150824.UpdateWebACL"] }
def x-amz-target-completer-76 [] { ["AWSWAF_20150824.UpdateXssMatchSet"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["create-byte-match-set" "create-geo-match-set" "create-ip-set" "create-rate-based-rule" "create-regex-match-set" "create-regex-pattern-set" "create-rule" "create-rule-group" "create-size-constraint-set" "create-sql-injection-match-set" "create-web-acl" "create-web-acl-migration-stack" "create-xss-match-set" "delete-byte-match-set" "delete-geo-match-set" "delete-ip-set" "delete-logging-configuration" "delete-permission-policy" "delete-rate-based-rule" "delete-regex-match-set" "delete-regex-pattern-set" "delete-rule" "delete-rule-group" "delete-size-constraint-set" "delete-sql-injection-match-set" "delete-web-acl" "delete-xss-match-set" "get-byte-match-set" "get-change-token" "get-change-token-status" "get-geo-match-set" "get-ip-set" "get-logging-configuration" "get-permission-policy" "get-rate-based-rule" "get-rate-based-rule-managed-keys" "get-regex-match-set" "get-regex-pattern-set" "get-rule" "get-rule-group" "get-sampled-requests" "get-size-constraint-set" "get-sql-injection-match-set" "get-web-acl" "get-xss-match-set" "list-activated-rules-in-rule-group" "list-byte-match-sets" "list-geo-match-sets" "list-ip-sets" "list-logging-configurations" "list-rate-based-rules" "list-regex-match-sets" "list-regex-pattern-sets" "list-rule-groups" "list-rules" "list-size-constraint-sets" "list-sql-injection-match-sets" "list-subscribed-rule-groups" "list-tags-for-resource" "list-web-ac-ls" "list-xss-match-sets" "put-logging-configuration" "put-permission-policy" "tag-resource" "untag-resource" "update-byte-match-set" "update-geo-match-set" "update-ip-set" "update-rate-based-rule" "update-regex-match-set" "update-regex-pattern-set" "update-rule" "update-rule-group" "update-size-constraint-set" "update-sql-injection-match-set" "update-web-acl" "update-xss-match-set" "commands"] | sort) } | get name | first)
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a ByteMatchSet. You then use UpdateByteMatchSet to identify the part of a web request that you want AWS WAF to inspect, such as the values of the User-Agent header or the query string. For example, you can create a ByteMatchSet that matches any requests with User-Agent headers that contain the string BadBot. You can then configure AWS WAF to reject those requests. To create and configure a ByteMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateByteMatchSet request. Submit a CreateByteMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateByteMatchSet request. Submit an UpdateByteMatchSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateByteMatchSet
export def "create-byte-match-set" [
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
  name: string # A friendly name or description of the ByteMatchSet. You can't change Name after you create a ByteMatchSet.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ByteMatchSet: record<ByteMatchSetId: string, Name: string, ByteMatchTuples: list<record>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateByteMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates an GeoMatchSet, which you use to specify which web requests you want to allow or block based on the country that the requests originate from. For example, if you're receiving a lot of requests from one or more countries and you want to block the requests, you can create an GeoMatchSet that contains those countries and then configure AWS WAF to block the requests. To create and configure a GeoMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateGeoMatchSet request. Submit a CreateGeoMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateGeoMatchSet request. Submit an UpdateGeoMatchSetSet request to specify the countries that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateGeoMatchSet
export def "create-geo-match-set" [
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
  name: string # A friendly name or description of the GeoMatchSet. You can't change Name after you create the GeoMatchSet.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<GeoMatchSet: record<GeoMatchSetId: string, Name: string, GeoMatchConstraints: list<record>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateGeoMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates an IPSet, which you use to specify which web requests that you want to allow or block based on the IP addresses that the requests originate from. For example, if you're receiving a lot of requests from one or more individual IP addresses or one or more ranges of IP addresses and you want to block the requests, you can create an IPSet that contains those IP addresses and then configure AWS WAF to block the requests. To create and configure an IPSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateIPSet request. Submit a CreateIPSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateIPSet request. Submit an UpdateIPSet request to specify the IP addresses that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateIPSet
export def "create-ip-set" [
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
  name: string # A friendly name or description of the IPSet. You can't change Name after you create the IPSet.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<IPSet: record<IPSetId: string, Name: string, IPSetDescriptors: list<record>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateIPSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a RateBasedRule. The RateBasedRule contains a RateLimit, which specifies the maximum number of requests that AWS WAF allows from a specified IP address in a five-minute period. The RateBasedRule also contains the IPSet objects, ByteMatchSet objects, and other predicates that identify the requests that you want to count or block if these requests exceed the RateLimit. If you add more than one predicate to a RateBasedRule, a request not only must exceed the RateLimit, but it also must match all the conditions to be counted or blocked. For example, suppose you add the following to a RateBasedRule: An IPSet that matches the IP address 192.0.2.44/32 A ByteMatchSet that matches BadBot in the User-Agent header Further, you specify a RateLimit of 1,000. You then add the RateBasedRule to a WebACL and specify that you want to block requests that meet the conditions in the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 and the User-Agent header in the request must contain the value BadBot. Further, requests that match these two conditions must be received at a rate of more than 1,000 requests every five minutes. If both conditions are met and the rate is exceeded, AWS WAF blocks the requests. If the rate drops below 1,000 for a five-minute period, AWS WAF no longer blocks the requests. As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a RateBasedRule: A ByteMatchSet with FieldToMatch of URI A PositionalConstraint of STARTS_WITH A TargetString of login Further, you specify a RateLimit of 1,000. By adding this RateBasedRule to a WebACL, you could limit requests to your login page without affecting the rest of your site. To create and configure a RateBasedRule, perform the following steps: Create and update the predicates that you want to include in the rule. For more information, see CreateByteMatchSet, CreateIPSet, and CreateSqlInjectionMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateRule request. Submit a CreateRateBasedRule request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRule request. Submit an UpdateRateBasedRule request to specify the predicates that you want to include in the rule. Create and update a WebACL that contains the RateBasedRule. For more information, see CreateWebACL. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRateBasedRule
export def "create-rate-based-rule" [
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
  name: string # A friendly name or description of the RateBasedRule. You can't change the name of a RateBasedRule after you create it.
  metric_name: string # A friendly name or description for the metrics for this RateBasedRule. The name can contain only alphanumeric characters (A-Z, a-z, 0-9), with maximum length 128 and minimum length one. It can't contain whitespace or metric names reserved for AWS WAF, including "All" and "Default_Action." You can't change the name of the metric after you create the RateBasedRule.
  rate_key: string@rate-key-completer # The field that AWS WAF uses to determine if requests are likely arriving from a single source and thus subject to rate monitoring. The only valid value for RateKey is IP. IP indicates that requests that arrive from the same IP address are subject to the RateLimit that is specified in the RateBasedRule.
  rate_limit: int # The maximum number of requests, which have an identical value in the field that is specified by RateKey, allowed in a five-minute period. If the number of requests exceeds the RateLimit and the other predicates specified in the rule are also met, AWS WAF triggers the action that is specified for this rule.
  change_token: string # The ChangeToken that you used to submit the CreateRateBasedRule request. You can also use this value to query the status of the request. For more information, see GetChangeTokenStatus.
  --tags: list # item shape: {Key: string, Value: string}
]: any -> oneof<record<Rule: record<RuleId: string, Name: string, MetricName: string, MatchPredicates: list<record>, RateKey: string, RateLimit: int>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateRateBasedRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "MetricName": $metric_name, "RateKey": $rate_key, "RateLimit": $rate_limit, "ChangeToken": $change_token, "Tags": $tags} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a RegexMatchSet. You then use UpdateRegexMatchSet to identify the part of a web request that you want AWS WAF to inspect, such as the values of the User-Agent header or the query string. For example, you can create a RegexMatchSet that contains a RegexMatchTuple that looks for any requests with User-Agent headers that match a RegexPatternSet with pattern B[a@]dB[o0]t. You can then configure AWS WAF to reject those requests. To create and configure a RegexMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateRegexMatchSet request. Submit a CreateRegexMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRegexMatchSet request. Submit an UpdateRegexMatchSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value, using a RegexPatternSet, that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRegexMatchSet
export def "create-regex-match-set" [
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
  name: string # A friendly name or description of the RegexMatchSet. You can't change Name after you create a RegexMatchSet.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<RegexMatchSet: record<RegexMatchSetId: string, Name: string, RegexMatchTuples: list<record>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateRegexMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a RegexPatternSet. You then use UpdateRegexPatternSet to specify the regular expression (regex) pattern that you want AWS WAF to search for, such as B[a@]dB[o0]t. You can then configure AWS WAF to reject those requests. To create and configure a RegexPatternSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateRegexPatternSet request. Submit a CreateRegexPatternSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRegexPatternSet request. Submit an UpdateRegexPatternSet request to specify the string that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRegexPatternSet
export def "create-regex-pattern-set" [
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
  name: string # A friendly name or description of the RegexPatternSet. You can't change Name after you create a RegexPatternSet.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<RegexPatternSet: record<RegexPatternSetId: string, Name: string, RegexPatternStrings: list<string>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateRegexPatternSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a Rule, which contains the IPSet objects, ByteMatchSet objects, and other predicates that identify the requests that you want to block. If you add more than one predicate to a Rule, a request must match all of the specifications to be allowed or blocked. For example, suppose that you add the following to a Rule: An IPSet that matches the IP address 192.0.2.44/32 A ByteMatchSet that matches BadBot in the User-Agent header You then add the Rule to a WebACL and specify that you want to blocks requests that satisfy the Rule. For a request to be blocked, it must come from the IP address 192.0.2.44 and the User-Agent header in the request must contain the value BadBot. To create and configure a Rule, perform the following steps: Create and update the predicates that you want to include in the Rule. For more information, see CreateByteMatchSet, CreateIPSet, and CreateSqlInjectionMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateRule request. Submit a CreateRule request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRule request. Submit an UpdateRule request to specify the predicates that you want to include in the Rule. Create and update a WebACL that contains the Rule. For more information, see CreateWebACL. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRule
export def "create-rule" [
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
  name: string # A friendly name or description of the Rule. You can't change the name of a Rule after you create it.
  metric_name: string # A friendly name or description for the metrics for this Rule. The name can contain only alphanumeric characters (A-Z, a-z, 0-9), with maximum length 128 and minimum length one. It can't contain whitespace or metric names reserved for AWS WAF, including "All" and "Default_Action." You can't change the name of the metric after you create the Rule.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  --tags: list # item shape: {Key: string, Value: string}
]: any -> oneof<record<Rule: record<RuleId: string, Name: string, MetricName: string, Predicates: list<record>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "MetricName": $metric_name, "ChangeToken": $change_token, "Tags": $tags} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a RuleGroup. A rule group is a collection of predefined rules that you add to a web ACL. You use UpdateRuleGroup to add rules to the rule group. Rule groups are subject to the following limits: Three rule groups per account. You can request an increase to this limit by contacting customer support. One rule group per web ACL. Ten rules per rule group. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRuleGroup
export def "create-rule-group" [
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
  name: string # A friendly name or description of the RuleGroup. You can't change Name after you create a RuleGroup.
  metric_name: string # A friendly name or description for the metrics for this RuleGroup. The name can contain only alphanumeric characters (A-Z, a-z, 0-9), with maximum length 128 and minimum length one. It can't contain whitespace or metric names reserved for AWS WAF, including "All" and "Default_Action." You can't change the name of the metric after you create the RuleGroup.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  --tags: list # item shape: {Key: string, Value: string}
]: any -> oneof<record<RuleGroup: record<RuleGroupId: string, Name: string, MetricName: string>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "MetricName": $metric_name, "ChangeToken": $change_token, "Tags": $tags} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a SizeConstraintSet. You then use UpdateSizeConstraintSet to identify the part of a web request that you want AWS WAF to check for length, such as the length of the User-Agent header or the length of the query string. For example, you can create a SizeConstraintSet that matches any requests that have a query string that is longer than 100 bytes. You can then configure AWS WAF to reject those requests. To create and configure a SizeConstraintSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateSizeConstraintSet request. Submit a CreateSizeConstraintSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateSizeConstraintSet request. Submit an UpdateSizeConstraintSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateSizeConstraintSet
export def "create-size-constraint-set" [
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
  name: string # A friendly name or description of the SizeConstraintSet. You can't change Name after you create a SizeConstraintSet.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<SizeConstraintSet: record<SizeConstraintSetId: string, Name: string, SizeConstraints: list<record>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateSizeConstraintSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a SqlInjectionMatchSet, which you use to allow, block, or count requests that contain snippets of SQL code in a specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings. To create and configure a SqlInjectionMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateSqlInjectionMatchSet request. Submit a CreateSqlInjectionMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateSqlInjectionMatchSet request. Submit an UpdateSqlInjectionMatchSet request to specify the parts of web requests in which you want to allow, block, or count malicious SQL code. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateSqlInjectionMatchSet
export def "create-sql-injection-match-set" [
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
  name: string # A friendly name or description for the SqlInjectionMatchSet that you're creating. You can't change Name after you create the SqlInjectionMatchSet.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<SqlInjectionMatchSet: record<SqlInjectionMatchSetId: string, Name: string, SqlInjectionMatchTuples: list<record>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateSqlInjectionMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a WebACL, which contains the Rules that identify the CloudFront web requests that you want to allow, block, or count. AWS WAF evaluates Rules in order based on the value of Priority for each Rule. You also specify a default action, either ALLOW or BLOCK. If a web request doesn't match any of the Rules in a WebACL, AWS WAF responds to the request with the default action. To create and configure a WebACL, perform the following steps: Create and update the ByteMatchSet objects and other predicates that you want to include in Rules. For more information, see CreateByteMatchSet, UpdateByteMatchSet, CreateIPSet, UpdateIPSet, CreateSqlInjectionMatchSet, and UpdateSqlInjectionMatchSet. Create and update the Rules that you want to include in the WebACL. For more information, see CreateRule and UpdateRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateWebACL request. Submit a CreateWebACL request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateWebACL request. Submit an UpdateWebACL request to specify the Rules that you want to include in the WebACL, to specify the default action, and to associate the WebACL with a CloudFront distribution. For more information about how to use the AWS WAF API, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateWebACL
export def "create-web-acl" [
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
  name: string # A friendly name or description of the WebACL. You can't change Name after you create the WebACL.
  metric_name: string # A friendly name or description for the metrics for this WebACL.The name can contain only alphanumeric characters (A-Z, a-z, 0-9), with maximum length 128 and minimum length one. It can't contain whitespace or metric names reserved for AWS WAF, including "All" and "Default_Action." You can't change MetricName after you create the WebACL.
  default_action: record # This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. For the action that is associated with a rule in a WebACL, specifies the action that you want AWS WAF to perform when a web request matches all of the conditions in a rule. For the default action in a WebACL, specifies the action that you want AWS WAF to take when a web request doesn't match all of the conditions in any of the rules in a WebACL. — shape: {Type: "BLOCK"|"ALLOW"|"COUNT"}
  change_token: string # The value returned by the most recent call to GetChangeToken.
  --tags: list # item shape: {Key: string, Value: string}
]: any -> oneof<record<WebACL: record<WebACLId: string, Name: string, MetricName: string, DefaultAction: record<Type: string>, Rules: list<record>, WebACLArn: string>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "MetricName": $metric_name, "DefaultAction": $default_action, "ChangeToken": $change_token, "Tags": $tags} | compact
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

# Creates an AWS CloudFormation WAFV2 template for the specified web ACL in the specified Amazon S3 bucket. Then, in CloudFormation, you create a stack from the template, to create the web ACL and its resources in AWS WAFV2. Use this to migrate your AWS WAF Classic web ACL to the latest version of AWS WAF. This is part of a larger migration procedure for web ACLs from AWS WAF Classic to the latest version of AWS WAF. For the full procedure, including caveats and manual steps to complete the migration and switch over to the new web ACL, see Migrating your AWS WAF Classic resources to AWS WAF (https://docs.aws.amazon.com/waf/latest/developerguide/waf-migrating-from-classic.html) in the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html).
#
# POST /
# operationId: CreateWebACLMigrationStack
export def "create-web-acl-migration-stack" [
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
  web_acl_id: string # The UUID of the WAF Classic web ACL that you want to migrate to WAF v2.
  s3_bucket_name: string # The name of the Amazon S3 bucket to store the CloudFormation template in. The S3 bucket must be configured as follows for the migration: The bucket name must start with aws-waf-migration-. For example, aws-waf-migration-my-web-acl. The bucket must be in the Region where you are deploying the template. For example, for a web ACL in us-west-2, you must use an Amazon S3 bucket in us-west-2 and you must deploy the template stack to us-west-2. The bucket policies must permit the migration process to write data. For listings of the bucket policies, see the Examples section.
  --ignore-unsupported-type: oneof<nothing, bool> # Indicates whether to exclude entities that can't be migrated or to stop the migration. Set this to true to ignore unsupported entities in the web ACL during the migration. Otherwise, if AWS WAF encounters unsupported entities, it stops the process and throws an exception.
]: any -> oneof<record<S3ObjectUrl: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateWebACLMigrationStack")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLId": $web_acl_id, "S3BucketName": $s3_bucket_name, "IgnoreUnsupportedType": $ignore_unsupported_type} | compact
  let req_body = (merge-body-input $input $req_body "record")
  if (($req_body | get -o "IgnoreUnsupportedType") == null) { error make --unspanned { msg: "required body field 'IgnoreUnsupportedType' missing: pass --ignore-unsupported-type or pipe a record" } }
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates an XssMatchSet, which you use to allow, block, or count requests that contain cross-site scripting attacks in the specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings. To create and configure an XssMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateXssMatchSet request. Submit a CreateXssMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateXssMatchSet request. Submit an UpdateXssMatchSet request to specify the parts of web requests in which you want to allow, block, or count cross-site scripting attacks. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateXssMatchSet
export def "create-xss-match-set" [
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
  name: string # A friendly name or description for the XssMatchSet that you're creating. You can't change Name after you create the XssMatchSet.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<XssMatchSet: record<XssMatchSetId: string, Name: string, XssMatchTuples: list<record>>, ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.CreateXssMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a ByteMatchSet. You can't delete a ByteMatchSet if it's still used in any Rules or if it still includes any ByteMatchTuple objects (any filters). If you just want to remove a ByteMatchSet from a Rule, use UpdateRule. To permanently delete a ByteMatchSet, perform the following steps: Update the ByteMatchSet to remove filters, if any. For more information, see UpdateByteMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteByteMatchSet request. Submit a DeleteByteMatchSet request.
#
# POST /
# operationId: DeleteByteMatchSet
export def "delete-byte-match-set" [
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
  byte_match_set_id: string # The ByteMatchSetId of the ByteMatchSet that you want to delete. ByteMatchSetId is returned by CreateByteMatchSet and by ListByteMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteByteMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ByteMatchSetId": $byte_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a GeoMatchSet. You can't delete a GeoMatchSet if it's still used in any Rules or if it still includes any countries. If you just want to remove a GeoMatchSet from a Rule, use UpdateRule. To permanently delete a GeoMatchSet from AWS WAF, perform the following steps: Update the GeoMatchSet to remove any countries. For more information, see UpdateGeoMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteGeoMatchSet request. Submit a DeleteGeoMatchSet request.
#
# POST /
# operationId: DeleteGeoMatchSet
export def "delete-geo-match-set" [
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
  geo_match_set_id: string # The GeoMatchSetID of the GeoMatchSet that you want to delete. GeoMatchSetId is returned by CreateGeoMatchSet and by ListGeoMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteGeoMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GeoMatchSetId": $geo_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes an IPSet. You can't delete an IPSet if it's still used in any Rules or if it still includes any IP addresses. If you just want to remove an IPSet from a Rule, use UpdateRule. To permanently delete an IPSet from AWS WAF, perform the following steps: Update the IPSet to remove IP address ranges, if any. For more information, see UpdateIPSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteIPSet request. Submit a DeleteIPSet request.
#
# POST /
# operationId: DeleteIPSet
export def "delete-ip-set" [
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
  ip_set_id: string # The IPSetId of the IPSet that you want to delete. IPSetId is returned by CreateIPSet and by ListIPSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteIPSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"IPSetId": $ip_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes the LoggingConfiguration from the specified web ACL.
#
# POST /
# operationId: DeleteLoggingConfiguration
export def "delete-logging-configuration" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the web ACL from which you want to delete the LoggingConfiguration.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteLoggingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes an IAM policy from the specified RuleGroup. The user making the request must be the owner of the RuleGroup.
#
# POST /
# operationId: DeletePermissionPolicy
export def "delete-permission-policy" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the RuleGroup from which you want to delete the policy. The user making the request must be the owner of the RuleGroup.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeletePermissionPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a RateBasedRule. You can't delete a rule if it's still used in any WebACL objects or if it still includes any predicates, such as ByteMatchSet objects. If you just want to remove a rule from a WebACL, use UpdateWebACL. To permanently delete a RateBasedRule from AWS WAF, perform the following steps: Update the RateBasedRule to remove predicates, if any. For more information, see UpdateRateBasedRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteRateBasedRule request. Submit a DeleteRateBasedRule request.
#
# POST /
# operationId: DeleteRateBasedRule
export def "delete-rate-based-rule" [
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
  rule_id: string # The RuleId of the RateBasedRule that you want to delete. RuleId is returned by CreateRateBasedRule and by ListRateBasedRules.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteRateBasedRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a RegexMatchSet. You can't delete a RegexMatchSet if it's still used in any Rules or if it still includes any RegexMatchTuples objects (any filters). If you just want to remove a RegexMatchSet from a Rule, use UpdateRule. To permanently delete a RegexMatchSet, perform the following steps: Update the RegexMatchSet to remove filters, if any. For more information, see UpdateRegexMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteRegexMatchSet request. Submit a DeleteRegexMatchSet request.
#
# POST /
# operationId: DeleteRegexMatchSet
export def "delete-regex-match-set" [
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
  regex_match_set_id: string # The RegexMatchSetId of the RegexMatchSet that you want to delete. RegexMatchSetId is returned by CreateRegexMatchSet and by ListRegexMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteRegexMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexMatchSetId": $regex_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a RegexPatternSet. You can't delete a RegexPatternSet if it's still used in any RegexMatchSet or if the RegexPatternSet is not empty.
#
# POST /
# operationId: DeleteRegexPatternSet
export def "delete-regex-pattern-set" [
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
  regex_pattern_set_id: string # The RegexPatternSetId of the RegexPatternSet that you want to delete. RegexPatternSetId is returned by CreateRegexPatternSet and by ListRegexPatternSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteRegexPatternSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexPatternSetId": $regex_pattern_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a Rule. You can't delete a Rule if it's still used in any WebACL objects or if it still includes any predicates, such as ByteMatchSet objects. If you just want to remove a Rule from a WebACL, use UpdateWebACL. To permanently delete a Rule from AWS WAF, perform the following steps: Update the Rule to remove predicates, if any. For more information, see UpdateRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteRule request. Submit a DeleteRule request.
#
# POST /
# operationId: DeleteRule
export def "delete-rule" [
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
  rule_id: string # The RuleId of the Rule that you want to delete. RuleId is returned by CreateRule and by ListRules.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a RuleGroup. You can't delete a RuleGroup if it's still used in any WebACL objects or if it still includes any rules. If you just want to remove a RuleGroup from a WebACL, use UpdateWebACL. To permanently delete a RuleGroup from AWS WAF, perform the following steps: Update the RuleGroup to remove rules, if any. For more information, see UpdateRuleGroup. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteRuleGroup request. Submit a DeleteRuleGroup request.
#
# POST /
# operationId: DeleteRuleGroup
export def "delete-rule-group" [
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
  rule_group_id: string # The RuleGroupId of the RuleGroup that you want to delete. RuleGroupId is returned by CreateRuleGroup and by ListRuleGroups.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupId": $rule_group_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a SizeConstraintSet. You can't delete a SizeConstraintSet if it's still used in any Rules or if it still includes any SizeConstraint objects (any filters). If you just want to remove a SizeConstraintSet from a Rule, use UpdateRule. To permanently delete a SizeConstraintSet, perform the following steps: Update the SizeConstraintSet to remove filters, if any. For more information, see UpdateSizeConstraintSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteSizeConstraintSet request. Submit a DeleteSizeConstraintSet request.
#
# POST /
# operationId: DeleteSizeConstraintSet
export def "delete-size-constraint-set" [
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
  size_constraint_set_id: string # The SizeConstraintSetId of the SizeConstraintSet that you want to delete. SizeConstraintSetId is returned by CreateSizeConstraintSet and by ListSizeConstraintSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteSizeConstraintSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SizeConstraintSetId": $size_constraint_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a SqlInjectionMatchSet. You can't delete a SqlInjectionMatchSet if it's still used in any Rules or if it still contains any SqlInjectionMatchTuple objects. If you just want to remove a SqlInjectionMatchSet from a Rule, use UpdateRule. To permanently delete a SqlInjectionMatchSet from AWS WAF, perform the following steps: Update the SqlInjectionMatchSet to remove filters, if any. For more information, see UpdateSqlInjectionMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteSqlInjectionMatchSet request. Submit a DeleteSqlInjectionMatchSet request.
#
# POST /
# operationId: DeleteSqlInjectionMatchSet
export def "delete-sql-injection-match-set" [
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
  sql_injection_match_set_id: string # The SqlInjectionMatchSetId of the SqlInjectionMatchSet that you want to delete. SqlInjectionMatchSetId is returned by CreateSqlInjectionMatchSet and by ListSqlInjectionMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteSqlInjectionMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SqlInjectionMatchSetId": $sql_injection_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a WebACL. You can't delete a WebACL if it still contains any Rules. To delete a WebACL, perform the following steps: Update the WebACL to remove Rules, if any. For more information, see UpdateWebACL. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteWebACL request. Submit a DeleteWebACL request.
#
# POST /
# operationId: DeleteWebACL
export def "delete-web-acl" [
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
  web_acl_id: string # The WebACLId of the WebACL that you want to delete. WebACLId is returned by CreateWebACL and by ListWebACLs.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLId": $web_acl_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes an XssMatchSet. You can't delete an XssMatchSet if it's still used in any Rules or if it still contains any XssMatchTuple objects. If you just want to remove an XssMatchSet from a Rule, use UpdateRule. To permanently delete an XssMatchSet from AWS WAF, perform the following steps: Update the XssMatchSet to remove filters, if any. For more information, see UpdateXssMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteXssMatchSet request. Submit a DeleteXssMatchSet request.
#
# POST /
# operationId: DeleteXssMatchSet
export def "delete-xss-match-set" [
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
  xss_match_set_id: string # The XssMatchSetId of the XssMatchSet that you want to delete. XssMatchSetId is returned by CreateXssMatchSet and by ListXssMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.DeleteXssMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"XssMatchSetId": $xss_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the ByteMatchSet specified by ByteMatchSetId.
#
# POST /
# operationId: GetByteMatchSet
export def "get-byte-match-set" [
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
  byte_match_set_id: string # The ByteMatchSetId of the ByteMatchSet that you want to get. ByteMatchSetId is returned by CreateByteMatchSet and by ListByteMatchSets.
]: any -> oneof<record<ByteMatchSet: record<ByteMatchSetId: string, Name: string, ByteMatchTuples: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetByteMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ByteMatchSetId": $byte_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. When you want to create, update, or delete AWS WAF objects, get a change token and include the change token in the create, update, or delete request. Change tokens ensure that your application doesn't submit conflicting requests to AWS WAF. Each create, update, or delete request must use a unique change token. If your application submits a GetChangeToken request and then submits a second GetChangeToken request before submitting a create, update, or delete request, the second GetChangeToken request returns the same value as the first GetChangeToken request. When you use a change token in a create, update, or delete request, the status of the change token changes to PENDING, which indicates that AWS WAF is propagating the change to all AWS WAF servers. Use GetChangeTokenStatus to determine the status of your change token.
#
# POST /
# operationId: GetChangeToken
export def "get-change-token" [
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
  --body: record
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetChangeToken")
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the status of a ChangeToken that you got by calling GetChangeToken. ChangeTokenStatus is one of the following values: PROVISIONED: You requested the change token by calling GetChangeToken, but you haven't used it yet in a call to create, update, or delete an AWS WAF object. PENDING: AWS WAF is propagating the create, update, or delete request to all AWS WAF servers. INSYNC: Propagation is complete.
#
# POST /
# operationId: GetChangeTokenStatus
export def "get-change-token-status" [
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
  change_token: string # The change token for which you want to get the status. This change token was previously returned in the GetChangeToken response.
]: any -> oneof<record<ChangeTokenStatus: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetChangeTokenStatus")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the GeoMatchSet that is specified by GeoMatchSetId.
#
# POST /
# operationId: GetGeoMatchSet
export def "get-geo-match-set" [
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
  geo_match_set_id: string # The GeoMatchSetId of the GeoMatchSet that you want to get. GeoMatchSetId is returned by CreateGeoMatchSet and by ListGeoMatchSets.
]: any -> oneof<record<GeoMatchSet: record<GeoMatchSetId: string, Name: string, GeoMatchConstraints: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetGeoMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GeoMatchSetId": $geo_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the IPSet that is specified by IPSetId.
#
# POST /
# operationId: GetIPSet
export def "get-ip-set" [
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
  ip_set_id: string # The IPSetId of the IPSet that you want to get. IPSetId is returned by CreateIPSet and by ListIPSets.
]: any -> oneof<record<IPSet: record<IPSetId: string, Name: string, IPSetDescriptors: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetIPSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"IPSetId": $ip_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the LoggingConfiguration for the specified web ACL.
#
# POST /
# operationId: GetLoggingConfiguration
export def "get-logging-configuration" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the web ACL for which you want to get the LoggingConfiguration.
]: any -> oneof<record<LoggingConfiguration: record<ResourceArn: string, LogDestinationConfigs: list<string>, RedactedFields: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetLoggingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the IAM policy attached to the RuleGroup.
#
# POST /
# operationId: GetPermissionPolicy
export def "get-permission-policy" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the RuleGroup for which you want to get the policy.
]: any -> oneof<record<Policy: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetPermissionPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the RateBasedRule that is specified by the RuleId that you included in the GetRateBasedRule request.
#
# POST /
# operationId: GetRateBasedRule
export def "get-rate-based-rule" [
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
  rule_id: string # The RuleId of the RateBasedRule that you want to get. RuleId is returned by CreateRateBasedRule and by ListRateBasedRules.
]: any -> oneof<record<Rule: record<RuleId: string, Name: string, MetricName: string, MatchPredicates: list<record>, RateKey: string, RateLimit: int>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetRateBasedRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of IP addresses currently being blocked by the RateBasedRule that is specified by the RuleId. The maximum number of managed keys that will be blocked is 10,000. If more than 10,000 addresses exceed the rate limit, the 10,000 addresses with the highest rates will be blocked.
#
# POST /
# operationId: GetRateBasedRuleManagedKeys
export def "get-rate-based-rule-managed-keys" [
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
  rule_id: string # The RuleId of the RateBasedRule for which you want to get a list of ManagedKeys. RuleId is returned by CreateRateBasedRule and by ListRateBasedRules.
  --next-marker: string # A null value and not currently used. Do not include this in your request.
]: any -> oneof<record<ManagedKeys: list<string>, NextMarker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetRateBasedRuleManagedKeys")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "NextMarker": $next_marker} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the RegexMatchSet specified by RegexMatchSetId.
#
# POST /
# operationId: GetRegexMatchSet
export def "get-regex-match-set" [
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
  regex_match_set_id: string # The RegexMatchSetId of the RegexMatchSet that you want to get. RegexMatchSetId is returned by CreateRegexMatchSet and by ListRegexMatchSets.
]: any -> oneof<record<RegexMatchSet: record<RegexMatchSetId: string, Name: string, RegexMatchTuples: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetRegexMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexMatchSetId": $regex_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the RegexPatternSet specified by RegexPatternSetId.
#
# POST /
# operationId: GetRegexPatternSet
export def "get-regex-pattern-set" [
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
  --x-amz-target: string@x-amz-target-completer-37 # required
  regex_pattern_set_id: string # The RegexPatternSetId of the RegexPatternSet that you want to get. RegexPatternSetId is returned by CreateRegexPatternSet and by ListRegexPatternSets.
]: any -> oneof<record<RegexPatternSet: record<RegexPatternSetId: string, Name: string, RegexPatternStrings: list<string>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetRegexPatternSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexPatternSetId": $regex_pattern_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the Rule that is specified by the RuleId that you included in the GetRule request.
#
# POST /
# operationId: GetRule
export def "get-rule" [
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
  --x-amz-target: string@x-amz-target-completer-38 # required
  rule_id: string # The RuleId of the Rule that you want to get. RuleId is returned by CreateRule and by ListRules.
]: any -> oneof<record<Rule: record<RuleId: string, Name: string, MetricName: string, Predicates: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the RuleGroup that is specified by the RuleGroupId that you included in the GetRuleGroup request. To view the rules in a rule group, use ListActivatedRulesInRuleGroup.
#
# POST /
# operationId: GetRuleGroup
export def "get-rule-group" [
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
  --x-amz-target: string@x-amz-target-completer-39 # required
  rule_group_id: string # The RuleGroupId of the RuleGroup that you want to get. RuleGroupId is returned by CreateRuleGroup and by ListRuleGroups.
]: any -> oneof<record<RuleGroup: record<RuleGroupId: string, Name: string, MetricName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupId": $rule_group_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours. GetSampledRequests returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, GetSampledRequests returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.
#
# POST /
# operationId: GetSampledRequests
export def "get-sampled-requests" [
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
  web_acl_id: string # The WebACLId of the WebACL for which you want GetSampledRequests to return a sample of requests.
  rule_id: string # RuleId is one of three values: The RuleId of the Rule or the RuleGroupId of the RuleGroup for which you want GetSampledRequests to return a sample of requests. Default_Action, which causes GetSampledRequests to return a sample of the requests that didn't match any of the rules in the specified WebACL.
  time_window: record # This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. In a GetSampledRequests request, the StartTime and EndTime objects specify the time range for which you want AWS WAF to return a sample of web requests. You must specify the times in Coordinated Universal Time (UTC) format. UTC format includes the special designator, Z. For example, "2016-09-27T14:50Z". In a GetSampledRequests response, the StartTime and EndTime objects specify the time range for which AWS WAF actually returned a sample of web requests. AWS WAF gets the specified number of requests from among the first 5,000 requests that your AWS resource receives during the specified time period. If your resource receives more than 5,000 requests during that period, AWS WAF stops sampling after the 5,000th request. In that case, EndTime is the time that AWS WAF received the 5,000th request. — shape: {StartTime: string, EndTime: string}
  max_items: int # The number of requests that you want AWS WAF to return from among the first 5,000 requests that your AWS resource received during the time range. If your resource received fewer requests than the value of MaxItems, GetSampledRequests returns information about all of them.
]: any -> oneof<record<SampledRequests: table<Request: record, Weight: int, Timestamp: string, Action: string, RuleWithinRuleGroup: string>, PopulationSize: int, TimeWindow: record<StartTime: string, EndTime: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetSampledRequests")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebAclId": $web_acl_id, "RuleId": $rule_id, "TimeWindow": $time_window, "MaxItems": $max_items} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the SizeConstraintSet specified by SizeConstraintSetId.
#
# POST /
# operationId: GetSizeConstraintSet
export def "get-size-constraint-set" [
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
  size_constraint_set_id: string # The SizeConstraintSetId of the SizeConstraintSet that you want to get. SizeConstraintSetId is returned by CreateSizeConstraintSet and by ListSizeConstraintSets.
]: any -> oneof<record<SizeConstraintSet: record<SizeConstraintSetId: string, Name: string, SizeConstraints: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetSizeConstraintSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SizeConstraintSetId": $size_constraint_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the SqlInjectionMatchSet that is specified by SqlInjectionMatchSetId.
#
# POST /
# operationId: GetSqlInjectionMatchSet
export def "get-sql-injection-match-set" [
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
  sql_injection_match_set_id: string # The SqlInjectionMatchSetId of the SqlInjectionMatchSet that you want to get. SqlInjectionMatchSetId is returned by CreateSqlInjectionMatchSet and by ListSqlInjectionMatchSets.
]: any -> oneof<record<SqlInjectionMatchSet: record<SqlInjectionMatchSetId: string, Name: string, SqlInjectionMatchTuples: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetSqlInjectionMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SqlInjectionMatchSetId": $sql_injection_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the WebACL that is specified by WebACLId.
#
# POST /
# operationId: GetWebACL
export def "get-web-acl" [
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
  --x-amz-target: string@x-amz-target-completer-43 # required
  web_acl_id: string # The WebACLId of the WebACL that you want to get. WebACLId is returned by CreateWebACL and by ListWebACLs.
]: any -> oneof<record<WebACL: record<WebACLId: string, Name: string, MetricName: string, DefaultAction: record<Type: string>, Rules: list<record>, WebACLArn: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLId": $web_acl_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the XssMatchSet that is specified by XssMatchSetId.
#
# POST /
# operationId: GetXssMatchSet
export def "get-xss-match-set" [
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
  xss_match_set_id: string # The XssMatchSetId of the XssMatchSet that you want to get. XssMatchSetId is returned by CreateXssMatchSet and by ListXssMatchSets.
]: any -> oneof<record<XssMatchSet: record<XssMatchSetId: string, Name: string, XssMatchTuples: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.GetXssMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"XssMatchSetId": $xss_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of ActivatedRule objects.
#
# POST /
# operationId: ListActivatedRulesInRuleGroup
export def "list-activated-rules-in-rule-group" [
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
  --rule-group-id: string # The RuleGroupId of the RuleGroup for which you want to get a list of ActivatedRule objects.
  --next-marker: string # If you specify a value for Limit and you have more ActivatedRules than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of ActivatedRules. For the second and subsequent ListActivatedRulesInRuleGroup requests, specify the value of NextMarker from the previous response to get information about another batch of ActivatedRules.
  --limit: int # Specifies the number of ActivatedRules that you want AWS WAF to return for this request. If you have more ActivatedRules than the number that you specify for Limit, the response includes a NextMarker value that you can use to get another batch of ActivatedRules.
]: any -> oneof<record<NextMarker: string, ActivatedRules: table<Priority: int, RuleId: string, Action: record, OverrideAction: record, Type: string, ExcludedRules: list>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListActivatedRulesInRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupId": $rule_group_id, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of ByteMatchSetSummary objects.
#
# POST /
# operationId: ListByteMatchSets
export def "list-byte-match-sets" [
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
  --x-amz-target: string@x-amz-target-completer-46 # required
  --next-marker: string # If you specify a value for Limit and you have more ByteMatchSets than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of ByteMatchSets. For the second and subsequent ListByteMatchSets requests, specify the value of NextMarker from the previous response to get information about another batch of ByteMatchSets.
  --limit: int # Specifies the number of ByteMatchSet objects that you want AWS WAF to return for this request. If you have more ByteMatchSets objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of ByteMatchSet objects.
]: any -> oneof<record<NextMarker: string, ByteMatchSets: table<ByteMatchSetId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListByteMatchSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of GeoMatchSetSummary objects in the response.
#
# POST /
# operationId: ListGeoMatchSets
export def "list-geo-match-sets" [
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
  --x-amz-target: string@x-amz-target-completer-47 # required
  --next-marker: string # If you specify a value for Limit and you have more GeoMatchSets than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of GeoMatchSet objects. For the second and subsequent ListGeoMatchSets requests, specify the value of NextMarker from the previous response to get information about another batch of GeoMatchSet objects.
  --limit: int # Specifies the number of GeoMatchSet objects that you want AWS WAF to return for this request. If you have more GeoMatchSet objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of GeoMatchSet objects.
]: any -> oneof<record<NextMarker: string, GeoMatchSets: table<GeoMatchSetId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListGeoMatchSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of IPSetSummary objects in the response.
#
# POST /
# operationId: ListIPSets
export def "list-ip-sets" [
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
  --next-marker: string # AWS WAF returns a NextMarker value in the response that allows you to list another group of IPSets. For the second and subsequent ListIPSets requests, specify the value of NextMarker from the previous response to get information about another batch of IPSets.
  --limit: int # Specifies the number of IPSet objects that you want AWS WAF to return for this request. If you have more IPSet objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of IPSet objects.
]: any -> oneof<record<NextMarker: string, IPSets: table<IPSetId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListIPSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of LoggingConfiguration objects.
#
# POST /
# operationId: ListLoggingConfigurations
export def "list-logging-configurations" [
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
  --x-amz-target: string@x-amz-target-completer-49 # required
  --next-marker: string # If you specify a value for Limit and you have more LoggingConfigurations than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of LoggingConfigurations. For the second and subsequent ListLoggingConfigurations requests, specify the value of NextMarker from the previous response to get information about another batch of ListLoggingConfigurations.
  --limit: int # Specifies the number of LoggingConfigurations that you want AWS WAF to return for this request. If you have more LoggingConfigurations than the number that you specify for Limit, the response includes a NextMarker value that you can use to get another batch of LoggingConfigurations.
]: any -> oneof<record<LoggingConfigurations: table<ResourceArn: string, LogDestinationConfigs: list, RedactedFields: list>, NextMarker: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListLoggingConfigurations")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RuleSummary objects.
#
# POST /
# operationId: ListRateBasedRules
export def "list-rate-based-rules" [
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
  --x-amz-target: string@x-amz-target-completer-50 # required
  --next-marker: string # If you specify a value for Limit and you have more Rules than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of Rules. For the second and subsequent ListRateBasedRules requests, specify the value of NextMarker from the previous response to get information about another batch of Rules.
  --limit: int # Specifies the number of Rules that you want AWS WAF to return for this request. If you have more Rules than the number that you specify for Limit, the response includes a NextMarker value that you can use to get another batch of Rules.
]: any -> oneof<record<NextMarker: string, Rules: table<RuleId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListRateBasedRules")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RegexMatchSetSummary objects.
#
# POST /
# operationId: ListRegexMatchSets
export def "list-regex-match-sets" [
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
  --x-amz-target: string@x-amz-target-completer-51 # required
  --next-marker: string # If you specify a value for Limit and you have more RegexMatchSet objects than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of ByteMatchSets. For the second and subsequent ListRegexMatchSets requests, specify the value of NextMarker from the previous response to get information about another batch of RegexMatchSet objects.
  --limit: int # Specifies the number of RegexMatchSet objects that you want AWS WAF to return for this request. If you have more RegexMatchSet objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of RegexMatchSet objects.
]: any -> oneof<record<NextMarker: string, RegexMatchSets: table<RegexMatchSetId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListRegexMatchSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RegexPatternSetSummary objects.
#
# POST /
# operationId: ListRegexPatternSets
export def "list-regex-pattern-sets" [
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
  --next-marker: string # If you specify a value for Limit and you have more RegexPatternSet objects than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of RegexPatternSet objects. For the second and subsequent ListRegexPatternSets requests, specify the value of NextMarker from the previous response to get information about another batch of RegexPatternSet objects.
  --limit: int # Specifies the number of RegexPatternSet objects that you want AWS WAF to return for this request. If you have more RegexPatternSet objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of RegexPatternSet objects.
]: any -> oneof<record<NextMarker: string, RegexPatternSets: table<RegexPatternSetId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListRegexPatternSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RuleGroup objects.
#
# POST /
# operationId: ListRuleGroups
export def "list-rule-groups" [
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
  --x-amz-target: string@x-amz-target-completer-53 # required
  --next-marker: string # If you specify a value for Limit and you have more RuleGroups than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of RuleGroups. For the second and subsequent ListRuleGroups requests, specify the value of NextMarker from the previous response to get information about another batch of RuleGroups.
  --limit: int # Specifies the number of RuleGroups that you want AWS WAF to return for this request. If you have more RuleGroups than the number that you specify for Limit, the response includes a NextMarker value that you can use to get another batch of RuleGroups.
]: any -> oneof<record<NextMarker: string, RuleGroups: table<RuleGroupId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListRuleGroups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RuleSummary objects.
#
# POST /
# operationId: ListRules
export def "list-rules" [
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
  --x-amz-target: string@x-amz-target-completer-54 # required
  --next-marker: string # If you specify a value for Limit and you have more Rules than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of Rules. For the second and subsequent ListRules requests, specify the value of NextMarker from the previous response to get information about another batch of Rules.
  --limit: int # Specifies the number of Rules that you want AWS WAF to return for this request. If you have more Rules than the number that you specify for Limit, the response includes a NextMarker value that you can use to get another batch of Rules.
]: any -> oneof<record<NextMarker: string, Rules: table<RuleId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListRules")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of SizeConstraintSetSummary objects.
#
# POST /
# operationId: ListSizeConstraintSets
export def "list-size-constraint-sets" [
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
  --x-amz-target: string@x-amz-target-completer-55 # required
  --next-marker: string # If you specify a value for Limit and you have more SizeConstraintSets than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of SizeConstraintSets. For the second and subsequent ListSizeConstraintSets requests, specify the value of NextMarker from the previous response to get information about another batch of SizeConstraintSets.
  --limit: int # Specifies the number of SizeConstraintSet objects that you want AWS WAF to return for this request. If you have more SizeConstraintSets objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of SizeConstraintSet objects.
]: any -> oneof<record<NextMarker: string, SizeConstraintSets: table<SizeConstraintSetId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListSizeConstraintSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of SqlInjectionMatchSet objects.
#
# POST /
# operationId: ListSqlInjectionMatchSets
export def "list-sql-injection-match-sets" [
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
  --next-marker: string # If you specify a value for Limit and you have more SqlInjectionMatchSet objects than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of SqlInjectionMatchSets. For the second and subsequent ListSqlInjectionMatchSets requests, specify the value of NextMarker from the previous response to get information about another batch of SqlInjectionMatchSets.
  --limit: int # Specifies the number of SqlInjectionMatchSet objects that you want AWS WAF to return for this request. If you have more SqlInjectionMatchSet objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of Rules.
]: any -> oneof<record<NextMarker: string, SqlInjectionMatchSets: table<SqlInjectionMatchSetId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListSqlInjectionMatchSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RuleGroup objects that you are subscribed to.
#
# POST /
# operationId: ListSubscribedRuleGroups
export def "list-subscribed-rule-groups" [
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
  --x-amz-target: string@x-amz-target-completer-57 # required
  --next-marker: string # If you specify a value for Limit and you have more ByteMatchSetssubscribed rule groups than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of subscribed rule groups. For the second and subsequent ListSubscribedRuleGroupsRequest requests, specify the value of NextMarker from the previous response to get information about another batch of subscribed rule groups.
  --limit: int # Specifies the number of subscribed rule groups that you want AWS WAF to return for this request. If you have more objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of objects.
]: any -> oneof<record<NextMarker: string, RuleGroups: table<RuleGroupId: string, Name: string, MetricName: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListSubscribedRuleGroups")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Retrieves the tags associated with the specified AWS resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each AWS resource, up to 50 tags for a resource. Tagging is only available through the API, SDKs, and CLI. You can't manage or view tags through the AWS WAF Classic console. You can tag the AWS resources that you manage through AWS WAF Classic: web ACLs, rule groups, and rules.
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
  --x-amz-target: string@x-amz-target-completer-58 # required
  --next-marker: string
  --limit: int
  resource_arn: string
]: any -> oneof<record<NextMarker: string, TagInfoForResource: record<ResourceARN: string, TagList: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListTagsForResource")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit, "ResourceARN": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of WebACLSummary objects in the response.
#
# POST /
# operationId: ListWebACLs
export def "list-web-ac-ls" [
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
  --next-marker: string # If you specify a value for Limit and you have more WebACL objects than the number that you specify for Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of WebACL objects. For the second and subsequent ListWebACLs requests, specify the value of NextMarker from the previous response to get information about another batch of WebACL objects.
  --limit: int # Specifies the number of WebACL objects that you want AWS WAF to return for this request. If you have more WebACL objects than the number that you specify for Limit, the response includes a NextMarker value that you can use to get another batch of WebACL objects.
]: any -> oneof<record<NextMarker: string, WebACLs: table<WebACLId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListWebACLs")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of XssMatchSet objects.
#
# POST /
# operationId: ListXssMatchSets
export def "list-xss-match-sets" [
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
  --next-marker: string # If you specify a value for Limit and you have more XssMatchSet objects than the value of Limit, AWS WAF returns a NextMarker value in the response that allows you to list another group of XssMatchSets. For the second and subsequent ListXssMatchSets requests, specify the value of NextMarker from the previous response to get information about another batch of XssMatchSets.
  --limit: int # Specifies the number of XssMatchSet objects that you want AWS WAF to return for this request. If you have more XssMatchSet objects than the number you specify for Limit, the response includes a NextMarker value that you can use to get another batch of Rules.
]: any -> oneof<record<NextMarker: string, XssMatchSets: table<XssMatchSetId: string, Name: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.ListXssMatchSets")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Associates a LoggingConfiguration with a specified web ACL. You can access information about all traffic that AWS WAF inspects using the following steps: Create an Amazon Kinesis Data Firehose. Create the data firehose with a PUT source and in the region that you are operating. However, if you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). Do not create the data firehose using a Kinesis stream as your source. Associate that firehose to your web ACL using a PutLoggingConfiguration request. When you successfully enable logging using a PutLoggingConfiguration request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see Logging Web ACL Traffic Information (https://docs.aws.amazon.com/waf/latest/developerguide/logging.html) in the AWS WAF Developer Guide.
#
# POST /
# operationId: PutLoggingConfiguration
export def "put-logging-configuration" [
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
  logging_configuration: record # This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. The Amazon Kinesis Data Firehose, RedactedFields information, and the web ACL Amazon Resource Name (ARN). — shape: {ResourceArn: string, LogDestinationConfigs: list<string>, RedactedFields?: list}
]: any -> oneof<record<LoggingConfiguration: record<ResourceArn: string, LogDestinationConfigs: list<string>, RedactedFields: list<record>>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.PutLoggingConfiguration")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LoggingConfiguration": $logging_configuration} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Attaches an IAM policy to the specified resource. The only supported use for this action is to share a RuleGroup across accounts. The PutPermissionPolicy is subject to the following restrictions: You can attach only one policy with each PutPermissionPolicy request. The policy must include an Effect, Action and Principal. Effect must specify Allow. The Action in the policy must be waf:UpdateWebACL, waf-regional:UpdateWebACL, waf:GetRuleGroup and waf-regional:GetRuleGroup . Any extra or wildcard actions in the policy will be rejected. The policy cannot include a Resource parameter. The ARN in the request must be a valid WAF RuleGroup ARN and the RuleGroup must exist in the same region. The user making the request must be the owner of the RuleGroup. Your policy must be composed using IAM Policy version 2012-10-17. For more information, see IAM Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html). An example of a valid policy parameter is shown in the Examples section below.
#
# POST /
# operationId: PutPermissionPolicy
export def "put-permission-policy" [
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
  resource_arn: string # The Amazon Resource Name (ARN) of the RuleGroup to which you want to attach the policy.
  policy: string # The policy to attach to the specified RuleGroup.
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.PutPermissionPolicy")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Policy": $policy} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Associates tags with the specified AWS resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each AWS resource, up to 50 tags for a resource. Tagging is only available through the API, SDKs, and CLI. You can't manage or view tags through the AWS WAF Classic console. You can use this action to tag the AWS resources that you manage through AWS WAF Classic: web ACLs, rule groups, and rules.
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
  --x-amz-target: string@x-amz-target-completer-63 # required
  resource_arn: string
  tags: list # item shape: {Key: string, Value: string}
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.TagResource")
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use.
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
  --x-amz-target: string@x-amz-target-completer-64 # required
  resource_arn: string
  tag_keys: list<string>
]: any -> oneof<record, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UntagResource")
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes ByteMatchTuple objects (filters) in a ByteMatchSet. For each ByteMatchTuple object, you specify the following values: Whether to insert or delete the object from the array. If you want to change a ByteMatchSetUpdate object, you delete the existing object and add a new one. The part of a web request that you want AWS WAF to inspect, such as a query string or the value of the User-Agent header. The bytes (typically a string that corresponds with ASCII characters) that you want AWS WAF to look for. For more information, including how you specify the values for the AWS WAF API and the AWS CLI or SDKs, see TargetString in the ByteMatchTuple data type. Where to look, such as at the beginning or the end of a query string. Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string. For example, you can add a ByteMatchSetUpdate object that matches web requests in which User-Agent headers contain the string BadBot. You can then configure AWS WAF to block those requests. To create and configure a ByteMatchSet, perform the following steps: Create a ByteMatchSet. For more information, see CreateByteMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateByteMatchSet request. Submit an UpdateByteMatchSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateByteMatchSet
export def "update-byte-match-set" [
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
  byte_match_set_id: string # The ByteMatchSetId of the ByteMatchSet that you want to update. ByteMatchSetId is returned by CreateByteMatchSet and by ListByteMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  updates: list # An array of ByteMatchSetUpdate objects that you want to insert into or delete from a ByteMatchSet. For more information, see the applicable data types: ByteMatchSetUpdate: Contains Action and ByteMatchTuple ByteMatchTuple: Contains FieldToMatch, PositionalConstraint, TargetString, and TextTransformation FieldToMatch: Contains Data and Type — item shape: {Action: "INSERT"|"DELETE", ByteMatchTuple: record}
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateByteMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ByteMatchSetId": $byte_match_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes GeoMatchConstraint objects in an GeoMatchSet. For each GeoMatchConstraint object, you specify the following values: Whether to insert or delete the object from the array. If you want to change an GeoMatchConstraint object, you delete the existing object and add a new one. The Type. The only valid value for Type is Country. The Value, which is a two character code for the country to add to the GeoMatchConstraint object. Valid codes are listed in GeoMatchConstraint$Value. To create and configure an GeoMatchSet, perform the following steps: Submit a CreateGeoMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateGeoMatchSet request. Submit an UpdateGeoMatchSet request to specify the country that you want AWS WAF to watch for. When you update an GeoMatchSet, you specify the country that you want to add and/or the country that you want to delete. If you want to change a country, you delete the existing country and add the new one. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateGeoMatchSet
export def "update-geo-match-set" [
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
  geo_match_set_id: string # The GeoMatchSetId of the GeoMatchSet that you want to update. GeoMatchSetId is returned by CreateGeoMatchSet and by ListGeoMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  updates: list # An array of GeoMatchSetUpdate objects that you want to insert into or delete from an GeoMatchSet. For more information, see the applicable data types: GeoMatchSetUpdate: Contains Action and GeoMatchConstraint GeoMatchConstraint: Contains Type and Value You can have only one Type and Value per GeoMatchConstraint. To add multiple countries, include multiple GeoMatchSetUpdate objects in your request. — item shape: {Action: "INSERT"|"DELETE", GeoMatchConstraint: record}
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateGeoMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GeoMatchSetId": $geo_match_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes IPSetDescriptor objects in an IPSet. For each IPSetDescriptor object, you specify the following values: Whether to insert or delete the object from the array. If you want to change an IPSetDescriptor object, you delete the existing object and add a new one. The IP address version, IPv4 or IPv6. The IP address in CIDR notation, for example, 192.0.2.0/24 (for the range of IP addresses from 192.0.2.0 to 192.0.2.255) or 192.0.2.44/32 (for the individual IP address 192.0.2.44). AWS WAF supports IPv4 address ranges: /8 and any range between /16 through /32. AWS WAF supports IPv6 address ranges: /24, /32, /48, /56, /64, and /128. For more information about CIDR notation, see the Wikipedia entry Classless Inter-Domain Routing (https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). IPv6 addresses can be represented using any of the following formats: 1111:0000:0000:0000:0000:0000:0000:0111/128 1111:0:0:0:0:0:0:0111/128 1111::0111/128 1111::111/128 You use an IPSet to specify which web requests you want to allow or block based on the IP addresses that the requests originated from. For example, if you're receiving a lot of requests from one or a small number of IP addresses and you want to block the requests, you can create an IPSet that specifies those IP addresses, and then configure AWS WAF to block the requests. To create and configure an IPSet, perform the following steps: Submit a CreateIPSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateIPSet request. Submit an UpdateIPSet request to specify the IP addresses that you want AWS WAF to watch for. When you update an IPSet, you specify the IP addresses that you want to add and/or the IP addresses that you want to delete. If you want to change an IP address, you delete the existing IP address and add the new one. You can insert a maximum of 1000 addresses in a single request. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateIPSet
export def "update-ip-set" [
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
  ip_set_id: string # The IPSetId of the IPSet that you want to update. IPSetId is returned by CreateIPSet and by ListIPSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  updates: list # An array of IPSetUpdate objects that you want to insert into or delete from an IPSet. For more information, see the applicable data types: IPSetUpdate: Contains Action and IPSetDescriptor IPSetDescriptor: Contains Type and Value You can insert a maximum of 1000 addresses in a single request. — item shape: {Action: "INSERT"|"DELETE", IPSetDescriptor: record}
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateIPSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"IPSetId": $ip_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes Predicate objects in a rule and updates the RateLimit in the rule. Each Predicate object identifies a predicate, such as a ByteMatchSet or an IPSet, that specifies the web requests that you want to block or count. The RateLimit specifies the number of requests every five minutes that triggers the rule. If you add more than one predicate to a RateBasedRule, a request must match all the predicates and exceed the RateLimit to be counted or blocked. For example, suppose you add the following to a RateBasedRule: An IPSet that matches the IP address 192.0.2.44/32 A ByteMatchSet that matches BadBot in the User-Agent header Further, you specify a RateLimit of 1,000. You then add the RateBasedRule to a WebACL and specify that you want to block requests that satisfy the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 and the User-Agent header in the request must contain the value BadBot. Further, requests that match these two conditions much be received at a rate of more than 1,000 every five minutes. If the rate drops below this limit, AWS WAF no longer blocks the requests. As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a RateBasedRule: A ByteMatchSet with FieldToMatch of URI A PositionalConstraint of STARTS_WITH A TargetString of login Further, you specify a RateLimit of 1,000. By adding this RateBasedRule to a WebACL, you could limit requests to your login page without affecting the rest of your site.
#
# POST /
# operationId: UpdateRateBasedRule
export def "update-rate-based-rule" [
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
  --x-amz-target: string@x-amz-target-completer-68 # required
  rule_id: string # The RuleId of the RateBasedRule that you want to update. RuleId is returned by CreateRateBasedRule and by ListRateBasedRules.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  updates: list # An array of RuleUpdate objects that you want to insert into or delete from a RateBasedRule. — item shape: {Action: "INSERT"|"DELETE", Predicate: record}
  rate_limit: int # The maximum number of requests, which have an identical value in the field specified by the RateKey, allowed in a five-minute period. If the number of requests exceeds the RateLimit and the other predicates specified in the rule are also met, AWS WAF triggers the action that is specified for this rule.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateRateBasedRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "ChangeToken": $change_token, "Updates": $updates, "RateLimit": $rate_limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes RegexMatchTuple objects (filters) in a RegexMatchSet. For each RegexMatchSetUpdate object, you specify the following values: Whether to insert or delete the object from the array. If you want to change a RegexMatchSetUpdate object, you delete the existing object and add a new one. The part of a web request that you want AWS WAF to inspectupdate, such as a query string or the value of the User-Agent header. The identifier of the pattern (a regular expression) that you want AWS WAF to look for. For more information, see RegexPatternSet. Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string. For example, you can create a RegexPatternSet that matches any requests with User-Agent headers that contain the string B[a@]dB[o0]t. You can then configure AWS WAF to reject those requests. To create and configure a RegexMatchSet, perform the following steps: Create a RegexMatchSet. For more information, see CreateRegexMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRegexMatchSet request. Submit an UpdateRegexMatchSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the identifier of the RegexPatternSet that contain the regular expression patters you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateRegexMatchSet
export def "update-regex-match-set" [
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
  --x-amz-target: string@x-amz-target-completer-69 # required
  regex_match_set_id: string # The RegexMatchSetId of the RegexMatchSet that you want to update. RegexMatchSetId is returned by CreateRegexMatchSet and by ListRegexMatchSets.
  updates: list # An array of RegexMatchSetUpdate objects that you want to insert into or delete from a RegexMatchSet. For more information, see RegexMatchTuple. — item shape: {Action: "INSERT"|"DELETE", RegexMatchTuple: record}
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateRegexMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexMatchSetId": $regex_match_set_id, "Updates": $updates, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes RegexPatternString objects in a RegexPatternSet. For each RegexPatternString object, you specify the following values: Whether to insert or delete the RegexPatternString. The regular expression pattern that you want to insert or delete. For more information, see RegexPatternSet. For example, you can create a RegexPatternString such as B[a@]dB[o0]t. AWS WAF will match this RegexPatternString to: BadBot BadB0t B@dBot B@dB0t To create and configure a RegexPatternSet, perform the following steps: Create a RegexPatternSet. For more information, see CreateRegexPatternSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRegexPatternSet request. Submit an UpdateRegexPatternSet request to specify the regular expression pattern that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateRegexPatternSet
export def "update-regex-pattern-set" [
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
  regex_pattern_set_id: string # The RegexPatternSetId of the RegexPatternSet that you want to update. RegexPatternSetId is returned by CreateRegexPatternSet and by ListRegexPatternSets.
  updates: list # An array of RegexPatternSetUpdate objects that you want to insert into or delete from a RegexPatternSet. — item shape: {Action: "INSERT"|"DELETE", RegexPatternString: string}
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateRegexPatternSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexPatternSetId": $regex_pattern_set_id, "Updates": $updates, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes Predicate objects in a Rule. Each Predicate object identifies a predicate, such as a ByteMatchSet or an IPSet, that specifies the web requests that you want to allow, block, or count. If you add more than one predicate to a Rule, a request must match all of the specifications to be allowed, blocked, or counted. For example, suppose that you add the following to a Rule: A ByteMatchSet that matches the value BadBot in the User-Agent header An IPSet that matches the IP address 192.0.2.44 You then add the Rule to a WebACL and specify that you want to block requests that satisfy the Rule. For a request to be blocked, the User-Agent header in the request must contain the value BadBot and the request must originate from the IP address 192.0.2.44. To create and configure a Rule, perform the following steps: Create and update the predicates that you want to include in the Rule. Create the Rule. See CreateRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRule request. Submit an UpdateRule request to add predicates to the Rule. Create and update a WebACL that contains the Rule. See CreateWebACL. If you want to replace one ByteMatchSet or IPSet with another, you delete the existing one and add the new one. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateRule
export def "update-rule" [
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
  rule_id: string # The RuleId of the Rule that you want to update. RuleId is returned by CreateRule and by ListRules.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  updates: list # An array of RuleUpdate objects that you want to insert into or delete from a Rule. For more information, see the applicable data types: RuleUpdate: Contains Action and Predicate Predicate: Contains DataId, Negated, and Type FieldToMatch: Contains Data and Type — item shape: {Action: "INSERT"|"DELETE", Predicate: record}
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateRule")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes ActivatedRule objects in a RuleGroup. You can only insert REGULAR rules into a rule group. You can have a maximum of ten rules per rule group. To create and configure a RuleGroup, perform the following steps: Create and update the Rules that you want to include in the RuleGroup. See CreateRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRuleGroup request. Submit an UpdateRuleGroup request to add Rules to the RuleGroup. Create and update a WebACL that contains the RuleGroup. See CreateWebACL. If you want to replace one Rule with another, you delete the existing one and add the new one. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateRuleGroup
export def "update-rule-group" [
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
  rule_group_id: string # The RuleGroupId of the RuleGroup that you want to update. RuleGroupId is returned by CreateRuleGroup and by ListRuleGroups.
  updates: list # An array of RuleGroupUpdate objects that you want to insert into or delete from a RuleGroup. You can only insert REGULAR rules into a rule group. ActivatedRule|OverrideAction applies only when updating or adding a RuleGroup to a WebACL. In this case you do not use ActivatedRule|Action. For all other update requests, ActivatedRule|Action is used instead of ActivatedRule|OverrideAction. — item shape: {Action: "INSERT"|"DELETE", ActivatedRule: record}
  change_token: string # The value returned by the most recent call to GetChangeToken.
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateRuleGroup")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupId": $rule_group_id, "Updates": $updates, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes SizeConstraint objects (filters) in a SizeConstraintSet. For each SizeConstraint object, you specify the following values: Whether to insert or delete the object from the array. If you want to change a SizeConstraintSetUpdate object, you delete the existing object and add a new one. The part of a web request that you want AWS WAF to evaluate, such as the length of a query string or the length of the User-Agent header. Whether to perform any transformations on the request, such as converting it to lowercase, before checking its length. Note that transformations of the request body are not supported because the AWS resource forwards only the first 8192 bytes of your request to AWS WAF. You can only specify a single type of TextTransformation. A ComparisonOperator used for evaluating the selected part of the request against the specified Size, such as equals, greater than, less than, and so on. The length, in bytes, that you want AWS WAF to watch for in selected part of the request. The length is computed after applying the transformation. For example, you can add a SizeConstraintSetUpdate object that matches web requests in which the length of the User-Agent header is greater than 100 bytes. You can then configure AWS WAF to block those requests. To create and configure a SizeConstraintSet, perform the following steps: Create a SizeConstraintSet. For more information, see CreateSizeConstraintSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateSizeConstraintSet request. Submit an UpdateSizeConstraintSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateSizeConstraintSet
export def "update-size-constraint-set" [
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
  size_constraint_set_id: string # The SizeConstraintSetId of the SizeConstraintSet that you want to update. SizeConstraintSetId is returned by CreateSizeConstraintSet and by ListSizeConstraintSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  updates: list # An array of SizeConstraintSetUpdate objects that you want to insert into or delete from a SizeConstraintSet. For more information, see the applicable data types: SizeConstraintSetUpdate: Contains Action and SizeConstraint SizeConstraint: Contains FieldToMatch, TextTransformation, ComparisonOperator, and Size FieldToMatch: Contains Data and Type — item shape: {Action: "INSERT"|"DELETE", SizeConstraint: record}
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateSizeConstraintSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SizeConstraintSetId": $size_constraint_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes SqlInjectionMatchTuple objects (filters) in a SqlInjectionMatchSet. For each SqlInjectionMatchTuple object, you specify the following values: Action: Whether to insert the object into or delete the object from the array. To change a SqlInjectionMatchTuple, you delete the existing object and add a new one. FieldToMatch: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter. TextTransformation: Which text transformation, if any, to perform on the web request before inspecting the request for snippets of malicious SQL code. You can only specify a single type of TextTransformation. You use SqlInjectionMatchSet objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain snippets of SQL code in the query string and you want to block the requests, you can create a SqlInjectionMatchSet with the applicable settings, and then configure AWS WAF to block the requests. To create and configure a SqlInjectionMatchSet, perform the following steps: Submit a CreateSqlInjectionMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateIPSet request. Submit an UpdateSqlInjectionMatchSet request to specify the parts of web requests that you want AWS WAF to inspect for snippets of SQL code. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateSqlInjectionMatchSet
export def "update-sql-injection-match-set" [
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
  sql_injection_match_set_id: string # The SqlInjectionMatchSetId of the SqlInjectionMatchSet that you want to update. SqlInjectionMatchSetId is returned by CreateSqlInjectionMatchSet and by ListSqlInjectionMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  updates: list # An array of SqlInjectionMatchSetUpdate objects that you want to insert into or delete from a SqlInjectionMatchSet. For more information, see the applicable data types: SqlInjectionMatchSetUpdate: Contains Action and SqlInjectionMatchTuple SqlInjectionMatchTuple: Contains FieldToMatch and TextTransformation FieldToMatch: Contains Data and Type — item shape: {Action: "INSERT"|"DELETE", SqlInjectionMatchTuple: record}
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateSqlInjectionMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SqlInjectionMatchSetId": $sql_injection_match_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes ActivatedRule objects in a WebACL. Each Rule identifies web requests that you want to allow, block, or count. When you update a WebACL, you specify the following values: A default action for the WebACL, either ALLOW or BLOCK. AWS WAF performs the default action if a request doesn't match the criteria in any of the Rules in a WebACL. The Rules that you want to add or delete. If you want to replace one Rule with another, you delete the existing Rule and add the new one. For each Rule, whether you want AWS WAF to allow requests, block requests, or count requests that match the conditions in the Rule. The order in which you want AWS WAF to evaluate the Rules in a WebACL. If you add more than one Rule to a WebACL, AWS WAF evaluates each request against the Rules in order based on the value of Priority. (The Rule that has the lowest value for Priority is evaluated first.) When a web request matches all the predicates (such as ByteMatchSets and IPSets) in a Rule, AWS WAF immediately takes the corresponding action, allow or block, and doesn't evaluate the request against the remaining Rules in the WebACL, if any. To create and configure a WebACL, perform the following steps: Create and update the predicates that you want to include in Rules. For more information, see CreateByteMatchSet, UpdateByteMatchSet, CreateIPSet, UpdateIPSet, CreateSqlInjectionMatchSet, and UpdateSqlInjectionMatchSet. Create and update the Rules that you want to include in the WebACL. For more information, see CreateRule and UpdateRule. Create a WebACL. See CreateWebACL. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateWebACL request. Submit an UpdateWebACL request to specify the Rules that you want to include in the WebACL, to specify the default action, and to associate the WebACL with a CloudFront distribution. The ActivatedRule can be a rule group. If you specify a rule group as your ActivatedRule , you can exclude specific rules from that rule group. If you already have a rule group associated with a web ACL and want to submit an UpdateWebACL request to exclude certain rules from that rule group, you must first remove the rule group from the web ACL, the re-insert it again, specifying the excluded rules. For details, see ActivatedRule$ExcludedRules . Be aware that if you try to add a RATE_BASED rule to a web ACL without setting the rule type when first creating the rule, the UpdateWebACL request will fail because the request tries to add a REGULAR rule (the default rule type) with the specified ID, which does not exist. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateWebACL
export def "update-web-acl" [
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
  web_acl_id: string # The WebACLId of the WebACL that you want to update. WebACLId is returned by CreateWebACL and by ListWebACLs.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  --updates: list # An array of updates to make to the WebACL. An array of WebACLUpdate objects that you want to insert into or delete from a WebACL. For more information, see the applicable data types: WebACLUpdate: Contains Action and ActivatedRule ActivatedRule: Contains Action, OverrideAction, Priority, RuleId, and Type. ActivatedRule|OverrideAction applies only when updating or adding a RuleGroup to a WebACL. In this case, you do not use ActivatedRule|Action. For all other update requests, ActivatedRule|Action is used instead of ActivatedRule|OverrideAction. WafAction: Contains Type — item shape: {Action: "INSERT"|"DELETE", ActivatedRule: record}
  --default-action: record # This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. For the action that is associated with a rule in a WebACL, specifies the action that you want AWS WAF to perform when a web request matches all of the conditions in a rule. For the default action in a WebACL, specifies the action that you want AWS WAF to take when a web request doesn't match all of the conditions in any of the rules in a WebACL. — shape: {Type: "BLOCK"|"ALLOW"|"COUNT"}
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateWebACL")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLId": $web_acl_id, "ChangeToken": $change_token, "Updates": $updates, "DefaultAction": $default_action} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes XssMatchTuple objects (filters) in an XssMatchSet. For each XssMatchTuple object, you specify the following values: Action: Whether to insert the object into or delete the object from the array. To change an XssMatchTuple, you delete the existing object and add a new one. FieldToMatch: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter. TextTransformation: Which text transformation, if any, to perform on the web request before inspecting the request for cross-site scripting attacks. You can only specify a single type of TextTransformation. You use XssMatchSet objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain cross-site scripting attacks in the request body and you want to block the requests, you can create an XssMatchSet with the applicable settings, and then configure AWS WAF to block the requests. To create and configure an XssMatchSet, perform the following steps: Submit a CreateXssMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateIPSet request. Submit an UpdateXssMatchSet request to specify the parts of web requests that you want AWS WAF to inspect for cross-site scripting attacks. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateXssMatchSet
export def "update-xss-match-set" [
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
  xss_match_set_id: string # The XssMatchSetId of the XssMatchSet that you want to update. XssMatchSetId is returned by CreateXssMatchSet and by ListXssMatchSets.
  change_token: string # The value returned by the most recent call to GetChangeToken.
  updates: list # An array of XssMatchSetUpdate objects that you want to insert into or delete from an XssMatchSet. For more information, see the applicable data types: XssMatchSetUpdate: Contains Action and XssMatchTuple XssMatchTuple: Contains FieldToMatch and TextTransformation FieldToMatch: Contains Data and Type — item shape: {Action: "INSERT"|"DELETE", XssMatchTuple: record}
]: any -> oneof<record<ChangeToken: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let x_amz_target = ($x_amz_target | default "AWSWAF_20150824.UpdateXssMatchSet")
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"XssMatchSetId": $xss_match_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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
