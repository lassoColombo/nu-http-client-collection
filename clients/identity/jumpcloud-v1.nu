# Auto-generated client for JumpCloud API v1.0
# Source: https://docs.jumpcloud.com/api/1.0/index.yaml
# Auth: --token flag or $env.JUMPCLOUD_API_TOKEN

const BASE_URL = "https://console.jumpcloud.com/api"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o JUMPCLOUD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {x-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://console.jumpcloud.com/api" "https://console.eu.jumpcloud.com/api" "https://console.in.jumpcloud.com/api"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def color-completer [] { ["" "#005466" "#006CAC" "#0617AC" "#202D38" "#3E8696" "#57C49F" "#58C469" "#7C6ADA" "#9E2F00" "#D5779D" "#FF6C03" "#FFB000"] }
def authIdp-completer [] { ["AZURE" "JUMPCLOUD"] }
def mfa-completer [] { ["ALWAYS" "DISABLED" "ENABLED" "REQUIRED"] }
def caSource-completer [] { ["BYOC" "JUMPCLOUD_MANAGED" "NONE"] }
def state-completer [] { ["ACTIVATED" "STAGED" "SUSPENDED"] }
def state-completer-1 [] { ["ACTIVATED" "SUSPENDED"] }
def accept-completer [] { ["application/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "application-templates list" } } | get name | first)
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

# List Application Templates
#
# GET /application-templates
# operationId: application_templates_list
export def "application-templates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # The space separated fields included in the returned records. If omitted the default list of fields will be returned.
  --limit: int # The number of records to return at once.
  --skip: int # The offset into the records to return.
  --qp-sort: string # The space separated fields used to sort the collection. Default sort is ascending, prefix with - to sort descending.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --x-org-id: string
]: nothing -> record<results: table<_id: string, active: bool, beta: bool, status: string, color: string, config: record, displayLabel: string, displayName: string, isConfigured: bool, jit: record, learnMore: string, logo: record, name: string, oidc: record, provision: record, sso: record, ssoUrl: string, test: string, keywords: list>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/application-templates" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Application Template
#
# GET /application-templates/{id}
# operationId: application_templates_get
export def "application-templates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # The space separated fields included in the returned records. If omitted the default list of fields will be returned.
  --limit: int # The number of records to return at once.
  --skip: int # The offset into the records to return.
  --qp-sort: string # The space separated fields used to sort the collection. Default sort is ascending, prefix with - to sort descending.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --x-org-id: string
]: nothing -> record<_id: string, active: bool, beta: bool, status: string, color: string, config: record<spErrorFlow: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signAssertion: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signResponse: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, acsUrl: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, constantAttributes: record<label: string, mutable: bool, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: list, visible: bool>, databaseAttributes: record<position: int>, idpCertificate: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpPrivateKey: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, spEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, authClaimConfiguration: record<type: string, visible: bool, sendAmrClaim: record, authnContextMode: record, singleAuthnContextValue: record, authnContextMappings: record>>, displayLabel: string, displayName: string, isConfigured: bool, jit: record<attributes: record, createOnly: bool>, learnMore: string, logo: record<url: string>, name: string, oidc: record<grantTypes: list<string>, redirectUris: list<string>, tokenEndpointAuthMethod: string, ssoUrl: string>, provision: record<type: string, beta: bool, groups_supported: bool>, sso: record<type: string, beta: bool, jit: bool, idpCertExpirationAt: string, idpCertificateUpdatedAt: string, idpPrivateKeyUpdatedAt: string, spCertificateUpdatedAt: string, hidden: bool>, ssoUrl: string, test: string, keywords: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/application-templates/($id)" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Applications
#
# GET /applications
# operationId: applications_list
export def "applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # The space separated fields included in the returned records. If omitted the default list of fields will be returned.
  --limit: int # The number of records to return at once.
  --skip: int # The offset into the records to return.
  --qp-sort: string # The space separated fields used to sort the collection. Default sort is ascending, prefix with - to sort descending. (default: name)
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --x-org-id: string
]: nothing -> record<name: string, results: table<_id: string, active: bool, beta: bool, color: string, config: record, created: string, databaseAttributes: list, description: string, displayLabel: string, displayName: string, learnMore: string, logo: record, name: string, organization: string, sso: record, ssoUrl: string, parentApp: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/applications" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an Application
#
# POST /applications
# operationId: applications_post
# --config shape: {spErrorFlow?: record, signAssertion?: record, signResponse?: record, acsUrl?: record, constantAttributes?: record, databaseAttributes?: record, idpCertificate?: record, idpEntityId?: record, idpPrivateKey?: record, spEntityId?: record, authClaimConfiguration?: record}
# --logo shape: {color?: ""|"#202D38"|"#005466"|"#3E8696"|"#006CAC"|"#0617AC"|"#7C6ADA"|"#D5779D"|"#9E2F00"|"#FFB000"|"#58C469"|"#57C49F"|"#FF6C03", url?: string}
# --sso shape: {type?: string, beta?: bool, jit?: bool, idpCertExpirationAt?: string, hidden?: bool}
export def "applications post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --id: string
  --active: oneof<nothing, bool>
  --beta: oneof<nothing, bool>
  --color: string@color-completer
  config: record # Only required for SAML configuration (not required for Bookmarks) — shape: {spErrorFlow?: record, signAssertion?: record, signResponse?: record, acsUrl?: record, constantAttributes?: record, databaseAttributes?: record, idpCertificate?: record, idpEntityId?: record, idpPrivateKey?: record, spEntityId?: record, authClaimConfiguration?: record}
  --created: string
  --databaseAttributes: list
  --description: string
  --displayLabel: string
  --displayName: string
  --learnMore: string
  --logo: record # shape: {color?: ""|"#202D38"|"#005466"|"#3E8696"|"#006CAC"|"#0617AC"|"#7C6ADA"|"#D5779D"|"#9E2F00"|"#FFB000"|"#58C469"|"#57C49F"|"#FF6C03", url?: string}
  name: string
  --organization: string
  --sso: record # shape: {type?: string, beta?: bool, jit?: bool, idpCertExpirationAt?: string, hidden?: bool}
  ssoUrl: string
  --parentApp: string
]: any -> record<_id: string, active: bool, beta: bool, color: string, config: record<spErrorFlow: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signAssertion: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signResponse: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, acsUrl: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, constantAttributes: record<label: string, mutable: bool, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: list, visible: bool>, databaseAttributes: record<position: int>, idpCertificate: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpPrivateKey: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, spEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, authClaimConfiguration: record<type: string, visible: bool, sendAmrClaim: record, authnContextMode: record, singleAuthnContextValue: record, authnContextMappings: record>>, created: string, databaseAttributes: list<record>, description: string, displayLabel: string, displayName: string, learnMore: string, logo: record<color: string, url: string>, name: string, organization: string, sso: record<type: string, beta: bool, jit: bool, idpCertExpirationAt: string, idpCertificateUpdatedAt: string, idpPrivateKeyUpdatedAt: string, spCertificateUpdatedAt: string, hidden: bool>, ssoUrl: string, parentApp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/applications")
  let body = {_id: $id, active: $active, beta: $beta, color: $color, config: $config, created: $created, databaseAttributes: $databaseAttributes, description: $description, displayLabel: $displayLabel, displayName: $displayName, learnMore: $learnMore, logo: $logo, name: $name, organization: $organization, sso: $sso, ssoUrl: $ssoUrl, parentApp: $parentApp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an Application
#
# GET /applications/{id}
# operationId: applications_get
export def "applications get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> record<_id: string, active: bool, beta: bool, color: string, config: record<spErrorFlow: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signAssertion: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signResponse: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, acsUrl: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, constantAttributes: record<label: string, mutable: bool, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: list, visible: bool>, databaseAttributes: record<position: int>, idpCertificate: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpPrivateKey: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, spEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, authClaimConfiguration: record<type: string, visible: bool, sendAmrClaim: record, authnContextMode: record, singleAuthnContextValue: record, authnContextMappings: record>>, created: string, databaseAttributes: list<record>, description: string, displayLabel: string, displayName: string, learnMore: string, logo: record<color: string, url: string>, name: string, organization: string, sso: record<type: string, beta: bool, jit: bool, idpCertExpirationAt: string, idpCertificateUpdatedAt: string, idpPrivateKeyUpdatedAt: string, spCertificateUpdatedAt: string, hidden: bool>, ssoUrl: string, parentApp: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($id)")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Application
#
# PUT /applications/{id}
# operationId: applications_put
# --config shape: {spErrorFlow?: record, signAssertion?: record, signResponse?: record, acsUrl?: record, constantAttributes?: record, databaseAttributes?: record, idpCertificate?: record, idpEntityId?: record, idpPrivateKey?: record, spEntityId?: record, authClaimConfiguration?: record}
# --logo shape: {color?: ""|"#202D38"|"#005466"|"#3E8696"|"#006CAC"|"#0617AC"|"#7C6ADA"|"#D5779D"|"#9E2F00"|"#FFB000"|"#58C469"|"#57C49F"|"#FF6C03", url?: string}
# --sso shape: {type?: string, beta?: bool, jit?: bool, idpCertExpirationAt?: string, hidden?: bool}
export def "applications put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --body-id: string
  --active: oneof<nothing, bool>
  --beta: oneof<nothing, bool>
  --color: string@color-completer
  config: record # Only required for SAML configuration (not required for Bookmarks) — shape: {spErrorFlow?: record, signAssertion?: record, signResponse?: record, acsUrl?: record, constantAttributes?: record, databaseAttributes?: record, idpCertificate?: record, idpEntityId?: record, idpPrivateKey?: record, spEntityId?: record, authClaimConfiguration?: record}
  --created: string
  --databaseAttributes: list
  --description: string
  --displayLabel: string
  --displayName: string
  --learnMore: string
  --logo: record # shape: {color?: ""|"#202D38"|"#005466"|"#3E8696"|"#006CAC"|"#0617AC"|"#7C6ADA"|"#D5779D"|"#9E2F00"|"#FFB000"|"#58C469"|"#57C49F"|"#FF6C03", url?: string}
  name: string
  --organization: string
  --sso: record # shape: {type?: string, beta?: bool, jit?: bool, idpCertExpirationAt?: string, hidden?: bool}
  ssoUrl: string
  --parentApp: string
]: any -> record<_id: string, active: bool, beta: bool, color: string, config: record<spErrorFlow: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signAssertion: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signResponse: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, acsUrl: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, constantAttributes: record<label: string, mutable: bool, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: list, visible: bool>, databaseAttributes: record<position: int>, idpCertificate: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpPrivateKey: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, spEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, authClaimConfiguration: record<type: string, visible: bool, sendAmrClaim: record, authnContextMode: record, singleAuthnContextValue: record, authnContextMappings: record>>, created: string, databaseAttributes: list<record>, description: string, displayLabel: string, displayName: string, learnMore: string, logo: record<color: string, url: string>, name: string, organization: string, sso: record<type: string, beta: bool, jit: bool, idpCertExpirationAt: string, idpCertificateUpdatedAt: string, idpPrivateKeyUpdatedAt: string, spCertificateUpdatedAt: string, hidden: bool>, ssoUrl: string, parentApp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($id)")
  let body = {_id: $body_id, active: $active, beta: $beta, color: $color, config: $config, created: $created, databaseAttributes: $databaseAttributes, description: $description, displayLabel: $displayLabel, displayName: $displayName, learnMore: $learnMore, logo: $logo, name: $name, organization: $organization, sso: $sso, ssoUrl: $ssoUrl, parentApp: $parentApp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Application
#
# DELETE /applications/{id}
# operationId: applications_delete
export def "applications delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> record<_id: string, active: bool, beta: bool, color: string, config: record<spErrorFlow: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signAssertion: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, signResponse: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: bool, visible: bool>, acsUrl: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, constantAttributes: record<label: string, mutable: bool, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: list, visible: bool>, databaseAttributes: record<position: int>, idpCertificate: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, idpPrivateKey: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, spEntityId: record<label: string, position: int, readOnly: bool, required: bool, tooltip: record, type: string, value: string, visible: bool>, authClaimConfiguration: record<type: string, visible: bool, sendAmrClaim: record, authnContextMode: record, singleAuthnContextValue: record, authnContextMappings: record>>, created: string, databaseAttributes: list<record>, description: string, displayLabel: string, displayName: string, learnMore: string, logo: record<color: string, url: string>, name: string, organization: string, sso: record<type: string, beta: bool, jit: bool, idpCertExpirationAt: string, idpCertificateUpdatedAt: string, idpPrivateKeyUpdatedAt: string, spCertificateUpdatedAt: string, hidden: bool>, ssoUrl: string, parentApp: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($id)")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Launch a command via a Trigger
#
# POST /command/trigger/{triggername}
# operationId: command_trigger_webhook_post
export def "command-trigger post" [
  triggername: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --body: record
]: any -> record<triggered: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/command/trigger/($triggername)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all Command Results
#
# GET /commandresults
# operationId: command_results_list
export def "commandresults list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --qp-sort: string # Use space separated sort parameters to sort the collection. Default sort is ascending. Prefix with `-` to sort descending.
  --x-org-id: string
]: nothing -> record<totalCount: int, results: table<command: string, exitCode: int, name: string, sudo: bool, system: string, systemId: string, user: string, workflowId: string, _id: string, response: record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commandresults" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List an individual Command result
#
# GET /commandresults/{id}
# operationId: command_results_get
export def "commandresults get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --x-org-id: string
]: nothing -> record<_id: string, command: string, files: list<string>, name: string, organization: string, response: record<data: record<exitCode: int, output: string>, error: string, id: string>, sudo: bool, system: string, systemId: string, user: string, workflowId: string, workflowInstanceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/commandresults/($id)" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Command result
#
# DELETE /commandresults/{id}
# operationId: command_results_delete
export def "commandresults delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> record<_id: string, command: string, files: list<string>, name: string, organization: string, response: record<data: record<exitCode: int, output: string>, error: string, id: string>, sudo: bool, system: string, systemId: string, user: string, workflowId: string, workflowInstanceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/commandresults/($id)")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List All Commands
#
# GET /commands
# operationId: commands_list
export def "commands list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --qp-sort: string # Use space separated sort parameters to sort the collection. Default sort is ascending. Prefix with `-` to sort descending.
  --x-org-id: string
]: nothing -> record<results: table<_id: string, command: string, commandType: string, launchType: string, listensTo: string, name: string, organization: string, schedule: string, scheduleRepeatType: string, trigger: string, description: string, aiGenerated: bool, templatingRequired: bool>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commands" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create A Command
#
# POST /commands
# operationId: commands_post
# --filesS3 item shape: {objectStorageId: string, name: string, destination: string, sha256: string}
export def "commands post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  command: string # The command to execute on the server.
  --commandRunners: list # An array of IDs of the Command Runner Users that can execute this command.
  commandType: string # The Command OS (default: linux)
  --files: list # An array of file IDs to include with the command.
  --launchType: string # How the command will execute.
  --listensTo: string
  name: string
  --organization: string # The ID of the organization.
  --schedule: string # A crontab that consists of: [ (seconds) (minutes) (hours) (days of month) (months) (weekdays) ] or [ immediate ]. If you send this as an empty string, it will run immediately.
  --scheduleRepeatType: string # When the command will repeat.
  --sudo: oneof<nothing, bool>
  --systems: list # Not used. Use /api/v2/commands/{id}/associations to bind commands to systems.
  --template: string # The template this command was created from
  --timeout: string # The time in seconds to allow the command to run for. The maximum value is 86400 seconds (1 day).
  --trigger: string # The name of the command trigger.
  --user: string # The ID of the system user to run the command as. This field is required when creating a command with a commandType of "mac" or "linux".
  --shell: string # The shell used to run the command.
  --timeToLiveSeconds: int # Time in seconds a command can wait in the queue to be run before timing out
  --scheduleYear: int # The year that a scheduled command will launch in.
  --filesS3: list # An array of file stored in S3 to include with the command. — item shape: {objectStorageId: string, name: string, destination: string, sha256: string}
  --description: string # Description of the command.
  --aiGenerated: oneof<nothing, bool> # Whether this command was generated with AI assistance.
  --templatingRequired: oneof<nothing, bool> # Whether this command requires templating before execution.
]: any -> record<command: string, commandRunners: list<string>, commandType: string, files: list<string>, launchType: string, listensTo: string, name: string, organization: string, schedule: string, scheduleRepeatType: string, sudo: bool, systems: list<string>, template: string, timeout: string, trigger: string, user: string, shell: string, timeToLiveSeconds: int, scheduleYear: int, filesS3: table<objectStorageId: string, name: string, destination: string, sha256: string>, description: string, aiGenerated: bool, templatingRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commands")
  let body = {command: $command, commandRunners: $commandRunners, commandType: $commandType, files: $files, launchType: $launchType, listensTo: $listensTo, name: $name, organization: $organization, schedule: $schedule, scheduleRepeatType: $scheduleRepeatType, sudo: $sudo, systems: $systems, template: $template, timeout: $timeout, trigger: $trigger, user: $user, shell: $shell, timeToLiveSeconds: $timeToLiveSeconds, scheduleYear: $scheduleYear, filesS3: $filesS3, description: $description, aiGenerated: $aiGenerated, templatingRequired: $templatingRequired} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List an individual Command
#
# GET /commands/{id}
# operationId: commands_get
export def "commands get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --x-org-id: string
]: nothing -> record<command: string, commandRunners: list<string>, commandType: string, files: list<string>, launchType: string, listensTo: string, name: string, organization: string, schedule: string, scheduleRepeatType: string, sudo: bool, systems: list<string>, template: string, timeout: string, trigger: string, user: string, shell: string, timeToLiveSeconds: int, scheduleYear: int, filesS3: table<objectStorageId: string, name: string, destination: string, sha256: string>, description: string, aiGenerated: bool, templatingRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/commands/($id)" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Command
#
# PUT /commands/{id}
# operationId: commands_put
# --filesS3 item shape: {objectStorageId: string, name: string, destination: string, sha256: string}
export def "commands put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  command: string # The command to execute on the server.
  --commandRunners: list # An array of IDs of the Command Runner Users that can execute this command.
  commandType: string # The Command OS (default: linux)
  --files: list # An array of file IDs to include with the command.
  --launchType: string # How the command will execute.
  --listensTo: string
  name: string
  --organization: string # The ID of the organization.
  --schedule: string # A crontab that consists of: [ (seconds) (minutes) (hours) (days of month) (months) (weekdays) ] or [ immediate ]. If you send this as an empty string, it will run immediately.
  --scheduleRepeatType: string # When the command will repeat.
  --sudo: oneof<nothing, bool>
  --systems: list # Not used. Use /api/v2/commands/{id}/associations to bind commands to systems.
  --template: string # The template this command was created from
  --timeout: string # The time in seconds to allow the command to run for. The maximum value is 86400 seconds (1 day).
  --trigger: string # The name of the command trigger.
  --user: string # The ID of the system user to run the command as. This field is required when creating a command with a commandType of "mac" or "linux".
  --shell: string # The shell used to run the command.
  --timeToLiveSeconds: int # Time in seconds a command can wait in the queue to be run before timing out
  --scheduleYear: int # The year that a scheduled command will launch in.
  --filesS3: list # An array of file stored in S3 to include with the command. — item shape: {objectStorageId: string, name: string, destination: string, sha256: string}
  --description: string # Description of the command.
  --aiGenerated: oneof<nothing, bool> # Whether this command was generated with AI assistance.
  --templatingRequired: oneof<nothing, bool> # Whether this command requires templating before execution.
]: any -> record<command: string, commandRunners: list<string>, commandType: string, files: list<string>, launchType: string, listensTo: string, name: string, organization: string, schedule: string, scheduleRepeatType: string, sudo: bool, systems: list<string>, template: string, timeout: string, trigger: string, user: string, shell: string, timeToLiveSeconds: int, scheduleYear: int, filesS3: table<objectStorageId: string, name: string, destination: string, sha256: string>, description: string, aiGenerated: bool, templatingRequired: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/commands/($id)")
  let body = {command: $command, commandRunners: $commandRunners, commandType: $commandType, files: $files, launchType: $launchType, listensTo: $listensTo, name: $name, organization: $organization, schedule: $schedule, scheduleRepeatType: $scheduleRepeatType, sudo: $sudo, systems: $systems, template: $template, timeout: $timeout, trigger: $trigger, user: $user, shell: $shell, timeToLiveSeconds: $timeToLiveSeconds, scheduleYear: $scheduleYear, filesS3: $filesS3, description: $description, aiGenerated: $aiGenerated, templatingRequired: $templatingRequired} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Command
#
# DELETE /commands/{id}
# operationId: commands_delete
export def "commands delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> record<command: string, commandRunners: list<string>, commandType: string, files: list<string>, launchType: string, listensTo: string, name: string, organization: string, schedule: string, scheduleRepeatType: string, sudo: bool, systems: list<string>, template: string, timeout: string, trigger: string, user: string, shell: string, timeToLiveSeconds: int, scheduleYear: int, filesS3: table<objectStorageId: string, name: string, destination: string, sha256: string>, description: string, aiGenerated: bool, templatingRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/commands/($id)")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Command File
#
# GET /files/command/{id}
# operationId: command_file_get
export def "files-command get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --x-org-id: string
]: nothing -> record<results: table<_id: string, destination: string, name: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/files/command/($id)" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Organization Details
#
# GET /organizations
# operationId: organization_list
export def "organizations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --search: string # A nested object containing a `searchTerm` string or array of strings and a list of `fields` to search on.
  --skip: int # The offset into the records to return. (default: 0)
  --qp-sort: string # Use space separated sort parameters to sort the collection. Default sort is ascending. Prefix with `-` to sort descending.
  --sortIgnoreCase: string # Use space separated sort parameters to sort the collection, ignoring case. Default sort is ascending. Prefix with `-` to sort descending.
]: nothing -> record<results: table<_id: string, displayName: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sortIgnoreCase" $sortIgnoreCase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Organization
#
# GET /organizations/{id}
# operationId: organizations_get
export def "organizations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
]: nothing -> record<_id: string, created: string, customEmailSettings: record<enabled: bool>, displayName: string, entitlement: record<billingModel: string, capUserQuantity: bool, maxUserQuantity: int, purchaseChannel: string, entitlementProducts: list<record>, isManuallyBilled: bool, pricePerUserSum: int>, hasStripeCustomerId: bool, hasCreditCard: bool, lastEstimateCalculationTimeStamp: string, lastSfdcSyncStatus: record, accountsReceivable: string, accessRestriction: string, settings: record<agentVersion: string, betaFeatures: record, chromeDTCEnabled: bool, contactEmail: string, contactName: string, disableCommandRunner: bool, disableLdap: bool, disableUM: bool, duplicateLDAPGroups: bool, emailDisclaimer: string, enableGoogleApps: bool, enableManagedUID: bool, enableO365: bool, enableUserPortalAgentInstall: bool, features: record<directoryInsightsPremium: record, systemInsights: record, directoryInsights: record>, growthData: record, logo: string, name: string, newSystemUserStateDefaults: record<applicationImport: string, csvImport: string, manualEntry: string>, passwordCompliance: string, passwordPolicy: record<allowUnenrolledMFAPasswordReset: bool, allowUsernameSubstring: bool, daysAfterExpirationToSelfRecover: int, daysBeforeExpirationToForceReset: int, disallowCommonlyUsedPasswords: bool, disallowSequentialOrRepetitiveChars: bool, displayComplexityOnResetScreen: bool, effectiveDate: string, enableDaysAfterExpirationToSelfRecover: bool, enableDaysBeforeExpirationToForceReset: bool, enableLockoutTimeInSeconds: bool, enableMaxHistory: bool, enableMaxLoginAttempts: bool, enableMinChangePeriodInDays: bool, enableMinLength: bool, enablePasswordExpirationInDays: bool, gracePeriodDate: string, lockoutTimeInSeconds: int, maxHistory: int, maxLoginAttempts: int, minChangePeriodInDays: int, minLength: int, needsLowercase: bool, needsNumeric: bool, needsSymbolic: bool, needsUppercase: bool, passwordExpirationInDays: int, enableResetLockoutCounter: bool, resetLockoutCounterMinutes: int, enableRecoveryEmail: bool>, pendingDelete: bool, requireAdminMFA: bool, showIntro: bool, systemUserDefaults: record<restrictedFields: list>, systemUserPasswordExpirationInDays: int, systemUsersCanEdit: bool, disableGoogleLogin: bool, userPortal: record<idleSessionDurationMinutes: int, cookieExpirationType: string>, deviceIdentificationEnabled: bool, trustedAppConfig: record<checksum: string, trustedApps: list>, maxSystemUsers: int, windowsMDM: record<enabled: bool, autoEnroll: bool>>, totalBillingEstimate: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organizations/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Organization
#
# PUT /organizations/{id}
# operationId: organization_put
# --settings shape: {contactEmail?: string, contactName?: string, disableLdap?: bool, disableUM?: bool, duplicateLDAPGroups?: bool, emailDisclaimer?: string, enableManagedUID?: bool, features?: record, growthData?: record, logo?: string, name?: string, newSystemUserStateDefaults?: record, passwordCompliance?: "custom"|"pci3"|"windows", passwordPolicy?: record, showIntro?: bool, systemUserDefaults?: record, systemUserPasswordExpirationInDays?: int, systemUsersCanEdit?: bool, disableGoogleLogin?: bool, userPortal?: record, deviceIdentificationEnabled?: bool, trustedAppConfig?: record, maxSystemUsers?: int}
export def "organizations put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record # shape: {contactEmail?: string, contactName?: string, disableLdap?: bool, disableUM?: bool, duplicateLDAPGroups?: bool, emailDisclaimer?: string, enableManagedUID?: bool, features?: record, growthData?: record, logo?: string, name?: string, newSystemUserStateDefaults?: record, passwordCompliance?: "custom"|"pci3"|"windows", passwordPolicy?: record, showIntro?: bool, systemUserDefaults?: record, systemUserPasswordExpirationInDays?: int, systemUsersCanEdit?: bool, disableGoogleLogin?: bool, userPortal?: record, deviceIdentificationEnabled?: bool, trustedAppConfig?: record, maxSystemUsers?: int}
]: any -> record<_id: string, created: string, customEmailSettings: record<enabled: bool>, displayName: string, entitlement: record<billingModel: string, capUserQuantity: bool, maxUserQuantity: int, purchaseChannel: string, entitlementProducts: list<record>, isManuallyBilled: bool, pricePerUserSum: int>, hasStripeCustomerId: bool, hasCreditCard: bool, lastEstimateCalculationTimeStamp: string, lastSfdcSyncStatus: record, accountsReceivable: string, accessRestriction: string, settings: record<agentVersion: string, betaFeatures: record, chromeDTCEnabled: bool, contactEmail: string, contactName: string, disableCommandRunner: bool, disableLdap: bool, disableUM: bool, duplicateLDAPGroups: bool, emailDisclaimer: string, enableGoogleApps: bool, enableManagedUID: bool, enableO365: bool, enableUserPortalAgentInstall: bool, features: record<directoryInsightsPremium: record, systemInsights: record, directoryInsights: record>, growthData: record, logo: string, name: string, newSystemUserStateDefaults: record<applicationImport: string, csvImport: string, manualEntry: string>, passwordCompliance: string, passwordPolicy: record<allowUnenrolledMFAPasswordReset: bool, allowUsernameSubstring: bool, daysAfterExpirationToSelfRecover: int, daysBeforeExpirationToForceReset: int, disallowCommonlyUsedPasswords: bool, disallowSequentialOrRepetitiveChars: bool, displayComplexityOnResetScreen: bool, effectiveDate: string, enableDaysAfterExpirationToSelfRecover: bool, enableDaysBeforeExpirationToForceReset: bool, enableLockoutTimeInSeconds: bool, enableMaxHistory: bool, enableMaxLoginAttempts: bool, enableMinChangePeriodInDays: bool, enableMinLength: bool, enablePasswordExpirationInDays: bool, gracePeriodDate: string, lockoutTimeInSeconds: int, maxHistory: int, maxLoginAttempts: int, minChangePeriodInDays: int, minLength: int, needsLowercase: bool, needsNumeric: bool, needsSymbolic: bool, needsUppercase: bool, passwordExpirationInDays: int, enableResetLockoutCounter: bool, resetLockoutCounterMinutes: int, enableRecoveryEmail: bool>, pendingDelete: bool, requireAdminMFA: bool, showIntro: bool, systemUserDefaults: record<restrictedFields: list>, systemUserPasswordExpirationInDays: int, systemUsersCanEdit: bool, disableGoogleLogin: bool, userPortal: record<idleSessionDurationMinutes: int, cookieExpirationType: string>, deviceIdentificationEnabled: bool, trustedAppConfig: record<checksum: string, trustedApps: list>, maxSystemUsers: int, windowsMDM: record<enabled: bool, autoEnroll: bool>>, totalBillingEstimate: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organizations/($id)")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Radius Servers
#
# GET /radiusservers
# operationId: radius_servers_list
export def "radiusservers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --qp-sort: string # Use space separated sort parameters to sort the collection. Default sort is ascending. Prefix with `-` to sort descending.
  --x-org-id: string
]: nothing -> record<results: table<_id: string, authIdp: string, mfa: string, name: string, networkSourceIp: string, organization: string, sharedSecret: string, tagNames: list, tags: list, userLockoutAction: string, userPasswordExpirationAction: string, userPasswordEnabled: bool, userCertEnabled: bool, deviceCertEnabled: bool, caCert: string, requireTlsAuth: bool, radsecEnabled: bool, requireRadsec: bool, caSource: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/radiusservers" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Radius Server
#
# POST /radiusservers
# operationId: radius_servers_post
export def "radiusservers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --authIdp: string@authIdp-completer
  --mfa: string@mfa-completer
  name: string
  networkSourceIp: string
  sharedSecret: string # RADIUS shared secret between the server and client.
  --tagNames: list
  --userLockoutAction: string
  --userPasswordExpirationAction: string
  --userPasswordEnabled: oneof<nothing, bool>
  --userCertEnabled: oneof<nothing, bool>
  --deviceCertEnabled: oneof<nothing, bool>
  --caCert: string
  --requireTlsAuth: oneof<nothing, bool>
  --radsecEnabled: oneof<nothing, bool>
  --requireRadsec: oneof<nothing, bool>
  --caSource: string@caSource-completer # default: NONE
]: any -> record<_id: string, authIdp: string, mfa: string, name: string, networkSourceIp: string, organization: string, sharedSecret: string, tagNames: list<string>, tags: list<string>, userLockoutAction: string, userPasswordExpirationAction: string, userPasswordEnabled: bool, userCertEnabled: bool, deviceCertEnabled: bool, caCert: string, requireTlsAuth: bool, radsecEnabled: bool, requireRadsec: bool, caSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/radiusservers")
  let body = {authIdp: $authIdp, mfa: $mfa, name: $name, networkSourceIp: $networkSourceIp, sharedSecret: $sharedSecret, tagNames: $tagNames, userLockoutAction: $userLockoutAction, userPasswordExpirationAction: $userPasswordExpirationAction, userPasswordEnabled: $userPasswordEnabled, userCertEnabled: $userCertEnabled, deviceCertEnabled: $deviceCertEnabled, caCert: $caCert, requireTlsAuth: $requireTlsAuth, radsecEnabled: $radsecEnabled, requireRadsec: $requireRadsec, caSource: $caSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Radius Server
#
# GET /radiusservers/{id}
# operationId: radius_servers_get
export def "radiusservers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> record<_id: string, authIdp: string, mfa: string, name: string, networkSourceIp: string, organization: string, sharedSecret: string, tagNames: list<string>, tags: list<string>, userLockoutAction: string, userPasswordExpirationAction: string, userPasswordEnabled: bool, userCertEnabled: bool, deviceCertEnabled: bool, caCert: string, requireTlsAuth: bool, radsecEnabled: bool, requireRadsec: bool, caSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/radiusservers/($id)")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Radius Servers
#
# PUT /radiusservers/{id}
# operationId: radius_servers_put
export def "radiusservers put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --mfa: string@mfa-completer
  name: string
  networkSourceIp: string
  --tags: list
  --userLockoutAction: string
  --userPasswordExpirationAction: string
  sharedSecret: string
  --userPasswordEnabled: oneof<nothing, bool>
  --userCertEnabled: oneof<nothing, bool>
  --deviceCertEnabled: oneof<nothing, bool>
  --caCert: string
  --requireTlsAuth: oneof<nothing, bool>
  --radsecEnabled: oneof<nothing, bool>
  --requireRadsec: oneof<nothing, bool>
  --caSource: string@caSource-completer # default: NONE
]: any -> record<_id: string, authIdp: string, mfa: string, name: string, networkSourceIp: string, tagNames: list<string>, userLockoutAction: string, userPasswordExpirationAction: string, userPasswordEnabled: bool, userCertEnabled: bool, deviceCertEnabled: bool, caCert: string, requireTlsAuth: bool, radsecEnabled: bool, requireRadsec: bool, caSource: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/radiusservers/($id)")
  let body = {mfa: $mfa, name: $name, networkSourceIp: $networkSourceIp, tags: $tags, userLockoutAction: $userLockoutAction, userPasswordExpirationAction: $userPasswordExpirationAction, sharedSecret: $sharedSecret, userPasswordEnabled: $userPasswordEnabled, userCertEnabled: $userCertEnabled, deviceCertEnabled: $deviceCertEnabled, caCert: $caCert, requireTlsAuth: $requireTlsAuth, radsecEnabled: $radsecEnabled, requireRadsec: $requireRadsec, caSource: $caSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Radius Server
#
# DELETE /radiusservers/{id}
# operationId: radius_servers_delete
export def "radiusservers delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> record<_id: string, authIdp: string, mfa: string, name: string, networkSourceIp: string, tagNames: list<string>, userLockoutAction: string, userPasswordExpirationAction: string, userPasswordEnabled: bool, userCertEnabled: bool, deviceCertEnabled: bool, caCert: string, requireTlsAuth: bool, radsecEnabled: bool, requireRadsec: bool, caSource: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/radiusservers/($id)")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Organizations
#
# POST /search/organizations
# operationId: search_organizations_post
export def "search-organizations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --body-fields: string
  --filter: record
  --searchFilter: record
]: any -> record<results: table<_id: string, displayName: string>, totalCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/organizations" $qp)
  let body = {fields: $body_fields, filter: $filter, searchFilter: $searchFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search Systems
#
# POST /search/systems
# operationId: search_systems_post
export def "search-systems post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --x-org-id: string
  --x-eventually-consistent: oneof<nothing, bool> # EXPERIMENTAL! Use to acknowledge eventually consistent data in response.
  --body-fields: string
  --filter: record
  --searchFilter: record
]: any -> record<results: table<_id: string, active: bool, agentHasFullDiskAccess: bool, agentVersion: string, allowMultiFactorAuthentication: bool, allowPublicKeyAuthentication: bool, allowSshPasswordAuthentication: bool, allowSshRootLogin: bool, amazonInstanceID: string, arch: string, archFamily: string, attributes: list, connectionHistory: list, created: string, description: string, desktopCapable: bool, displayName: string, fde: record, fileSystem: string, hasServiceAccount: bool, hostname: string, hwVendor: string, isPolicyBound: bool, lastContact: string, modifySSHDConfig: bool, networkInterfaces: list, organization: string, os: string, osVersionDetail: record, policyStats: record, provisionMetadata: record, primarySystemUser: record, remoteIP: string, serialNumber: string, sshRootEnabled: bool, sshdParams: list, systemInsights: record, systemTimezone: int, tags: list, templateName: string, version: string, mdm: record, builtInCommands: list, osFamily: string, domainInfo: record, userMetrics: list, serviceAccountState: record, azureAdJoined: bool, displayManager: string, secureLogin: record, remoteAssistAgentVersion: string, primarySystemUser__id: string, primarySystemUser_attributes: list, primarySystemUser_company: string, primarySystemUser_costCenter: string, primarySystemUser_department: string, primarySystemUser_description: string, primarySystemUser_email: string, primarySystemUser_employeeType: string, primarySystemUser_jobTitle: string, primarySystemUser_location: string, primarySystemUser_manager: string, primarySystemUser_state: string, memberof: list, primarySystemUser_memberof: list>, totalCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/systems" $qp)
  let body = {fields: $body_fields, filter: $filter, searchFilter: $searchFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id, "x-eventually-consistent": $x_eventually_consistent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search System Users
#
# POST /search/systemusers
# operationId: search_systemusers_post
export def "search-systemusers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --x-org-id: string
  --x-eventually-consistent: oneof<nothing, bool> # EXPERIMENTAL! Use to acknowledge eventually consistent data in response.
  --body-fields: string
  --filter: record
  --searchFilter: record
]: any -> record<results: table<_id: string, account_locked: bool, account_locked_date: string, activated: bool, admin: record, addresses: list, allow_public_key: bool, alternateEmail: string, attributes: list, badLoginAttempts: int, company: string, costCenter: string, created: string, department: string, description: string, disableDeviceMaxLoginAttempts: bool, displayname: string, email: string, employeeIdentifier: string, employeeType: string, enable_managed_uid: bool, enable_user_portal_multifactor: bool, external_dn: string, external_password_expiration_date: string, external_source_type: string, externally_managed: bool, firstname: string, jobTitle: string, lastname: string, ldap_binding_user: bool, location: string, manager: string, mfa: record, mfaEnrollment: record, middlename: string, organization: string, password_date: string, password_expiration_date: string, password_expired: bool, password_never_expires: bool, passwordless_sudo: bool, phoneNumbers: list, public_key: string, recoveryEmail: record, relationships: list, samba_service_user: bool, ssh_keys: list, state: string, sudo: bool, suspended: bool, tags: list, totp_enabled: bool, unix_guid: int, unix_uid: int, username: string, managedAppleId: string, creationSource: string, restrictedFields: list, memberof: list>, totalCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/systemusers" $qp)
  let body = {fields: $body_fields, filter: $filter, searchFilter: $searchFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id, "x-eventually-consistent": $x_eventually_consistent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search Commands
#
# POST /search/commands
# operationId: search_commands_post
export def "search-commands post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --x-org-id: string
  --body-fields: string
  --filter: record
  --searchFilter: record
]: any -> record<results: table<_id: string, command: string, commandType: string, launchType: string, listensTo: string, name: string, organization: string, schedule: string, scheduleRepeatType: string, trigger: string, description: string, aiGenerated: bool, templatingRequired: bool>, totalCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/commands" $qp)
  let body = {fields: $body_fields, filter: $filter, searchFilter: $searchFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search Commands Results
#
# POST /search/commandresults
# operationId: search_commandresults_post
export def "search-commandresults post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --x-org-id: string
  --body-fields: string
  --filter: record
  --searchFilter: record
]: any -> record<totalCount: int, results: table<command: string, exitCode: int, name: string, sudo: bool, system: string, systemId: string, user: string, workflowId: string, _id: string, response: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/commandresults" $qp)
  let body = {fields: $body_fields, filter: $filter, searchFilter: $searchFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List All Systems
#
# GET /systems
# operationId: systems_list
export def "systems list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --search: string # A nested object containing a `searchTerm` string or array of strings and a list of `fields` to search on.
  --skip: int # The offset into the records to return. (default: 0)
  --qp-sort: string # Use space separated sort parameters to sort the collection. Default sort is ascending. Prefix with `-` to sort descending.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --x-org-id: string
]: nothing -> record<results: table<_id: string, active: bool, agentHasFullDiskAccess: bool, agentVersion: string, allowMultiFactorAuthentication: bool, allowPublicKeyAuthentication: bool, allowSshPasswordAuthentication: bool, allowSshRootLogin: bool, amazonInstanceID: string, arch: string, archFamily: string, attributes: list, connectionHistory: list, created: string, description: string, desktopCapable: bool, displayName: string, fde: record, fileSystem: string, hasServiceAccount: bool, hostname: string, hwVendor: string, isPolicyBound: bool, lastContact: string, modifySSHDConfig: bool, networkInterfaces: list, organization: string, os: string, osVersionDetail: record, policyStats: record, provisionMetadata: record, primarySystemUser: record, remoteIP: string, serialNumber: string, sshRootEnabled: bool, sshdParams: list, systemInsights: record, systemTimezone: int, tags: list, templateName: string, version: string, mdm: record, builtInCommands: list, osFamily: string, domainInfo: record, userMetrics: list, serviceAccountState: record, azureAdJoined: bool, displayManager: string, secureLogin: record, remoteAssistAgentVersion: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/systems" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List an individual system
#
# GET /systems/{id}
# operationId: systems_get
export def "systems get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --Date: string # Current date header for the System Context API
  --Authorization: string # Authorization header for the System Context API
  --x-org-id: string
]: nothing -> record<_id: string, active: bool, agentHasFullDiskAccess: bool, agentVersion: string, allowMultiFactorAuthentication: bool, allowPublicKeyAuthentication: bool, allowSshPasswordAuthentication: bool, allowSshRootLogin: bool, amazonInstanceID: string, arch: string, archFamily: string, attributes: table<name: string, value: string>, connectionHistory: list<record>, created: string, description: string, desktopCapable: bool, displayName: string, fde: record<active: bool, keyPresent: bool>, fileSystem: string, hasServiceAccount: bool, hostname: string, hwVendor: string, isPolicyBound: bool, lastContact: string, modifySSHDConfig: bool, networkInterfaces: table<address: string, family: string, internal: bool, name: string>, organization: string, os: string, osVersionDetail: record<osName: string, releaseName: string, major: string, minor: string, patch: string, majorNumber: int, minorNumber: int, patchNumber: int, revision: string, distributionName: string, version: string>, policyStats: record<duplicate: int, failed: int, pending: int, success: int, total: int, unsupportedOs: int>, provisionMetadata: record<provisioner: record<type: string, provisionerId: string>>, primarySystemUser: record<id: string>, remoteIP: string, serialNumber: string, sshRootEnabled: bool, sshdParams: table<name: string, value: string>, systemInsights: record<state: string>, systemTimezone: int, tags: list<string>, templateName: string, version: string, mdm: record<vendor: string, internal: record<deviceId: string, windowsDeviceId: string>, profileIdentifier: string, dep: bool, userApproved: bool, enrollmentType: string, providerId: string, windows: record<upn: string>, lostModeStatus: string>, builtInCommands: table<type: string, name: string>, osFamily: string, domainInfo: record<partOfDomain: bool, domainName: string>, userMetrics: table<userName: string, admin: bool, managed: bool, suspended: bool, secureTokenEnabled: bool>, serviceAccountState: record<hasSecureToken: bool, passwordODValid: bool, passwordAPFSValid: bool>, azureAdJoined: bool, displayManager: string, secureLogin: record<supported: bool, enabled: bool>, remoteAssistAgentVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/systems/($id)" $qp)
  let extra_headers = {"Date": $Date, "Authorization": $Authorization, "x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a system
#
# PUT /systems/{id}
# operationId: systems_put
# --agentBoundMessages item shape: {cmd?: string}
# --attributes item shape: {name?: string, value?: string}
export def "systems put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # Current date header for the System Context API
  --Authorization: string # Authorization header for the System Context API
  --x-org-id: string
  --agentBoundMessages: list # item shape: {cmd?: string}
  --allowMultiFactorAuthentication: oneof<nothing, bool>
  --allowPublicKeyAuthentication: oneof<nothing, bool>
  --allowSshPasswordAuthentication: oneof<nothing, bool>
  --allowSshRootLogin: oneof<nothing, bool>
  --displayName: string
  --attributes: list # item shape: {name?: string, value?: string}
  --tags: list
]: any -> record<_id: string, active: bool, agentHasFullDiskAccess: bool, agentVersion: string, allowMultiFactorAuthentication: bool, allowPublicKeyAuthentication: bool, allowSshPasswordAuthentication: bool, allowSshRootLogin: bool, amazonInstanceID: string, arch: string, archFamily: string, attributes: table<name: string, value: string>, connectionHistory: list<record>, created: string, description: string, desktopCapable: bool, displayName: string, fde: record<active: bool, keyPresent: bool>, fileSystem: string, hasServiceAccount: bool, hostname: string, hwVendor: string, isPolicyBound: bool, lastContact: string, modifySSHDConfig: bool, networkInterfaces: table<address: string, family: string, internal: bool, name: string>, organization: string, os: string, osVersionDetail: record<osName: string, releaseName: string, major: string, minor: string, patch: string, majorNumber: int, minorNumber: int, patchNumber: int, revision: string, distributionName: string, version: string>, policyStats: record<duplicate: int, failed: int, pending: int, success: int, total: int, unsupportedOs: int>, provisionMetadata: record<provisioner: record<type: string, provisionerId: string>>, primarySystemUser: record<id: string>, remoteIP: string, serialNumber: string, sshRootEnabled: bool, sshdParams: table<name: string, value: string>, systemInsights: record<state: string>, systemTimezone: int, tags: list<string>, templateName: string, version: string, mdm: record<vendor: string, internal: record<deviceId: string, windowsDeviceId: string>, profileIdentifier: string, dep: bool, userApproved: bool, enrollmentType: string, providerId: string, windows: record<upn: string>, lostModeStatus: string>, builtInCommands: table<type: string, name: string>, osFamily: string, domainInfo: record<partOfDomain: bool, domainName: string>, userMetrics: table<userName: string, admin: bool, managed: bool, suspended: bool, secureTokenEnabled: bool>, serviceAccountState: record<hasSecureToken: bool, passwordODValid: bool, passwordAPFSValid: bool>, azureAdJoined: bool, displayManager: string, secureLogin: record<supported: bool, enabled: bool>, remoteAssistAgentVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systems/($id)")
  let body = {agentBoundMessages: $agentBoundMessages, allowMultiFactorAuthentication: $allowMultiFactorAuthentication, allowPublicKeyAuthentication: $allowPublicKeyAuthentication, allowSshPasswordAuthentication: $allowSshPasswordAuthentication, allowSshRootLogin: $allowSshRootLogin, displayName: $displayName, attributes: $attributes, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Date": $Date, "Authorization": $Authorization, "x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a System
#
# DELETE /systems/{id}
# operationId: systems_delete
export def "systems delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # Current date header for the System Context API
  --Authorization: string # Authorization header for the System Context API
  --x-org-id: string
]: nothing -> record<_id: string, active: bool, agentHasFullDiskAccess: bool, agentVersion: string, allowMultiFactorAuthentication: bool, allowPublicKeyAuthentication: bool, allowSshPasswordAuthentication: bool, allowSshRootLogin: bool, amazonInstanceID: string, arch: string, archFamily: string, attributes: table<name: string, value: string>, connectionHistory: list<record>, created: string, description: string, desktopCapable: bool, displayName: string, fde: record<active: bool, keyPresent: bool>, fileSystem: string, hasServiceAccount: bool, hostname: string, hwVendor: string, isPolicyBound: bool, lastContact: string, modifySSHDConfig: bool, networkInterfaces: table<address: string, family: string, internal: bool, name: string>, organization: string, os: string, osVersionDetail: record<osName: string, releaseName: string, major: string, minor: string, patch: string, majorNumber: int, minorNumber: int, patchNumber: int, revision: string, distributionName: string, version: string>, policyStats: record<duplicate: int, failed: int, pending: int, success: int, total: int, unsupportedOs: int>, provisionMetadata: record<provisioner: record<type: string, provisionerId: string>>, primarySystemUser: record<id: string>, remoteIP: string, serialNumber: string, sshRootEnabled: bool, sshdParams: table<name: string, value: string>, systemInsights: record<state: string>, systemTimezone: int, tags: list<string>, templateName: string, version: string, mdm: record<vendor: string, internal: record<deviceId: string, windowsDeviceId: string>, profileIdentifier: string, dep: bool, userApproved: bool, enrollmentType: string, providerId: string, windows: record<upn: string>, lostModeStatus: string>, builtInCommands: table<type: string, name: string>, osFamily: string, domainInfo: record<partOfDomain: bool, domainName: string>, userMetrics: table<userName: string, admin: bool, managed: bool, suspended: bool, secureTokenEnabled: bool>, serviceAccountState: record<hasSecureToken: bool, passwordODValid: bool, passwordAPFSValid: bool>, azureAdJoined: bool, displayManager: string, secureLogin: record<supported: bool, enabled: bool>, remoteAssistAgentVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systems/($id)")
  let extra_headers = {"Date": $Date, "Authorization": $Authorization, "x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all system users
#
# GET /systemusers
# operationId: systemusers_list
export def "systemusers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of records to return at once. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
  --qp-sort: string # The space separated fields used to sort the collection. Default sort is ascending, prefix with `-` to sort descending.
  --qp-fields: string # The space separated fields included in the returned records. If omitted the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --search: string # A nested object containing a `searchTerm` string or array of strings and a list of `fields` to search on.
  --x-org-id: string
]: nothing -> record<results: table<_id: string, account_locked: bool, account_locked_date: string, activated: bool, admin: record, addresses: list, allow_public_key: bool, alternateEmail: string, attributes: list, badLoginAttempts: int, company: string, costCenter: string, created: string, department: string, description: string, disableDeviceMaxLoginAttempts: bool, displayname: string, email: string, employeeIdentifier: string, employeeType: string, enable_managed_uid: bool, enable_user_portal_multifactor: bool, external_dn: string, external_password_expiration_date: string, external_source_type: string, externally_managed: bool, firstname: string, jobTitle: string, lastname: string, ldap_binding_user: bool, location: string, manager: string, mfa: record, mfaEnrollment: record, middlename: string, organization: string, password_date: string, password_expiration_date: string, password_expired: bool, password_never_expires: bool, passwordless_sudo: bool, phoneNumbers: list, public_key: string, recoveryEmail: record, relationships: list, samba_service_user: bool, ssh_keys: list, state: string, sudo: bool, suspended: bool, tags: list, totp_enabled: bool, unix_guid: int, unix_uid: int, username: string, managedAppleId: string, creationSource: string, delegatedAuthority: record, restrictedFields: list>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/systemusers" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a system user
#
# POST /systemusers
# operationId: systemusers_post
# --addresses item shape: {country?: string, extendedAddress?: string, locality?: string, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
# --attributes item shape: {name?: string, value?: string}
# --mfa shape: {configured?: bool, exclusion?: bool, exclusionUntil?: string, exclusionDays?: int}
# --phoneNumbers item shape: {number?: string, type?: string}
# --recoveryEmail shape: {address?: string}
# --relationships item shape: {type?: string, value?: string}
# --restrictedFields item shape: {field?: "addresses"|"company"|"costCenter"|"department"|"description"|"displayname"|"email"|"employeeIdentifier"|"employeeType"|"firstname"|"jobTitle"|"lastname"|"location"|"middlename"|"password"|"phoneNumbers"|"sudo"|"username", type?: "active_directory"|"federated_identity_provider"|"scim", id?: string}
export def "systemusers post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fullValidationDetails: string # Pass this query parameter when a client wants all validation errors to be returned with a detailed error response for the form field specified. The current form fields are allowed:  * `password`  #### Password validation flag Use the `password` validation flag to receive details on a possible bad request response ``` ?fullValidationDetails=password ``` Without the flag, default behavior will be a normal 400 with only a single validation string error #### Expected Behavior Clients can expect a list of validation error mappings for the validation query field in the details provided on the response: ``` {   "code": 400,   "message": "Password validation fail",   "status": "INVALID_ARGUMENT",   "details": [       {         "fieldViolationsList": [           {"field": "password", "description": "specialCharacter"}         ],         '@type': 'type.googleapis.com/google.rpc.BadRequest',       },   ], }, ```
  --x-org-id: string
  --account-locked: oneof<nothing, bool>
  --activated: oneof<nothing, bool>
  --addresses: list # item shape: {country?: string, extendedAddress?: string, locality?: string, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
  --allow-public-key: oneof<nothing, bool>
  --alternateEmail: string
  --attributes: list # item shape: {name?: string, value?: string}
  --company: string
  --costCenter: string
  --department: string
  --description: string
  --disableDeviceMaxLoginAttempts: oneof<nothing, bool>
  --displayname: string
  email: string
  --employeeIdentifier: string # Must be unique per user. 
  --employeeType: string
  --enable-managed-uid: oneof<nothing, bool>
  --enable-user-portal-multifactor: oneof<nothing, bool>
  --external-dn: string
  --external-password-expiration-date: string # format: date-time
  --external-source-type: string
  --externally-managed: oneof<nothing, bool> # The externally_managed property has been deprecated. Whenever a user has their externally_managed field modified their restrictedFields property gets populated with the appropriate value, even if it is already set to a value an administrator manually set.
  --firstname: string
  --jobTitle: string
  --lastname: string
  --ldap-binding-user: oneof<nothing, bool>
  --location: string
  --manager: string # Relation with another systemuser to identify the last as a manager.
  --mfa: record # shape: {configured?: bool, exclusion?: bool, exclusionUntil?: string, exclusionDays?: int}
  --middlename: string
  --password: string
  --password-never-expires: oneof<nothing, bool>
  --passwordless-sudo: oneof<nothing, bool>
  --phoneNumbers: list # item shape: {number?: string, type?: string}
  --public-key: string
  --recoveryEmail: record # shape: {address?: string}
  --relationships: list # item shape: {type?: string, value?: string}
  --samba-service-user: oneof<nothing, bool>
  --state: string@state-completer
  --sudo: oneof<nothing, bool>
  --suspended: oneof<nothing, bool>
  --tags: list
  --unix-guid: int
  --unix-uid: int
  username: string
  --managedAppleId: string
  --delegatedAuthority: any
  --restrictedFields: list # item shape: {field?: "addresses"|"company"|"costCenter"|"department"|"description"|"displayname"|"email"|"employeeIdentifier"|"employeeType"|"firstname"|"jobTitle"|"lastname"|"location"|"middlename"|"password"|"phoneNumbers"|"sudo"|"username", type?: "active_directory"|"federated_identity_provider"|"scim", id?: string}
]: any -> record<_id: string, account_locked: bool, account_locked_date: string, activated: bool, admin: record<id: string, roleName: string, roleNames: list<string>>, addresses: table<country: string, extendedAddress: string, id: string, locality: string, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, allow_public_key: bool, alternateEmail: string, attributes: table<name: string, value: string>, badLoginAttempts: int, company: string, costCenter: string, created: string, department: string, description: string, disableDeviceMaxLoginAttempts: bool, displayname: string, email: string, employeeIdentifier: string, employeeType: string, enable_managed_uid: bool, enable_user_portal_multifactor: bool, external_dn: string, external_password_expiration_date: string, external_source_type: string, externally_managed: bool, firstname: string, jobTitle: string, lastname: string, ldap_binding_user: bool, location: string, manager: string, mfa: record<configured: bool, exclusion: bool, exclusionUntil: string, exclusionDays: int>, mfaEnrollment: record<totpStatus: string, webAuthnStatus: string, pushStatus: string, smsStatus: string, overallStatus: string, jcGoStatus: string>, middlename: string, organization: string, password_date: string, password_expiration_date: string, password_expired: bool, password_never_expires: bool, passwordless_sudo: bool, phoneNumbers: table<id: string, number: string, type: string>, public_key: string, recoveryEmail: record<address: string, verified: bool, verifiedAt: string>, relationships: table<type: string, value: string>, samba_service_user: bool, ssh_keys: table<_id: string, create_date: string, name: string, public_key: string>, state: string, sudo: bool, suspended: bool, tags: list<string>, totp_enabled: bool, unix_guid: int, unix_uid: int, username: string, managedAppleId: string, creationSource: string, delegatedAuthority: record<name: string, id: string>, restrictedFields: table<field: string, type: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fullValidationDetails" $fullValidationDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/systemusers" $qp)
  let body = {account_locked: $account_locked, activated: $activated, addresses: $addresses, allow_public_key: $allow_public_key, alternateEmail: $alternateEmail, attributes: $attributes, company: $company, costCenter: $costCenter, department: $department, description: $description, disableDeviceMaxLoginAttempts: $disableDeviceMaxLoginAttempts, displayname: $displayname, email: $email, employeeIdentifier: $employeeIdentifier, employeeType: $employeeType, enable_managed_uid: $enable_managed_uid, enable_user_portal_multifactor: $enable_user_portal_multifactor, external_dn: $external_dn, external_password_expiration_date: $external_password_expiration_date, external_source_type: $external_source_type, externally_managed: $externally_managed, firstname: $firstname, jobTitle: $jobTitle, lastname: $lastname, ldap_binding_user: $ldap_binding_user, location: $location, manager: $manager, mfa: $mfa, middlename: $middlename, password: $password, password_never_expires: $password_never_expires, passwordless_sudo: $passwordless_sudo, phoneNumbers: $phoneNumbers, public_key: $public_key, recoveryEmail: $recoveryEmail, relationships: $relationships, samba_service_user: $samba_service_user, state: $state, sudo: $sudo, suspended: $suspended, tags: $tags, unix_guid: $unix_guid, unix_uid: $unix_uid, username: $username, managedAppleId: $managedAppleId, delegatedAuthority: $delegatedAuthority, restrictedFields: $restrictedFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List a system user
#
# GET /systemusers/{id}
# operationId: systemusers_get
export def "systemusers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Use a space seperated string of field parameters to include the data in the response. If omitted, the default list of fields will be returned.
  --filter: string # A filter to apply to the query. See the supported operators below. For more complex searches, see the related `/search/<domain>` endpoints, e.g. `/search/systems`.  **Filter structure**: The filter syntax follows a consistent pattern of `<field>:<operator>:<value>` (e.g. `department:$eq:Finance`)  **field** = Populate with a valid field from an endpoint response.  **operator** = Supported operators are: - `$eq` - equals (exact match) - `$in` - equals (multiple match terms). Separate terms by `|` character: `<field>:$in:<term one>|<term two>`   - any item with `<field>` that matches ANY of the match terms will be returned   - to use a literal `|` character inside a match term, it must be "escaped" using a backslash `\` (`"\|"`)     - for `GET` endpoints, only ONE backslash is needed: `costCenter:$in:Atlanta\|Tampa|Chicago`     - for `POST` endpoints, TWO backslashes are needed due to the nature of JSON: `costCenter:$in:Atlanta\\|Tampa|Chicago`     - resulting match terms: `"Atlanta|Tampa", "Chicago"` - `$ne` - does not equal - `$nin` - does not equal (multiple match terms). Separate terms by `|` character: `<field>:$nin:<term one>|<term two>`   - any item with `<field>` that DOES NOT match ANY of the match terms will be returned   - refer to above `$in` documentation on using literal `|` character in match terms - `$lt` - is less than - `$lte` - is less than or equal to - `$gt` - is greater than - `$gte` - is greater than or equal to - `$sw` - Finds items where the field value begins with the specified term.  **Eventually Consistent Operators** = These advanced operators support multiple-term matching and **require the `x-eventually-consistent` API request header** to be set as `true`. Terms within the `value` must be separated by the `|` character. - `$sw` - Matches any item where the field value **begins** with **any one** of the provided terms. E.g `<field>:$sw:<term one>|<term two>` - `$ew` - Matches any item where the field value **ends** with **any one** of the provided terms. E.g `<field>:$ew:<term one>|<term two>` - `$co` - Matches any item where the field value **contains** **any one** of the provided terms. E.g `<field>:$co:<term one>|<term two>` - `$nco` - Matches any item where the field value **does not contain** any of the provided terms. E.g `<field>:$nco:<term one>|<term two>`  _Note: v1 operators differ from v2 operators._  _Note: For v1 operators, excluding the `$` will result in undefined behavior **and is not recommended.**_  **value** = Populate with the value you want to search for. **Case sensitive**.  **Examples** - `GET /users?filter=username:$eq:testuser` - `GET /systemusers?filter=department:$in:Finance|IT|Shipping & Receiving` - an item with `{ department: "IT" }` will match - `GET /systemusers?filter=department:$in:Finance \| Sales|IT` - an item with `{ department: "Finance | Sales" }` will match - `GET /systemusers?filter=department:$ne:Accounting` - `GET /systemusers?filter=department:$nin:Finance|IT|Shipping & Receiving` - an item with `{ department: "HR" }` will match - `GET /systemusers?filter=password_expiration_date:$lte:2021-10-24` - `GET /systems?filter[0]=firstname:$eq:foo&filter[1]=lastname:$eq:bar` - this will AND the filters together. - `GET /systems?filter[or][0]=lastname:$eq:foo&filter[or][1]=lastname:$eq:bar` - this will OR the filters together. - `GET /systemusers?filter=department:$sw:Shipping` - an item with `{ department: "Shipping & Receiving" }` will match - `GET /systemusers?filter=department:$sw:Shipping\|Receiving` - an item with `{ department: "Shipping|Receiving Item" }` will match - `GET /systemusers?filter=department:$sw:Shipping|Receiving` - an item with `{ department: "Shipping Item" }` will match or an item with `{ department: "Receiving Item" }` will match. **Use it with `x-eventually-consistent` header set to `true`:**
  --x-org-id: string
]: nothing -> record<_id: string, account_locked: bool, account_locked_date: string, activated: bool, admin: record<id: string, roleName: string, roleNames: list<string>>, addresses: table<country: string, extendedAddress: string, id: string, locality: string, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, allow_public_key: bool, alternateEmail: string, attributes: table<name: string, value: string>, badLoginAttempts: int, company: string, costCenter: string, created: string, department: string, description: string, disableDeviceMaxLoginAttempts: bool, displayname: string, email: string, employeeIdentifier: string, employeeType: string, enable_managed_uid: bool, enable_user_portal_multifactor: bool, external_dn: string, external_password_expiration_date: string, external_source_type: string, externally_managed: bool, firstname: string, jobTitle: string, lastname: string, ldap_binding_user: bool, location: string, manager: string, mfa: record<configured: bool, exclusion: bool, exclusionUntil: string, exclusionDays: int>, mfaEnrollment: record<totpStatus: string, webAuthnStatus: string, pushStatus: string, smsStatus: string, overallStatus: string, jcGoStatus: string>, middlename: string, organization: string, password_date: string, password_expiration_date: string, password_expired: bool, password_never_expires: bool, passwordless_sudo: bool, phoneNumbers: table<id: string, number: string, type: string>, public_key: string, recoveryEmail: record<address: string, verified: bool, verifiedAt: string>, relationships: table<type: string, value: string>, samba_service_user: bool, ssh_keys: table<_id: string, create_date: string, name: string, public_key: string>, state: string, sudo: bool, suspended: bool, tags: list<string>, totp_enabled: bool, unix_guid: int, unix_uid: int, username: string, managedAppleId: string, creationSource: string, delegatedAuthority: record<name: string, id: string>, restrictedFields: table<field: string, type: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/systemusers/($id)" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a system user
#
# PUT /systemusers/{id}
# operationId: systemusers_put
# --addresses item shape: {country?: string, extendedAddress?: string, locality?: string, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
# --attributes item shape: {name?: string, value?: string}
# --mfa shape: {configured?: bool, exclusion?: bool, exclusionUntil?: string, exclusionDays?: int}
# --phoneNumbers item shape: {number?: string, type?: string}
# --relationships item shape: {type?: string, value?: string}
# --ssh_keys item shape: {name: string, public_key: string}
# --restrictedFields item shape: {field?: "addresses"|"company"|"costCenter"|"department"|"description"|"displayname"|"email"|"employeeIdentifier"|"employeeType"|"firstname"|"jobTitle"|"lastname"|"location"|"middlename"|"password"|"phoneNumbers"|"sudo"|"username", type?: "active_directory"|"federated_identity_provider"|"scim", id?: string}
export def "systemusers put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fullValidationDetails: string # This endpoint can take in a query when a client wants all validation errors to be returned with error response for the form field specified, i.e. 'password' #### Password validation flag Use the "password" validation flag to receive details on a possible bad request response Without the `password` flag, default behavior will be a normal 400 with only a validation string message ``` ?fullValidationDetails=password ``` #### Expected Behavior Clients can expect a list of validation error mappings for the validation query field in the details provided on the response: ``` {   "code": 400,   "message": "Password validation fail",   "status": "INVALID_ARGUMENT",   "details": [       {         "fieldViolationsList": [{ "field": "password", "description": "passwordHistory" }],         '@type': 'type.googleapis.com/google.rpc.BadRequest',       },   ], }, ```
  --x-org-id: string
  --account-locked: oneof<nothing, bool>
  --addresses: list # type, poBox, extendedAddress, streetAddress, locality, region, postalCode, country — item shape: {country?: string, extendedAddress?: string, locality?: string, poBox?: string, postalCode?: string, region?: string, streetAddress?: string, type?: string}
  --allow-public-key: oneof<nothing, bool>
  --alternateEmail: string
  --attributes: list # item shape: {name?: string, value?: string}
  --company: string
  --costCenter: string
  --department: string
  --description: string
  --disableDeviceMaxLoginAttempts: oneof<nothing, bool>
  --displayname: string
  --email: string
  --employeeIdentifier: string # Must be unique per user. 
  --employeeType: string
  --enable-managed-uid: oneof<nothing, bool>
  --enable-user-portal-multifactor: oneof<nothing, bool>
  --external-dn: string
  --external-password-expiration-date: string
  --external-source-type: string
  --externally-managed: oneof<nothing, bool> # The externally_managed property has been deprecated. Whenever a user has their externally_managed field modified their restrictedFields property gets populated with the appropriate value, even if it is already set to a value an administrator manually set.
  --firstname: string
  --jobTitle: string
  --lastname: string
  --ldap-binding-user: oneof<nothing, bool>
  --location: string
  --manager: string # Relation with another systemuser to identify the last as a manager.
  --mfa: record # shape: {configured?: bool, exclusion?: bool, exclusionUntil?: string, exclusionDays?: int}
  --middlename: string
  --password: string
  --password-never-expires: oneof<nothing, bool>
  --phoneNumbers: list # item shape: {number?: string, type?: string}
  --public-key: string
  --relationships: list # item shape: {type?: string, value?: string}
  --samba-service-user: oneof<nothing, bool>
  --ssh-keys: list # item shape: {name: string, public_key: string}
  --state: string@state-completer-1
  --sudo: oneof<nothing, bool>
  --suspended: oneof<nothing, bool>
  --tags: list
  --unix-guid: int
  --unix-uid: int
  --username: string
  --managedAppleId: string
  --delegatedAuthority: any
  --restrictedFields: list # item shape: {field?: "addresses"|"company"|"costCenter"|"department"|"description"|"displayname"|"email"|"employeeIdentifier"|"employeeType"|"firstname"|"jobTitle"|"lastname"|"location"|"middlename"|"password"|"phoneNumbers"|"sudo"|"username", type?: "active_directory"|"federated_identity_provider"|"scim", id?: string}
]: any -> record<_id: string, account_locked: bool, account_locked_date: string, activated: bool, admin: record<id: string, roleName: string, roleNames: list<string>>, addresses: table<country: string, extendedAddress: string, id: string, locality: string, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, allow_public_key: bool, alternateEmail: string, attributes: table<name: string, value: string>, badLoginAttempts: int, company: string, costCenter: string, created: string, department: string, description: string, disableDeviceMaxLoginAttempts: bool, displayname: string, email: string, employeeIdentifier: string, employeeType: string, enable_managed_uid: bool, enable_user_portal_multifactor: bool, external_dn: string, external_password_expiration_date: string, external_source_type: string, externally_managed: bool, firstname: string, jobTitle: string, lastname: string, ldap_binding_user: bool, location: string, manager: string, mfa: record<configured: bool, exclusion: bool, exclusionUntil: string, exclusionDays: int>, mfaEnrollment: record<totpStatus: string, webAuthnStatus: string, pushStatus: string, smsStatus: string, overallStatus: string, jcGoStatus: string>, middlename: string, organization: string, password_date: string, password_expiration_date: string, password_expired: bool, password_never_expires: bool, passwordless_sudo: bool, phoneNumbers: table<id: string, number: string, type: string>, public_key: string, recoveryEmail: record<address: string, verified: bool, verifiedAt: string>, relationships: table<type: string, value: string>, samba_service_user: bool, ssh_keys: table<_id: string, create_date: string, name: string, public_key: string>, state: string, sudo: bool, suspended: bool, tags: list<string>, totp_enabled: bool, unix_guid: int, unix_uid: int, username: string, managedAppleId: string, creationSource: string, delegatedAuthority: record<name: string, id: string>, restrictedFields: table<field: string, type: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fullValidationDetails" $fullValidationDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/systemusers/($id)" $qp)
  let body = {account_locked: $account_locked, addresses: $addresses, allow_public_key: $allow_public_key, alternateEmail: $alternateEmail, attributes: $attributes, company: $company, costCenter: $costCenter, department: $department, description: $description, disableDeviceMaxLoginAttempts: $disableDeviceMaxLoginAttempts, displayname: $displayname, email: $email, employeeIdentifier: $employeeIdentifier, employeeType: $employeeType, enable_managed_uid: $enable_managed_uid, enable_user_portal_multifactor: $enable_user_portal_multifactor, external_dn: $external_dn, external_password_expiration_date: $external_password_expiration_date, external_source_type: $external_source_type, externally_managed: $externally_managed, firstname: $firstname, jobTitle: $jobTitle, lastname: $lastname, ldap_binding_user: $ldap_binding_user, location: $location, manager: $manager, mfa: $mfa, middlename: $middlename, password: $password, password_never_expires: $password_never_expires, phoneNumbers: $phoneNumbers, public_key: $public_key, relationships: $relationships, samba_service_user: $samba_service_user, ssh_keys: $ssh_keys, state: $state, sudo: $sudo, suspended: $suspended, tags: $tags, unix_guid: $unix_guid, unix_uid: $unix_uid, username: $username, managedAppleId: $managedAppleId, delegatedAuthority: $delegatedAuthority, restrictedFields: $restrictedFields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a system user
#
# DELETE /systemusers/{id}
# operationId: systemusers_delete
export def "systemusers delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cascade-manager: string # This is an optional flag that can be enabled on the DELETE call, DELETE /systemusers/{id}?cascade_manager=null. This parameter will clear the Manager attribute on all direct reports and then delete the account.
  --x-org-id: string
]: nothing -> record<_id: string, account_locked: bool, account_locked_date: string, activated: bool, admin: record<id: string, roleName: string, roleNames: list<string>>, addresses: table<country: string, extendedAddress: string, id: string, locality: string, poBox: string, postalCode: string, region: string, streetAddress: string, type: string>, allow_public_key: bool, alternateEmail: string, attributes: table<name: string, value: string>, badLoginAttempts: int, company: string, costCenter: string, created: string, department: string, description: string, disableDeviceMaxLoginAttempts: bool, displayname: string, email: string, employeeIdentifier: string, employeeType: string, enable_managed_uid: bool, enable_user_portal_multifactor: bool, external_dn: string, external_password_expiration_date: string, external_source_type: string, externally_managed: bool, firstname: string, jobTitle: string, lastname: string, ldap_binding_user: bool, location: string, manager: string, mfa: record<configured: bool, exclusion: bool, exclusionUntil: string, exclusionDays: int>, mfaEnrollment: record<totpStatus: string, webAuthnStatus: string, pushStatus: string, smsStatus: string, overallStatus: string, jcGoStatus: string>, middlename: string, organization: string, password_date: string, password_expiration_date: string, password_expired: bool, password_never_expires: bool, passwordless_sudo: bool, phoneNumbers: table<id: string, number: string, type: string>, public_key: string, recoveryEmail: record<address: string, verified: bool, verifiedAt: string>, relationships: table<type: string, value: string>, samba_service_user: bool, ssh_keys: table<_id: string, create_date: string, name: string, public_key: string>, state: string, sudo: bool, suspended: bool, tags: list<string>, totp_enabled: bool, unix_guid: int, unix_uid: int, username: string, managedAppleId: string, creationSource: string, delegatedAuthority: record<name: string, id: string>, restrictedFields: table<field: string, type: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cascade_manager" $cascade_manager "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/systemusers/($id)" $qp)
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Expire a system user's password
#
# POST /systemusers/{id}/expire
# operationId: systemusers_expire
export def "systemusers-expire expire" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-org-id: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/expire")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force set a system user's password
#
# POST /systemusers/{id}/password
# operationId: systemusers_password
export def "systemusers-password password" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --password: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a system user's MFA properties
#
# POST /systemusers/{id}/mfa/enforce
# operationId: systemusers_mfa_enforce
# --mfa shape: {configured?: bool, exclusion?: bool, exclusionUntil?: string, exclusionDays?: int}
export def "systemusers-mfa-enforce enforce" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --enable-user-portal-multifactor: oneof<nothing, bool> # Whether to require MFA for user portal login
  --mfa: record # shape: {configured?: bool, exclusion?: bool, exclusionUntil?: string, exclusionDays?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/mfa/enforce")
  let body = {enable_user_portal_multifactor: $enable_user_portal_multifactor, mfa: $mfa} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset a system user's MFA token
#
# POST /systemusers/{id}/resetmfa
# operationId: systemusers_resetmfa
export def "systemusers-resetmfa resetmfa" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-org-id: string
  --exclusion: oneof<nothing, bool>
  --exclusionUntil: string # format: date-time
  --exclusionDays: float
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/resetmfa")
  let body = {exclusion: $exclusion, exclusionUntil: $exclusionUntil, exclusionDays: $exclusionDays} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sync a systemuser's mfa enrollment status
#
# POST /systemusers/{id}/mfasync
# operationId: systemusers_mfasync
export def "systemusers-mfasync mfasync" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/mfasync")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a system user's public SSH keys
#
# GET /systemusers/{id}/sshkeys
# operationId: sshkey_list
export def "systemusers-sshkeys list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> table<_id: string, create_date: string, name: string, public_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/sshkeys")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a system user's Public SSH Key
#
# POST /systemusers/{id}/sshkeys
# operationId: sshkey_post
export def "systemusers-sshkeys post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  name: string # The name of the SSH key.
  public_key: string # The Public SSH key.
]: any -> record<_id: string, create_date: string, name: string, public_key: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/sshkeys")
  let body = {name: $name, public_key: $public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Display info about a System User's TOTP enrollment.
#
# GET /systemusers/{id}/totpinfo
# operationId: systemusers_totp_info
export def "systemusers-totpinfo info" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> record<enrollmentDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/totpinfo")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unlock a system user
#
# POST /systemusers/{id}/unlock
# operationId: systemusers_unlock
export def "systemusers-unlock unlock" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-org-id: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/unlock")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a system user's Public SSH Keys
#
# DELETE /systemusers/{systemuser_id}/sshkeys/{id}
# operationId: sshkey_delete
export def "systemusers-sshkeys delete" [
  systemuser_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --x-org-id: string
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($systemuser_id)/sshkeys/($id)")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate System User
#
# POST /systemusers/{id}/state/activate
# operationId: systemusers_state_activate
export def "systemusers-state-activate activate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/state/activate")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Suspend System User
#
# POST /systemusers/{id}/state/suspend
# operationId: systemusers_state_suspend
export def "systemusers-state-suspend suspend" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/state/suspend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Administrator TOTP Reset Initiation
#
# POST /users/resettotp/{id}
# operationId: admin_totpreset_begin
export def "users-resettotp begin" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/resettotp/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a user
#
# PUT /users/{id}
# operationId: users_put
export def "users put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --apiKeyAllowed: oneof<nothing, bool>
  --email: string # format: email
  --enableMultiFactor: oneof<nothing, bool>
  --firstname: string
  --growthData: record
  --lastWhatsNewChecked: string # format: date
  --lastname: string
  --roleName: string
  --roles: list
]: any -> record<_id: string, apiKeyAllowed: bool, apiKeyHash: record<createdAt: string, expireAt: string, prefix: string>, apiKeySet: bool, apiKeyUpdatedAt: string, created: string, disableIntroduction: bool, email: string, enableMultiFactor: bool, firstname: string, growthData: record<onboardingState: record, experimentStates: record>, lastWhatsNewChecked: string, lastname: string, organization: string, passwordUpdatedAt: string, provider: string, role: string, roles: list<string>, roleName: string, roleNames: list<string>, usersTimeZone: string, suspended: bool, sessionCount: int, totpEnrolled: bool, totpUpdatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let body = {apiKeyAllowed: $apiKeyAllowed, email: $email, enableMultiFactor: $enableMultiFactor, firstname: $firstname, growthData: $growthData, lastWhatsNewChecked: $lastWhatsNewChecked, lastname: $lastname, roleName: $roleName, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get results for a specific command
#
# GET /commands/{id}/results
# operationId: commands_getResults
export def "commands-results get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The number of records to return at once. Limited to 100. (default: 10)
  --skip: int # The offset into the records to return. (default: 0)
]: nothing -> table<_id: string, command: string, files: list<string>, name: string, organization: string, response: record<data: record, error: string, id: string>, sudo: bool, system: string, systemId: string, user: string, workflowId: string, workflowInstanceId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "skip" $skip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/commands/($id)/results" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reactivate System User
#
# POST /systemusers/{id}/reactivate
# operationId: systemuser_reactivate
export def "systemusers-reactivate reactivate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
  --email: string # Email address to which the activation email will be sent. If it is not provided, the activation email will be sent to the system user's email address. (format: email)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systemusers/($id)/reactivate")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Administrator Password Reset Initiation
#
# GET /users/reactivate/{id}
# operationId: users_reactivate_get
export def "users-reactivate get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/reactivate/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run a command
#
# POST /runCommand
# operationId: commands_run
export def "run-command run" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The ID of the command.
  --systemIds: list # An optional list of device IDs to run the command on. If omitted, the command will run on devices bound to the command.
]: any -> record<queueIds: list<string>, workflowInstanceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/runCommand")
  let body = {_id: $id, systemIds: $systemIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Erase a System
#
# POST /systems/{system_id}/command/builtin/erase
# operationId: systems_commandBuiltinErase
export def "systems-command-builtin-erase commandBuiltinErase" [
  system_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systems/($system_id)/command/builtin/erase")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lock a System
#
# POST /systems/{system_id}/command/builtin/lock
# operationId: systems_commandBuiltinLock
export def "systems-command-builtin-lock commandBuiltinLock" [
  system_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systems/($system_id)/command/builtin/lock")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restart a System
#
# POST /systems/{system_id}/command/builtin/restart
# operationId: systems_commandBuiltinRestart
export def "systems-command-builtin-restart commandBuiltinRestart" [
  system_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systems/($system_id)/command/builtin/restart")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Shutdown a System
#
# POST /systems/{system_id}/command/builtin/shutdown
# operationId: systems_commandBuiltinShutdown
export def "systems-command-builtin-shutdown commandBuiltinShutdown" [
  system_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-org-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/systems/($system_id)/command/builtin/shutdown")
  let extra_headers = {"x-org-id": $x_org_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
