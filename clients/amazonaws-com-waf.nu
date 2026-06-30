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

def base-url-completer [] { ["https://waf.amazonaws.com" "http://waf.cn-north-1.amazonaws.com.cn" "http://waf.cn-northwest-1.amazonaws.com.cn" "https://waf.cn-north-1.amazonaws.com.cn" "https://waf.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def x-amz-target-completer [] { ["AWSWAF_20150824.CreateByteMatchSet"] }
def x-amz-target-completer-1 [] { ["AWSWAF_20150824.CreateGeoMatchSet"] }
def x-amz-target-completer-2 [] { ["AWSWAF_20150824.CreateIPSet"] }
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "api create-byte-match-update" } } | get name | first)
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a ByteMatchSet. You then use UpdateByteMatchSet to identify the part of a web request that you want AWS WAF to inspect, such as the values of the User-Agent header or the query string. For example, you can create a ByteMatchSet that matches any requests with User-Agent headers that contain the string BadBot. You can then configure AWS WAF to reject those requests. To create and configure a ByteMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateByteMatchSet request. Submit a CreateByteMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateByteMatchSet request. Submit an UpdateByteMatchSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateByteMatchSet
export def "api create-byte-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: any
  change_token: any
]: any -> record<ByteMatchSet: record<ByteMatchSetId: record, Name: record, ByteMatchTuples: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates an GeoMatchSet, which you use to specify which web requests you want to allow or block based on the country that the requests originate from. For example, if you're receiving a lot of requests from one or more countries and you want to block the requests, you can create an GeoMatchSet that contains those countries and then configure AWS WAF to block the requests. To create and configure a GeoMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateGeoMatchSet request. Submit a CreateGeoMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateGeoMatchSet request. Submit an UpdateGeoMatchSetSet request to specify the countries that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateGeoMatchSet
export def "api create-geo-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: any
  change_token: any
]: any -> record<GeoMatchSet: record<GeoMatchSetId: record, Name: record, GeoMatchConstraints: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates an IPSet, which you use to specify which web requests that you want to allow or block based on the IP addresses that the requests originate from. For example, if you're receiving a lot of requests from one or more individual IP addresses or one or more ranges of IP addresses and you want to block the requests, you can create an IPSet that contains those IP addresses and then configure AWS WAF to block the requests. To create and configure an IPSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateIPSet request. Submit a CreateIPSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateIPSet request. Submit an UpdateIPSet request to specify the IP addresses that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateIPSet
export def "api create-ip-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  change_token: any
]: any -> record<IPSet: record<IPSetId: record, Name: record, IPSetDescriptors: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a RateBasedRule. The RateBasedRule contains a RateLimit, which specifies the maximum number of requests that AWS WAF allows from a specified IP address in a five-minute period. The RateBasedRule also contains the IPSet objects, ByteMatchSet objects, and other predicates that identify the requests that you want to count or block if these requests exceed the RateLimit. If you add more than one predicate to a RateBasedRule, a request not only must exceed the RateLimit, but it also must match all the conditions to be counted or blocked. For example, suppose you add the following to a RateBasedRule: An IPSet that matches the IP address 192.0.2.44/32 A ByteMatchSet that matches BadBot in the User-Agent header Further, you specify a RateLimit of 1,000. You then add the RateBasedRule to a WebACL and specify that you want to block requests that meet the conditions in the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 and the User-Agent header in the request must contain the value BadBot. Further, requests that match these two conditions must be received at a rate of more than 1,000 requests every five minutes. If both conditions are met and the rate is exceeded, AWS WAF blocks the requests. If the rate drops below 1,000 for a five-minute period, AWS WAF no longer blocks the requests. As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a RateBasedRule: A ByteMatchSet with FieldToMatch of URI A PositionalConstraint of STARTS_WITH A TargetString of login Further, you specify a RateLimit of 1,000. By adding this RateBasedRule to a WebACL, you could limit requests to your login page without affecting the rest of your site. To create and configure a RateBasedRule, perform the following steps: Create and update the predicates that you want to include in the rule. For more information, see CreateByteMatchSet, CreateIPSet, and CreateSqlInjectionMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateRule request. Submit a CreateRateBasedRule request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRule request. Submit an UpdateRateBasedRule request to specify the predicates that you want to include in the rule. Create and update a WebACL that contains the RateBasedRule. For more information, see CreateWebACL. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRateBasedRule
export def "api create-rate-based-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: any
  metric_name: any
  rate_key: any
  rate_limit: any
  change_token: any
  --tags: any
]: any -> record<Rule: record<RuleId: record, Name: record, MetricName: record, MatchPredicates: record, RateKey: record, RateLimit: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "MetricName": $metric_name, "RateKey": $rate_key, "RateLimit": $rate_limit, "ChangeToken": $change_token, "Tags": $tags} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a RegexMatchSet. You then use UpdateRegexMatchSet to identify the part of a web request that you want AWS WAF to inspect, such as the values of the User-Agent header or the query string. For example, you can create a RegexMatchSet that contains a RegexMatchTuple that looks for any requests with User-Agent headers that match a RegexPatternSet with pattern B[a@]dB[o0]t. You can then configure AWS WAF to reject those requests. To create and configure a RegexMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateRegexMatchSet request. Submit a CreateRegexMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRegexMatchSet request. Submit an UpdateRegexMatchSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value, using a RegexPatternSet, that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRegexMatchSet
export def "api create-regex-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  change_token: any
]: any -> record<RegexMatchSet: record<RegexMatchSetId: record, Name: record, RegexMatchTuples: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a RegexPatternSet. You then use UpdateRegexPatternSet to specify the regular expression (regex) pattern that you want AWS WAF to search for, such as B[a@]dB[o0]t. You can then configure AWS WAF to reject those requests. To create and configure a RegexPatternSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateRegexPatternSet request. Submit a CreateRegexPatternSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRegexPatternSet request. Submit an UpdateRegexPatternSet request to specify the string that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRegexPatternSet
export def "api create-regex-pattern-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: any
  change_token: any
]: any -> record<RegexPatternSet: record<RegexPatternSetId: record, Name: record, RegexPatternStrings: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a Rule, which contains the IPSet objects, ByteMatchSet objects, and other predicates that identify the requests that you want to block. If you add more than one predicate to a Rule, a request must match all of the specifications to be allowed or blocked. For example, suppose that you add the following to a Rule: An IPSet that matches the IP address 192.0.2.44/32 A ByteMatchSet that matches BadBot in the User-Agent header You then add the Rule to a WebACL and specify that you want to blocks requests that satisfy the Rule. For a request to be blocked, it must come from the IP address 192.0.2.44 and the User-Agent header in the request must contain the value BadBot. To create and configure a Rule, perform the following steps: Create and update the predicates that you want to include in the Rule. For more information, see CreateByteMatchSet, CreateIPSet, and CreateSqlInjectionMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateRule request. Submit a CreateRule request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRule request. Submit an UpdateRule request to specify the predicates that you want to include in the Rule. Create and update a WebACL that contains the Rule. For more information, see CreateWebACL. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRule
export def "api create-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: any
  metric_name: any
  change_token: any
  --tags: any
]: any -> record<Rule: record<RuleId: record, Name: record, MetricName: record, Predicates: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "MetricName": $metric_name, "ChangeToken": $change_token, "Tags": $tags} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a RuleGroup. A rule group is a collection of predefined rules that you add to a web ACL. You use UpdateRuleGroup to add rules to the rule group. Rule groups are subject to the following limits: Three rule groups per account. You can request an increase to this limit by contacting customer support. One rule group per web ACL. Ten rules per rule group. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateRuleGroup
export def "api create-rule-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: any
  metric_name: any
  change_token: any
  --tags: any
]: any -> record<RuleGroup: record<RuleGroupId: record, Name: record, MetricName: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "MetricName": $metric_name, "ChangeToken": $change_token, "Tags": $tags} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a SizeConstraintSet. You then use UpdateSizeConstraintSet to identify the part of a web request that you want AWS WAF to check for length, such as the length of the User-Agent header or the length of the query string. For example, you can create a SizeConstraintSet that matches any requests that have a query string that is longer than 100 bytes. You can then configure AWS WAF to reject those requests. To create and configure a SizeConstraintSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateSizeConstraintSet request. Submit a CreateSizeConstraintSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateSizeConstraintSet request. Submit an UpdateSizeConstraintSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateSizeConstraintSet
export def "api create-size-constraint-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  change_token: any
]: any -> record<SizeConstraintSet: record<SizeConstraintSetId: record, Name: record, SizeConstraints: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a SqlInjectionMatchSet, which you use to allow, block, or count requests that contain snippets of SQL code in a specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings. To create and configure a SqlInjectionMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateSqlInjectionMatchSet request. Submit a CreateSqlInjectionMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateSqlInjectionMatchSet request. Submit an UpdateSqlInjectionMatchSet request to specify the parts of web requests in which you want to allow, block, or count malicious SQL code. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateSqlInjectionMatchSet
export def "api create-sql-injection-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: any
  change_token: any
]: any -> record<SqlInjectionMatchSet: record<SqlInjectionMatchSetId: record, Name: record, SqlInjectionMatchTuples: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates a WebACL, which contains the Rules that identify the CloudFront web requests that you want to allow, block, or count. AWS WAF evaluates Rules in order based on the value of Priority for each Rule. You also specify a default action, either ALLOW or BLOCK. If a web request doesn't match any of the Rules in a WebACL, AWS WAF responds to the request with the default action. To create and configure a WebACL, perform the following steps: Create and update the ByteMatchSet objects and other predicates that you want to include in Rules. For more information, see CreateByteMatchSet, UpdateByteMatchSet, CreateIPSet, UpdateIPSet, CreateSqlInjectionMatchSet, and UpdateSqlInjectionMatchSet. Create and update the Rules that you want to include in the WebACL. For more information, see CreateRule and UpdateRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateWebACL request. Submit a CreateWebACL request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateWebACL request. Submit an UpdateWebACL request to specify the Rules that you want to include in the WebACL, to specify the default action, and to associate the WebACL with a CloudFront distribution. For more information about how to use the AWS WAF API, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateWebACL
export def "api create-web-acl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  metric_name: any
  default_action: any
  change_token: any
  --tags: any
]: any -> record<WebACL: record<WebACLId: record, Name: record, MetricName: record, DefaultAction: record<Type: record>, Rules: record, WebACLArn: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "MetricName": $metric_name, "DefaultAction": $default_action, "ChangeToken": $change_token, "Tags": $tags} | compact
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

# Creates an AWS CloudFormation WAFV2 template for the specified web ACL in the specified Amazon S3 bucket. Then, in CloudFormation, you create a stack from the template, to create the web ACL and its resources in AWS WAFV2. Use this to migrate your AWS WAF Classic web ACL to the latest version of AWS WAF. This is part of a larger migration procedure for web ACLs from AWS WAF Classic to the latest version of AWS WAF. For the full procedure, including caveats and manual steps to complete the migration and switch over to the new web ACL, see Migrating your AWS WAF Classic resources to AWS WAF (https://docs.aws.amazon.com/waf/latest/developerguide/waf-migrating-from-classic.html) in the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html).
#
# POST /
# operationId: CreateWebACLMigrationStack
export def "api create-web-acl-migration-stack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  web_acl_id: any
  s3_bucket_name: any
  ignore_unsupported_type: any
]: any -> record<S3ObjectUrl: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLId": $web_acl_id, "S3BucketName": $s3_bucket_name, "IgnoreUnsupportedType": $ignore_unsupported_type} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Creates an XssMatchSet, which you use to allow, block, or count requests that contain cross-site scripting attacks in the specified part of web requests. AWS WAF searches for character sequences that are likely to be malicious strings. To create and configure an XssMatchSet, perform the following steps: Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a CreateXssMatchSet request. Submit a CreateXssMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateXssMatchSet request. Submit an UpdateXssMatchSet request to specify the parts of web requests in which you want to allow, block, or count cross-site scripting attacks. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: CreateXssMatchSet
export def "api create-xss-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  name: any
  change_token: any
]: any -> record<XssMatchSet: record<XssMatchSetId: record, Name: record, XssMatchTuples: record>, ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"Name": $name, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a ByteMatchSet. You can't delete a ByteMatchSet if it's still used in any Rules or if it still includes any ByteMatchTuple objects (any filters). If you just want to remove a ByteMatchSet from a Rule, use UpdateRule. To permanently delete a ByteMatchSet, perform the following steps: Update the ByteMatchSet to remove filters, if any. For more information, see UpdateByteMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteByteMatchSet request. Submit a DeleteByteMatchSet request.
#
# POST /
# operationId: DeleteByteMatchSet
export def "api delete-byte-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  byte_match_set_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ByteMatchSetId": $byte_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a GeoMatchSet. You can't delete a GeoMatchSet if it's still used in any Rules or if it still includes any countries. If you just want to remove a GeoMatchSet from a Rule, use UpdateRule. To permanently delete a GeoMatchSet from AWS WAF, perform the following steps: Update the GeoMatchSet to remove any countries. For more information, see UpdateGeoMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteGeoMatchSet request. Submit a DeleteGeoMatchSet request.
#
# POST /
# operationId: DeleteGeoMatchSet
export def "api delete-geo-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  geo_match_set_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GeoMatchSetId": $geo_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes an IPSet. You can't delete an IPSet if it's still used in any Rules or if it still includes any IP addresses. If you just want to remove an IPSet from a Rule, use UpdateRule. To permanently delete an IPSet from AWS WAF, perform the following steps: Update the IPSet to remove IP address ranges, if any. For more information, see UpdateIPSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteIPSet request. Submit a DeleteIPSet request.
#
# POST /
# operationId: DeleteIPSet
export def "api delete-ip-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ip_set_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"IPSetId": $ip_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes the LoggingConfiguration from the specified web ACL.
#
# POST /
# operationId: DeleteLoggingConfiguration
export def "api delete-logging-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes an IAM policy from the specified RuleGroup. The user making the request must be the owner of the RuleGroup.
#
# POST /
# operationId: DeletePermissionPolicy
export def "api delete-permission-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a RateBasedRule. You can't delete a rule if it's still used in any WebACL objects or if it still includes any predicates, such as ByteMatchSet objects. If you just want to remove a rule from a WebACL, use UpdateWebACL. To permanently delete a RateBasedRule from AWS WAF, perform the following steps: Update the RateBasedRule to remove predicates, if any. For more information, see UpdateRateBasedRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteRateBasedRule request. Submit a DeleteRateBasedRule request.
#
# POST /
# operationId: DeleteRateBasedRule
export def "api delete-rate-based-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  rule_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a RegexMatchSet. You can't delete a RegexMatchSet if it's still used in any Rules or if it still includes any RegexMatchTuples objects (any filters). If you just want to remove a RegexMatchSet from a Rule, use UpdateRule. To permanently delete a RegexMatchSet, perform the following steps: Update the RegexMatchSet to remove filters, if any. For more information, see UpdateRegexMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteRegexMatchSet request. Submit a DeleteRegexMatchSet request.
#
# POST /
# operationId: DeleteRegexMatchSet
export def "api delete-regex-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  regex_match_set_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexMatchSetId": $regex_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a RegexPatternSet. You can't delete a RegexPatternSet if it's still used in any RegexMatchSet or if the RegexPatternSet is not empty.
#
# POST /
# operationId: DeleteRegexPatternSet
export def "api delete-regex-pattern-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  regex_pattern_set_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexPatternSetId": $regex_pattern_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a Rule. You can't delete a Rule if it's still used in any WebACL objects or if it still includes any predicates, such as ByteMatchSet objects. If you just want to remove a Rule from a WebACL, use UpdateWebACL. To permanently delete a Rule from AWS WAF, perform the following steps: Update the Rule to remove predicates, if any. For more information, see UpdateRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteRule request. Submit a DeleteRule request.
#
# POST /
# operationId: DeleteRule
export def "api delete-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  rule_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a RuleGroup. You can't delete a RuleGroup if it's still used in any WebACL objects or if it still includes any rules. If you just want to remove a RuleGroup from a WebACL, use UpdateWebACL. To permanently delete a RuleGroup from AWS WAF, perform the following steps: Update the RuleGroup to remove rules, if any. For more information, see UpdateRuleGroup. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteRuleGroup request. Submit a DeleteRuleGroup request.
#
# POST /
# operationId: DeleteRuleGroup
export def "api delete-rule-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  rule_group_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupId": $rule_group_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a SizeConstraintSet. You can't delete a SizeConstraintSet if it's still used in any Rules or if it still includes any SizeConstraint objects (any filters). If you just want to remove a SizeConstraintSet from a Rule, use UpdateRule. To permanently delete a SizeConstraintSet, perform the following steps: Update the SizeConstraintSet to remove filters, if any. For more information, see UpdateSizeConstraintSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteSizeConstraintSet request. Submit a DeleteSizeConstraintSet request.
#
# POST /
# operationId: DeleteSizeConstraintSet
export def "api delete-size-constraint-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  size_constraint_set_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SizeConstraintSetId": $size_constraint_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a SqlInjectionMatchSet. You can't delete a SqlInjectionMatchSet if it's still used in any Rules or if it still contains any SqlInjectionMatchTuple objects. If you just want to remove a SqlInjectionMatchSet from a Rule, use UpdateRule. To permanently delete a SqlInjectionMatchSet from AWS WAF, perform the following steps: Update the SqlInjectionMatchSet to remove filters, if any. For more information, see UpdateSqlInjectionMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteSqlInjectionMatchSet request. Submit a DeleteSqlInjectionMatchSet request.
#
# POST /
# operationId: DeleteSqlInjectionMatchSet
export def "api delete-sql-injection-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  sql_injection_match_set_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SqlInjectionMatchSetId": $sql_injection_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes a WebACL. You can't delete a WebACL if it still contains any Rules. To delete a WebACL, perform the following steps: Update the WebACL to remove Rules, if any. For more information, see UpdateWebACL. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteWebACL request. Submit a DeleteWebACL request.
#
# POST /
# operationId: DeleteWebACL
export def "api delete-web-acl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  web_acl_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLId": $web_acl_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Permanently deletes an XssMatchSet. You can't delete an XssMatchSet if it's still used in any Rules or if it still contains any XssMatchTuple objects. If you just want to remove an XssMatchSet from a Rule, use UpdateRule. To permanently delete an XssMatchSet from AWS WAF, perform the following steps: Update the XssMatchSet to remove filters, if any. For more information, see UpdateXssMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of a DeleteXssMatchSet request. Submit a DeleteXssMatchSet request.
#
# POST /
# operationId: DeleteXssMatchSet
export def "api delete-xss-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  xss_match_set_id: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"XssMatchSetId": $xss_match_set_id, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the ByteMatchSet specified by ByteMatchSetId.
#
# POST /
# operationId: GetByteMatchSet
export def "api get-byte-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  byte_match_set_id: any
]: any -> record<ByteMatchSet: record<ByteMatchSetId: record, Name: record, ByteMatchTuples: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ByteMatchSetId": $byte_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. When you want to create, update, or delete AWS WAF objects, get a change token and include the change token in the create, update, or delete request. Change tokens ensure that your application doesn't submit conflicting requests to AWS WAF. Each create, update, or delete request must use a unique change token. If your application submits a GetChangeToken request and then submits a second GetChangeToken request before submitting a create, update, or delete request, the second GetChangeToken request returns the same value as the first GetChangeToken request. When you use a change token in a create, update, or delete request, the status of the change token changes to PENDING, which indicates that AWS WAF is propagating the change to all AWS WAF servers. Use GetChangeTokenStatus to determine the status of your change token.
#
# POST /
# operationId: GetChangeToken
export def "api get-change-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --body: record
]: any -> record<ChangeToken: record> {
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the status of a ChangeToken that you got by calling GetChangeToken. ChangeTokenStatus is one of the following values: PROVISIONED: You requested the change token by calling GetChangeToken, but you haven't used it yet in a call to create, update, or delete an AWS WAF object. PENDING: AWS WAF is propagating the create, update, or delete request to all AWS WAF servers. INSYNC: Propagation is complete.
#
# POST /
# operationId: GetChangeTokenStatus
export def "api get-change-token-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  change_token: any
]: any -> record<ChangeTokenStatus: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the GeoMatchSet that is specified by GeoMatchSetId.
#
# POST /
# operationId: GetGeoMatchSet
export def "api get-geo-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  geo_match_set_id: any
]: any -> record<GeoMatchSet: record<GeoMatchSetId: record, Name: record, GeoMatchConstraints: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GeoMatchSetId": $geo_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the IPSet that is specified by IPSetId.
#
# POST /
# operationId: GetIPSet
export def "api get-ip-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  ip_set_id: any
]: any -> record<IPSet: record<IPSetId: record, Name: record, IPSetDescriptors: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"IPSetId": $ip_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the LoggingConfiguration for the specified web ACL.
#
# POST /
# operationId: GetLoggingConfiguration
export def "api get-logging-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: any
]: any -> record<LoggingConfiguration: record<ResourceArn: record, LogDestinationConfigs: record, RedactedFields: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the IAM policy attached to the RuleGroup.
#
# POST /
# operationId: GetPermissionPolicy
export def "api get-permission-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: any
]: any -> record<Policy: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the RateBasedRule that is specified by the RuleId that you included in the GetRateBasedRule request.
#
# POST /
# operationId: GetRateBasedRule
export def "api get-rate-based-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  rule_id: any
]: any -> record<Rule: record<RuleId: record, Name: record, MetricName: record, MatchPredicates: record, RateKey: record, RateLimit: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of IP addresses currently being blocked by the RateBasedRule that is specified by the RuleId. The maximum number of managed keys that will be blocked is 10,000. If more than 10,000 addresses exceed the rate limit, the 10,000 addresses with the highest rates will be blocked.
#
# POST /
# operationId: GetRateBasedRuleManagedKeys
export def "api get-rate-based-rule-managed-keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  rule_id: any
  --next-marker: any
]: any -> record<ManagedKeys: record, NextMarker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "NextMarker": $next_marker} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the RegexMatchSet specified by RegexMatchSetId.
#
# POST /
# operationId: GetRegexMatchSet
export def "api get-regex-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-36
  regex_match_set_id: any
]: any -> record<RegexMatchSet: record<RegexMatchSetId: record, Name: record, RegexMatchTuples: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexMatchSetId": $regex_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the RegexPatternSet specified by RegexPatternSetId.
#
# POST /
# operationId: GetRegexPatternSet
export def "api get-regex-pattern-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-37
  regex_pattern_set_id: any
]: any -> record<RegexPatternSet: record<RegexPatternSetId: record, Name: record, RegexPatternStrings: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexPatternSetId": $regex_pattern_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the Rule that is specified by the RuleId that you included in the GetRule request.
#
# POST /
# operationId: GetRule
export def "api get-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-38
  rule_id: any
]: any -> record<Rule: record<RuleId: record, Name: record, MetricName: record, Predicates: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the RuleGroup that is specified by the RuleGroupId that you included in the GetRuleGroup request. To view the rules in a rule group, use ListActivatedRulesInRuleGroup.
#
# POST /
# operationId: GetRuleGroup
export def "api get-rule-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-39
  rule_group_id: any
]: any -> record<RuleGroup: record<RuleGroupId: record, Name: record, MetricName: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupId": $rule_group_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Gets detailed information about a specified number of requests--a sample--that AWS WAF randomly selects from among the first 5,000 requests that your AWS resource received during a time range that you choose. You can specify a sample size of up to 500 requests, and you can specify any time range in the previous three hours. GetSampledRequests returns a time range, which is usually the time range that you specified. However, if your resource (such as a CloudFront distribution) received 5,000 requests before the specified time range elapsed, GetSampledRequests returns an updated time range. This new time range indicates the actual period during which AWS WAF selected the requests in the sample.
#
# POST /
# operationId: GetSampledRequests
export def "api get-sampled-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  web_acl_id: any
  rule_id: any
  time_window: any
  max_items: any
]: any -> record<SampledRequests: record, PopulationSize: record, TimeWindow: record<StartTime: record, EndTime: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebAclId": $web_acl_id, "RuleId": $rule_id, "TimeWindow": $time_window, "MaxItems": $max_items} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the SizeConstraintSet specified by SizeConstraintSetId.
#
# POST /
# operationId: GetSizeConstraintSet
export def "api get-size-constraint-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  size_constraint_set_id: any
]: any -> record<SizeConstraintSet: record<SizeConstraintSetId: record, Name: record, SizeConstraints: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SizeConstraintSetId": $size_constraint_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the SqlInjectionMatchSet that is specified by SqlInjectionMatchSetId.
#
# POST /
# operationId: GetSqlInjectionMatchSet
export def "api get-sql-injection-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  sql_injection_match_set_id: any
]: any -> record<SqlInjectionMatchSet: record<SqlInjectionMatchSetId: record, Name: record, SqlInjectionMatchTuples: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SqlInjectionMatchSetId": $sql_injection_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the WebACL that is specified by WebACLId.
#
# POST /
# operationId: GetWebACL
export def "api get-web-acl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-43
  web_acl_id: any
]: any -> record<WebACL: record<WebACLId: record, Name: record, MetricName: record, DefaultAction: record<Type: record>, Rules: record, WebACLArn: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLId": $web_acl_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns the XssMatchSet that is specified by XssMatchSetId.
#
# POST /
# operationId: GetXssMatchSet
export def "api get-xss-match-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  xss_match_set_id: any
]: any -> record<XssMatchSet: record<XssMatchSetId: record, Name: record, XssMatchTuples: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"XssMatchSetId": $xss_match_set_id} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of ActivatedRule objects.
#
# POST /
# operationId: ListActivatedRulesInRuleGroup
export def "api list-activated-rules-in-rule-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --rule-group-id: any
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, ActivatedRules: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupId": $rule_group_id, "NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of ByteMatchSetSummary objects.
#
# POST /
# operationId: ListByteMatchSets
export def "api list-byte-match-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-46
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, ByteMatchSets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of GeoMatchSetSummary objects in the response.
#
# POST /
# operationId: ListGeoMatchSets
export def "api list-geo-match-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-47
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, GeoMatchSets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of IPSetSummary objects in the response.
#
# POST /
# operationId: ListIPSets
export def "api list-ip-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, IPSets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of LoggingConfiguration objects.
#
# POST /
# operationId: ListLoggingConfigurations
export def "api list-logging-configurations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-49
  --next-marker: any
  --limit: any
]: any -> record<LoggingConfigurations: record, NextMarker: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RuleSummary objects.
#
# POST /
# operationId: ListRateBasedRules
export def "api list-rate-based-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-50
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, Rules: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RegexMatchSetSummary objects.
#
# POST /
# operationId: ListRegexMatchSets
export def "api list-regex-match-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-51
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, RegexMatchSets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RegexPatternSetSummary objects.
#
# POST /
# operationId: ListRegexPatternSets
export def "api list-regex-pattern-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, RegexPatternSets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RuleGroup objects.
#
# POST /
# operationId: ListRuleGroups
export def "api list-rule-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-53
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, RuleGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RuleSummary objects.
#
# POST /
# operationId: ListRules
export def "api list-rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-54
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, Rules: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of SizeConstraintSetSummary objects.
#
# POST /
# operationId: ListSizeConstraintSets
export def "api list-size-constraint-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-55
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, SizeConstraintSets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of SqlInjectionMatchSet objects.
#
# POST /
# operationId: ListSqlInjectionMatchSets
export def "api list-sql-injection-match-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, SqlInjectionMatchSets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of RuleGroup objects that you are subscribed to.
#
# POST /
# operationId: ListSubscribedRuleGroups
export def "api list-subscribed-rule-groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-57
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, RuleGroups: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Retrieves the tags associated with the specified AWS resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each AWS resource, up to 50 tags for a resource. Tagging is only available through the API, SDKs, and CLI. You can't manage or view tags through the AWS WAF Classic console. You can tag the AWS resources that you manage through AWS WAF Classic: web ACLs, rule groups, and rules.
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
  --x-amz-target: string@x-amz-target-completer-58
  --next-marker: any
  --limit: any
  resource_arn: any
]: any -> record<NextMarker: record, TagInfoForResource: record<ResourceARN: record, TagList: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit, "ResourceARN": $resource_arn} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of WebACLSummary objects in the response.
#
# POST /
# operationId: ListWebACLs
export def "api list-web-ac-ls" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, WebACLs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Returns an array of XssMatchSet objects.
#
# POST /
# operationId: ListXssMatchSets
export def "api list-xss-match-sets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  --next-marker: any
  --limit: any
]: any -> record<NextMarker: record, XssMatchSets: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"NextMarker": $next_marker, "Limit": $limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Associates a LoggingConfiguration with a specified web ACL. You can access information about all traffic that AWS WAF inspects using the following steps: Create an Amazon Kinesis Data Firehose. Create the data firehose with a PUT source and in the region that you are operating. However, if you are capturing logs for Amazon CloudFront, always create the firehose in US East (N. Virginia). Do not create the data firehose using a Kinesis stream as your source. Associate that firehose to your web ACL using a PutLoggingConfiguration request. When you successfully enable logging using a PutLoggingConfiguration request, AWS WAF will create a service linked role with the necessary permissions to write logs to the Amazon Kinesis Data Firehose. For more information, see Logging Web ACL Traffic Information (https://docs.aws.amazon.com/waf/latest/developerguide/logging.html) in the AWS WAF Developer Guide.
#
# POST /
# operationId: PutLoggingConfiguration
export def "api update-logging-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  logging_configuration: any
]: any -> record<LoggingConfiguration: record<ResourceArn: record, LogDestinationConfigs: record, RedactedFields: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"LoggingConfiguration": $logging_configuration} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Attaches an IAM policy to the specified resource. The only supported use for this action is to share a RuleGroup across accounts. The PutPermissionPolicy is subject to the following restrictions: You can attach only one policy with each PutPermissionPolicy request. The policy must include an Effect, Action and Principal. Effect must specify Allow. The Action in the policy must be waf:UpdateWebACL, waf-regional:UpdateWebACL, waf:GetRuleGroup and waf-regional:GetRuleGroup . Any extra or wildcard actions in the policy will be rejected. The policy cannot include a Resource parameter. The ARN in the request must be a valid WAF RuleGroup ARN and the RuleGroup must exist in the same region. The user making the request must be the owner of the RuleGroup. Your policy must be composed using IAM Policy version 2012-10-17. For more information, see IAM Policies (https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html). An example of a valid policy parameter is shown in the Examples section below.
#
# POST /
# operationId: PutPermissionPolicy
export def "api update-permission-policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  resource_arn: any
  policy: any
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ResourceArn": $resource_arn, "Policy": $policy} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Associates tags with the specified AWS resource. Tags are key:value pairs that you can use to categorize and manage your resources, for purposes like billing. For example, you might set the tag key to "customer" and the value to the customer name or ID. You can specify one or more tags to add to each AWS resource, up to 50 tags for a resource. Tagging is only available through the API, SDKs, and CLI. You can't manage or view tags through the AWS WAF Classic console. You can use this action to tag the AWS resources that you manage through AWS WAF Classic: web ACLs, rule groups, and rules.
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
  --x-amz-target: string@x-amz-target-completer-63
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use.
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
  --x-amz-target: string@x-amz-target-completer-64
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes ByteMatchTuple objects (filters) in a ByteMatchSet. For each ByteMatchTuple object, you specify the following values: Whether to insert or delete the object from the array. If you want to change a ByteMatchSetUpdate object, you delete the existing object and add a new one. The part of a web request that you want AWS WAF to inspect, such as a query string or the value of the User-Agent header. The bytes (typically a string that corresponds with ASCII characters) that you want AWS WAF to look for. For more information, including how you specify the values for the AWS WAF API and the AWS CLI or SDKs, see TargetString in the ByteMatchTuple data type. Where to look, such as at the beginning or the end of a query string. Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string. For example, you can add a ByteMatchSetUpdate object that matches web requests in which User-Agent headers contain the string BadBot. You can then configure AWS WAF to block those requests. To create and configure a ByteMatchSet, perform the following steps: Create a ByteMatchSet. For more information, see CreateByteMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateByteMatchSet request. Submit an UpdateByteMatchSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateByteMatchSet
export def "api update-byte-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-65
  byte_match_set_id: any
  change_token: any
  updates: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"ByteMatchSetId": $byte_match_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes GeoMatchConstraint objects in an GeoMatchSet. For each GeoMatchConstraint object, you specify the following values: Whether to insert or delete the object from the array. If you want to change an GeoMatchConstraint object, you delete the existing object and add a new one. The Type. The only valid value for Type is Country. The Value, which is a two character code for the country to add to the GeoMatchConstraint object. Valid codes are listed in GeoMatchConstraint$Value. To create and configure an GeoMatchSet, perform the following steps: Submit a CreateGeoMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateGeoMatchSet request. Submit an UpdateGeoMatchSet request to specify the country that you want AWS WAF to watch for. When you update an GeoMatchSet, you specify the country that you want to add and/or the country that you want to delete. If you want to change a country, you delete the existing country and add the new one. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateGeoMatchSet
export def "api update-geo-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-66
  geo_match_set_id: any
  change_token: any
  updates: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"GeoMatchSetId": $geo_match_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes IPSetDescriptor objects in an IPSet. For each IPSetDescriptor object, you specify the following values: Whether to insert or delete the object from the array. If you want to change an IPSetDescriptor object, you delete the existing object and add a new one. The IP address version, IPv4 or IPv6. The IP address in CIDR notation, for example, 192.0.2.0/24 (for the range of IP addresses from 192.0.2.0 to 192.0.2.255) or 192.0.2.44/32 (for the individual IP address 192.0.2.44). AWS WAF supports IPv4 address ranges: /8 and any range between /16 through /32. AWS WAF supports IPv6 address ranges: /24, /32, /48, /56, /64, and /128. For more information about CIDR notation, see the Wikipedia entry Classless Inter-Domain Routing (https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). IPv6 addresses can be represented using any of the following formats: 1111:0000:0000:0000:0000:0000:0000:0111/128 1111:0:0:0:0:0:0:0111/128 1111::0111/128 1111::111/128 You use an IPSet to specify which web requests you want to allow or block based on the IP addresses that the requests originated from. For example, if you're receiving a lot of requests from one or a small number of IP addresses and you want to block the requests, you can create an IPSet that specifies those IP addresses, and then configure AWS WAF to block the requests. To create and configure an IPSet, perform the following steps: Submit a CreateIPSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateIPSet request. Submit an UpdateIPSet request to specify the IP addresses that you want AWS WAF to watch for. When you update an IPSet, you specify the IP addresses that you want to add and/or the IP addresses that you want to delete. If you want to change an IP address, you delete the existing IP address and add the new one. You can insert a maximum of 1000 addresses in a single request. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateIPSet
export def "api update-ip" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-67
  ip_set_id: any
  change_token: any
  updates: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"IPSetId": $ip_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes Predicate objects in a rule and updates the RateLimit in the rule. Each Predicate object identifies a predicate, such as a ByteMatchSet or an IPSet, that specifies the web requests that you want to block or count. The RateLimit specifies the number of requests every five minutes that triggers the rule. If you add more than one predicate to a RateBasedRule, a request must match all the predicates and exceed the RateLimit to be counted or blocked. For example, suppose you add the following to a RateBasedRule: An IPSet that matches the IP address 192.0.2.44/32 A ByteMatchSet that matches BadBot in the User-Agent header Further, you specify a RateLimit of 1,000. You then add the RateBasedRule to a WebACL and specify that you want to block requests that satisfy the rule. For a request to be blocked, it must come from the IP address 192.0.2.44 and the User-Agent header in the request must contain the value BadBot. Further, requests that match these two conditions much be received at a rate of more than 1,000 every five minutes. If the rate drops below this limit, AWS WAF no longer blocks the requests. As a second example, suppose you want to limit requests to a particular page on your site. To do this, you could add the following to a RateBasedRule: A ByteMatchSet with FieldToMatch of URI A PositionalConstraint of STARTS_WITH A TargetString of login Further, you specify a RateLimit of 1,000. By adding this RateBasedRule to a WebACL, you could limit requests to your login page without affecting the rest of your site.
#
# POST /
# operationId: UpdateRateBasedRule
export def "api update-rate-based-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-68
  rule_id: any
  change_token: any
  updates: any
  rate_limit: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "ChangeToken": $change_token, "Updates": $updates, "RateLimit": $rate_limit} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes RegexMatchTuple objects (filters) in a RegexMatchSet. For each RegexMatchSetUpdate object, you specify the following values: Whether to insert or delete the object from the array. If you want to change a RegexMatchSetUpdate object, you delete the existing object and add a new one. The part of a web request that you want AWS WAF to inspectupdate, such as a query string or the value of the User-Agent header. The identifier of the pattern (a regular expression) that you want AWS WAF to look for. For more information, see RegexPatternSet. Whether to perform any conversions on the request, such as converting it to lowercase, before inspecting it for the specified string. For example, you can create a RegexPatternSet that matches any requests with User-Agent headers that contain the string B[a@]dB[o0]t. You can then configure AWS WAF to reject those requests. To create and configure a RegexMatchSet, perform the following steps: Create a RegexMatchSet. For more information, see CreateRegexMatchSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRegexMatchSet request. Submit an UpdateRegexMatchSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the identifier of the RegexPatternSet that contain the regular expression patters you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateRegexMatchSet
export def "api update-regex-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-69
  regex_match_set_id: any
  updates: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexMatchSetId": $regex_match_set_id, "Updates": $updates, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes RegexPatternString objects in a RegexPatternSet. For each RegexPatternString object, you specify the following values: Whether to insert or delete the RegexPatternString. The regular expression pattern that you want to insert or delete. For more information, see RegexPatternSet. For example, you can create a RegexPatternString such as B[a@]dB[o0]t. AWS WAF will match this RegexPatternString to: BadBot BadB0t B@dBot B@dB0t To create and configure a RegexPatternSet, perform the following steps: Create a RegexPatternSet. For more information, see CreateRegexPatternSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRegexPatternSet request. Submit an UpdateRegexPatternSet request to specify the regular expression pattern that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateRegexPatternSet
export def "api update-regex-pattern" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-70
  regex_pattern_set_id: any
  updates: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RegexPatternSetId": $regex_pattern_set_id, "Updates": $updates, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes Predicate objects in a Rule. Each Predicate object identifies a predicate, such as a ByteMatchSet or an IPSet, that specifies the web requests that you want to allow, block, or count. If you add more than one predicate to a Rule, a request must match all of the specifications to be allowed, blocked, or counted. For example, suppose that you add the following to a Rule: A ByteMatchSet that matches the value BadBot in the User-Agent header An IPSet that matches the IP address 192.0.2.44 You then add the Rule to a WebACL and specify that you want to block requests that satisfy the Rule. For a request to be blocked, the User-Agent header in the request must contain the value BadBot and the request must originate from the IP address 192.0.2.44. To create and configure a Rule, perform the following steps: Create and update the predicates that you want to include in the Rule. Create the Rule. See CreateRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRule request. Submit an UpdateRule request to add predicates to the Rule. Create and update a WebACL that contains the Rule. See CreateWebACL. If you want to replace one ByteMatchSet or IPSet with another, you delete the existing one and add the new one. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateRule
export def "api update-rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-71
  rule_id: any
  change_token: any
  updates: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleId": $rule_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes ActivatedRule objects in a RuleGroup. You can only insert REGULAR rules into a rule group. You can have a maximum of ten rules per rule group. To create and configure a RuleGroup, perform the following steps: Create and update the Rules that you want to include in the RuleGroup. See CreateRule. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateRuleGroup request. Submit an UpdateRuleGroup request to add Rules to the RuleGroup. Create and update a WebACL that contains the RuleGroup. See CreateWebACL. If you want to replace one Rule with another, you delete the existing one and add the new one. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateRuleGroup
export def "api update-rule-group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --x-amz-target: string@x-amz-target-completer-72
  rule_group_id: any
  updates: any
  change_token: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"RuleGroupId": $rule_group_id, "Updates": $updates, "ChangeToken": $change_token} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes SizeConstraint objects (filters) in a SizeConstraintSet. For each SizeConstraint object, you specify the following values: Whether to insert or delete the object from the array. If you want to change a SizeConstraintSetUpdate object, you delete the existing object and add a new one. The part of a web request that you want AWS WAF to evaluate, such as the length of a query string or the length of the User-Agent header. Whether to perform any transformations on the request, such as converting it to lowercase, before checking its length. Note that transformations of the request body are not supported because the AWS resource forwards only the first 8192 bytes of your request to AWS WAF. You can only specify a single type of TextTransformation. A ComparisonOperator used for evaluating the selected part of the request against the specified Size, such as equals, greater than, less than, and so on. The length, in bytes, that you want AWS WAF to watch for in selected part of the request. The length is computed after applying the transformation. For example, you can add a SizeConstraintSetUpdate object that matches web requests in which the length of the User-Agent header is greater than 100 bytes. You can then configure AWS WAF to block those requests. To create and configure a SizeConstraintSet, perform the following steps: Create a SizeConstraintSet. For more information, see CreateSizeConstraintSet. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateSizeConstraintSet request. Submit an UpdateSizeConstraintSet request to specify the part of the request that you want AWS WAF to inspect (for example, the header or the URI) and the value that you want AWS WAF to watch for. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateSizeConstraintSet
export def "api update-size-constraint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  size_constraint_set_id: any
  change_token: any
  updates: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SizeConstraintSetId": $size_constraint_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes SqlInjectionMatchTuple objects (filters) in a SqlInjectionMatchSet. For each SqlInjectionMatchTuple object, you specify the following values: Action: Whether to insert the object into or delete the object from the array. To change a SqlInjectionMatchTuple, you delete the existing object and add a new one. FieldToMatch: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter. TextTransformation: Which text transformation, if any, to perform on the web request before inspecting the request for snippets of malicious SQL code. You can only specify a single type of TextTransformation. You use SqlInjectionMatchSet objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain snippets of SQL code in the query string and you want to block the requests, you can create a SqlInjectionMatchSet with the applicable settings, and then configure AWS WAF to block the requests. To create and configure a SqlInjectionMatchSet, perform the following steps: Submit a CreateSqlInjectionMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateIPSet request. Submit an UpdateSqlInjectionMatchSet request to specify the parts of web requests that you want AWS WAF to inspect for snippets of SQL code. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateSqlInjectionMatchSet
export def "api update-sql-injection-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  sql_injection_match_set_id: any
  change_token: any
  updates: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"SqlInjectionMatchSetId": $sql_injection_match_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes ActivatedRule objects in a WebACL. Each Rule identifies web requests that you want to allow, block, or count. When you update a WebACL, you specify the following values: A default action for the WebACL, either ALLOW or BLOCK. AWS WAF performs the default action if a request doesn't match the criteria in any of the Rules in a WebACL. The Rules that you want to add or delete. If you want to replace one Rule with another, you delete the existing Rule and add the new one. For each Rule, whether you want AWS WAF to allow requests, block requests, or count requests that match the conditions in the Rule. The order in which you want AWS WAF to evaluate the Rules in a WebACL. If you add more than one Rule to a WebACL, AWS WAF evaluates each request against the Rules in order based on the value of Priority. (The Rule that has the lowest value for Priority is evaluated first.) When a web request matches all the predicates (such as ByteMatchSets and IPSets) in a Rule, AWS WAF immediately takes the corresponding action, allow or block, and doesn't evaluate the request against the remaining Rules in the WebACL, if any. To create and configure a WebACL, perform the following steps: Create and update the predicates that you want to include in Rules. For more information, see CreateByteMatchSet, UpdateByteMatchSet, CreateIPSet, UpdateIPSet, CreateSqlInjectionMatchSet, and UpdateSqlInjectionMatchSet. Create and update the Rules that you want to include in the WebACL. For more information, see CreateRule and UpdateRule. Create a WebACL. See CreateWebACL. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateWebACL request. Submit an UpdateWebACL request to specify the Rules that you want to include in the WebACL, to specify the default action, and to associate the WebACL with a CloudFront distribution. The ActivatedRule can be a rule group. If you specify a rule group as your ActivatedRule , you can exclude specific rules from that rule group. If you already have a rule group associated with a web ACL and want to submit an UpdateWebACL request to exclude certain rules from that rule group, you must first remove the rule group from the web ACL, the re-insert it again, specifying the excluded rules. For details, see ActivatedRule$ExcludedRules . Be aware that if you try to add a RATE_BASED rule to a web ACL without setting the rule type when first creating the rule, the UpdateWebACL request will fail because the request tries to add a REGULAR rule (the default rule type) with the specified ID, which does not exist. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateWebACL
export def "api update-web-acl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  web_acl_id: any
  change_token: any
  --updates: any
  --default-action: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"WebACLId": $web_acl_id, "ChangeToken": $change_token, "Updates": $updates, "DefaultAction": $default_action} | compact
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

# This is AWS WAF Classic documentation. For more information, see AWS WAF Classic (https://docs.aws.amazon.com/waf/latest/developerguide/classic-waf-chapter.html) in the developer guide. For the latest version of AWS WAF, use the AWS WAFV2 API and see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html). With the latest version, AWS WAF has a single set of endpoints for regional and global use. Inserts or deletes XssMatchTuple objects (filters) in an XssMatchSet. For each XssMatchTuple object, you specify the following values: Action: Whether to insert the object into or delete the object from the array. To change an XssMatchTuple, you delete the existing object and add a new one. FieldToMatch: The part of web requests that you want AWS WAF to inspect and, if you want AWS WAF to inspect a header or custom query parameter, the name of the header or parameter. TextTransformation: Which text transformation, if any, to perform on the web request before inspecting the request for cross-site scripting attacks. You can only specify a single type of TextTransformation. You use XssMatchSet objects to specify which CloudFront requests that you want to allow, block, or count. For example, if you're receiving requests that contain cross-site scripting attacks in the request body and you want to block the requests, you can create an XssMatchSet with the applicable settings, and then configure AWS WAF to block the requests. To create and configure an XssMatchSet, perform the following steps: Submit a CreateXssMatchSet request. Use GetChangeToken to get the change token that you provide in the ChangeToken parameter of an UpdateIPSet request. Submit an UpdateXssMatchSet request to specify the parts of web requests that you want AWS WAF to inspect for cross-site scripting attacks. For more information about how to use the AWS WAF API to allow or block HTTP requests, see the AWS WAF Developer Guide (https://docs.aws.amazon.com/waf/latest/developerguide/).
#
# POST /
# operationId: UpdateXssMatchSet
export def "api update-xss-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  xss_match_set_id: any
  change_token: any
  updates: any
]: any -> record<ChangeToken: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/" $auth.query)
  let req_body = {"XssMatchSetId": $xss_match_set_id, "ChangeToken": $change_token, "Updates": $updates} | compact
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
