# Auto-generated client for Catalog API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Catalog-API/1.0/openapi.json
# Auth: --token flag or $env.CATALOG_API_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CATALOG_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-vtex-api-appkey" => { {headers: {X-VTEX-API-AppKey: $token_val}, query: ""} }
    "x-vtex-api-apptoken" => { {headers: {X-VTEX-API-AppToken: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addon-pvt-giftlist-get list-gift" } } | get name | first)
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

# Get Gift List
#
# GET /api/addon/pvt/giftlist/get/{listId}
# operationId: GetGiftList
export def "addon-pvt-giftlist-get list-gift" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<IsPublic: bool, address: string, dateCreated: string, eventCity: string, eventDate: string, eventLocation: string, eventState: string, fileId: int, fileUrl: string, giftCardId: int, giftCardRechargeSkuId: int, giftListId: int, giftListMembers: table<clientId: string, giftListId: int, giftListMemberId: int, isActive: bool, isAdmin: bool, name: string, surname: string, text1: string, text2: string, title: string, userId: string>, giftListSkuIds: list<string>, giftListTypeId: int, giftListTypeName: string, isActive: bool, isAddressOk: bool, memberNames: string, message: string, name: string, profileSystemUserAddressName: string, profileSystemUserId: string, shipsToOwner: bool, telemarketingId: int, telemarketingObservation: string, urlFolder: string, userId: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/api/addon/pvt/giftlist/get/{list_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product Review Rate by Product ID
#
# GET /api/addon/pvt/review/GetProductRate/{productId}
# operationId: ReviewRateProduct
export def "addon-pvt-review-get-product-rate get" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/addon/pvt/review/GetProductRate/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create attachment
#
# POST /api/catalog/pvt/attachment
# --Domains item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
export def "catalog-pvt-attachment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  domains: list # List of characteristics related to the attachment. — item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
  --is-active: oneof<nothing, bool> # Defines if the attachment is active or not. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the attachment is required or not. (e.g. false)
  name: string # Attachment Name. (e.g. Shirt customization)
]: any -> record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/attachment")
  let req_body = {"Domains": $domains, "IsActive": $is_active, "IsRequired": $is_required, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete attachment
#
# DELETE /api/catalog/pvt/attachment/{attachmentid}
export def "catalog-pvt-attachment delete" [
  attachmentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attachmentid: (encode-path-segment $attachmentid)} | format pattern "/api/catalog/pvt/attachment/{attachmentid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get attachment
#
# GET /api/catalog/pvt/attachment/{attachmentid}
export def "catalog-pvt-attachment get" [
  attachmentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attachmentid: (encode-path-segment $attachmentid)} | format pattern "/api/catalog/pvt/attachment/{attachmentid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update attachment
#
# PUT /api/catalog/pvt/attachment/{attachmentid}
# --Domains item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
export def "catalog-pvt-attachment update" [
  attachmentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  domains: list # List of characteristics related to the attachment. — item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
  --is-active: oneof<nothing, bool> # Defines if the attachment is active or not. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the attachment is required or not. (e.g. false)
  name: string # Attachment Name. (e.g. Shirt customization)
]: any -> record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({attachmentid: (encode-path-segment $attachmentid)} | format pattern "/api/catalog/pvt/attachment/{attachmentid}"))
  let req_body = {"Domains": $domains, "IsActive": $is_active, "IsRequired": $is_required, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get all attachments
#
# GET /api/catalog/pvt/attachments
export def "catalog-pvt-attachments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Data: table<Domains: list, Id: int, IsActive: bool, IsRequired: bool, Name: string>, Page: int, Size: int, TotalPage: int, TotalRows: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/attachments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Brand
#
# POST /api/catalog/pvt/brand
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
export def "catalog-pvt-brand create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --active: oneof<nothing, bool> # Defines if the brand is active (`true`) or not (`false`). (e.g. true)
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  id: int # Brand's unique numerical identifier. (e.g. 2000003)
  --keywords: string # Store Framework - Deprecated. Legacy CMS Portal - Alternative search terms that will lead to the specific brand. The user can find the desired brand even when misspelling it. Used especially when words are of foreign origin and have a distinct spelling that is transcribed into a generic one, or when small spelling mistakes occur. (e.g. adidas)
  --link-id: string # Brand page slug. Only lowercase letters and hyphens (`-`) are allowed. (nullable, e.g. adidas-sports)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --menu-home: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - Defines if the Brand appears in the Department Menu control (`<vtex.cmc:departmentNavigator/>`). (e.g. true)
  name: string # Brand name. (e.g. Adidas)
  --score: int # Store Framework - Deprecated Legacy CMS Portal - Value used to set the priority on the search result page. (nullable, e.g. 10)
  --site-title: string # Meta Title for the Brand page. (e.g. Adidas)
  --text: string # Meta Description for the Brand page. A brief description of the brand, displayed by search engines. Since search engines can only display less than 150 characters, we recommend not exceeding this character limit when creating the description. (e.g. Adidas)
]: any -> record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/brand")
  let req_body = {"Active": $active, "AdWordsRemarketingCode": $ad_words_remarketing_code, "Id": $id, "Keywords": $keywords, "LinkId": $link_id, "LomadeeCampaignCode": $lomadee_campaign_code, "MenuHome": $menu_home, "Name": $name, "Score": $score, "SiteTitle": $site_title, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete Brand
#
# DELETE /api/catalog/pvt/brand/{brandId}
export def "catalog-pvt-brand delete" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog/pvt/brand/{brand_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Brand and context
#
# GET /api/catalog/pvt/brand/{brandId}
export def "catalog-pvt-brand get" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog/pvt/brand/{brand_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Brand
#
# PUT /api/catalog/pvt/brand/{brandId}
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
export def "catalog-pvt-brand update" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --active: oneof<nothing, bool> # Defines if the brand is active (`true`) or not (`false`). (e.g. true)
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  id: int # Brand's unique numerical identifier. (e.g. 2000003)
  --keywords: string # Store Framework - Deprecated. Legacy CMS Portal - Alternative search terms that will lead to the specific brand. The user can find the desired brand even when misspelling it. Used especially when words are of foreign origin and have a distinct spelling that is transcribed into a generic one, or when small spelling mistakes occur. (e.g. adidas)
  --link-id: string # Brand page slug. Only lowercase letters and hyphens (`-`) are allowed. (nullable, e.g. adidas-sports)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --menu-home: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - Defines if the Brand appears in the Department Menu control (`<vtex.cmc:departmentNavigator/>`). (e.g. true)
  name: string # Brand name. (e.g. Adidas)
  --score: int # Store Framework - Deprecated Legacy CMS Portal - Value used to set the priority on the search result page. (nullable, e.g. 10)
  --site-title: string # Meta Title for the Brand page. (e.g. Adidas)
  --text: string # Meta Description for the Brand page. A brief description of the brand, displayed by search engines. Since search engines can only display less than 150 characters, we recommend not exceeding this character limit when creating the description. (e.g. Adidas)
]: any -> record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog/pvt/brand/{brand_id}"))
  let req_body = {"Active": $active, "AdWordsRemarketingCode": $ad_words_remarketing_code, "Id": $id, "Keywords": $keywords, "LinkId": $link_id, "LomadeeCampaignCode": $lomadee_campaign_code, "MenuHome": $menu_home, "Name": $name, "Score": $score, "SiteTitle": $site_title, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create Category
#
# POST /api/catalog/pvt/category
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
export def "catalog-pvt-category create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --active-store-front-link: oneof<nothing, bool> # If true, the Category link becomes active in store. (e.g. true)
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, nullable, e.g. Sale)
  description: string # Text used in meta description tag for Category page. (e.g. Discover our range of home appliances. Find smart vacuums, kitchen and laundry appliances to suit your needs. Order online now.)
  --father-category-id: int # ID of the parent category, apply in case of category and subcategory. (nullable, e.g. 2)
  global_category_id: int # Google Global Category ID. (e.g. 222)
  --id: int # Category unique identifier. If not informed, it will be automatically generated by VTEX. (e.g. 1)
  --is-active: oneof<nothing, bool> # If true, the Category page becomes available in store. (e.g. true)
  keywords: string # Substitute words for the Category. (e.g. Kitchen, Laundry, Appliances)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, nullable, e.g. Sale)
  name: string # Category name. (e.g. Home Appliances)
  --score: int # Score for search sorting order. (nullable, e.g. 3)
  --show-brand-filter: oneof<nothing, bool> # If true, the Category page displays a Brand filter. (e.g. true)
  --show-in-store-front: oneof<nothing, bool> # If true, the Category is shown in the top and side menu. (e.g. true)
  stock_keeping_unit_selection_mode: string # Defines how the SKU will be exhibited (e.g. SPECIFICATION)
  title: string # Text used in title tag for Category page. (e.g. Home Appliances)
]: any -> record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/category")
  let req_body = {"ActiveStoreFrontLink": $active_store_front_link, "AdWordsRemarketingCode": $ad_words_remarketing_code, "Description": $description, "FatherCategoryId": $father_category_id, "GlobalCategoryId": $global_category_id, "Id": $id, "IsActive": $is_active, "Keywords": $keywords, "LomadeeCampaignCode": $lomadee_campaign_code, "Name": $name, "Score": $score, "ShowBrandFilter": $show_brand_filter, "ShowInStoreFront": $show_in_store_front, "StockKeepingUnitSelectionMode": $stock_keeping_unit_selection_mode, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Category by ID
#
# GET /api/catalog/pvt/category/{categoryId}
export def "catalog-pvt-category get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog/pvt/category/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Category
#
# PUT /api/catalog/pvt/category/{categoryId}
export def "catalog-pvt-category update" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --active-store-front-link: oneof<nothing, bool> # If true, the Category link becomes active in store. (e.g. true)
  ad_words_remarketing_code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, e.g. Sale)
  description: string # Text used in meta description tag for Category page. (e.g. Discover our range of home appliances. Find smart vacuums, kitchen and laundry appliances to suit your needs. Order online now.)
  --father-category-id: int # ID of the parent category, apply in case of category and subcategory. (nullable, e.g. 2)
  global_category_id: int # Google Global Category ID. (e.g. 222)
  --is-active: oneof<nothing, bool> # If true, the Category page becomes available in store. (e.g. true)
  keywords: string # Substitute words for the Category. (e.g. Kitchen, Laundry, Appliances)
  lomadee_campaign_code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, e.g. Sale)
  name: string # Category name. (e.g. Home Appliances)
  score: int # Score for search sorting order. (e.g. 3)
  --show-brand-filter: oneof<nothing, bool> # If true, the Category page displays a Brand filter. (e.g. true)
  --show-in-store-front: oneof<nothing, bool> # If true, the Category is shown in the top and side menu. (e.g. true)
  stock_keeping_unit_selection_mode: string # Defines how the SKU will be exhibited (e.g. SPECIFICATION)
  title: string # Text used in title tag for Category page. (e.g. Home Appliances)
]: any -> record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog/pvt/category/{category_id}"))
  let req_body = {"ActiveStoreFrontLink": $active_store_front_link, "AdWordsRemarketingCode": $ad_words_remarketing_code, "Description": $description, "FatherCategoryId": $father_category_id, "GlobalCategoryId": $global_category_id, "IsActive": $is_active, "Keywords": $keywords, "LomadeeCampaignCode": $lomadee_campaign_code, "Name": $name, "Score": $score, "ShowBrandFilter": $show_brand_filter, "ShowInStoreFront": $show_in_store_front, "StockKeepingUnitSelectionMode": $stock_keeping_unit_selection_mode, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create Collection
#
# POST /api/catalog/pvt/collection
export def "catalog-pvt-collection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  date_from: string # Initial value date for the Collection. (e.g. 2017-09-27T10:47:00)
  date_to: string # Final value date for the Collection. (e.g. 2017-09-27T10:47:00)
  --highlight: oneof<nothing, bool> # Defines if the Collection is highlighted or not. (e.g. false)
  name: string # Collection Name. (e.g. Test)
  --searchable: oneof<nothing, bool> # Defines if the Collection is searchable or not. (e.g. true)
]: any -> record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/collection")
  let req_body = {"DateFrom": $date_from, "DateTo": $date_to, "Highlight": $highlight, "Name": $name, "Searchable": $searchable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create Collection
#
# POST /api/catalog/pvt/collection/
# operationId: POST-CreateCollection
export def "catalog-pvt-collection create-create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  date_from: string # Collection start date and time. If a future date and time are set, the collection will have a scheduled status. (e.g. 2020-11-26T15:23:00)
  date_to: string # Collection end date and time. (e.g. 2069-11-26T15:23:00)
  description: string # Collection's description for internal use, with the collection's details. It will not be used for search engines. (e.g. HomeHalloween)
  --highlight: oneof<nothing, bool> # Option if you want the collection to highlight specific products using a tag. (e.g. false)
  name: string # Collection's Name. (e.g. Halloween costumes)
  --searchable: oneof<nothing, bool> # Option making the collection searchable in the store. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/collection/")
  let req_body = {"DateFrom": $date_from, "DateTo": $date_to, "Description": $description, "Highlight": $highlight, "Name": $name, "Searchable": $searchable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get All Inactive Collections
#
# GET /api/catalog/pvt/collection/inactive
# operationId: GET-AllInactiveCollections
export def "catalog-pvt-collection-inactive get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/collection/inactive")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Import Collection file example
#
# GET /api/catalog/pvt/collection/stockkeepingunit/importfileexample
# operationId: GET-Importfileexample
export def "catalog-pvt-collection-stockkeepingunit-importfileexample get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/collection/stockkeepingunit/importfileexample")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Collection
#
# DELETE /api/catalog/pvt/collection/{collectionId}
export def "catalog-pvt-collection delete" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/catalog/pvt/collection/{collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Collection
#
# GET /api/catalog/pvt/collection/{collectionId}
export def "catalog-pvt-collection get" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/catalog/pvt/collection/{collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Collection
#
# PUT /api/catalog/pvt/collection/{collectionId}
export def "catalog-pvt-collection update" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  date_from: string # Initial value date for the Collection. (e.g. 2017-09-27T10:47:00)
  date_to: string # Final value date for the Collection. (e.g. 2017-09-27T10:47:00)
  --highlight: oneof<nothing, bool> # Defines if the Collection is highlighted or not (e.g. false)
  name: string # Collection Name. (e.g. Test)
  --searchable: oneof<nothing, bool> # Defines if the Collection is searchable or not. (e.g. true)
]: any -> record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/catalog/pvt/collection/{collection_id}"))
  let req_body = {"DateFrom": $date_from, "DateTo": $date_to, "Highlight": $highlight, "Name": $name, "Searchable": $searchable} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Reposition SKU on the Subcollection
#
# POST /api/catalog/pvt/collection/{collectionId}/position
export def "catalog-pvt-collection-position create" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  position: int # SKU position. (e.g. 1)
  sku_id: int # SKU ID. (e.g. 1)
  sub_collection_id: int # Subcollection ID. (e.g. 17)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/catalog/pvt/collection/{collection_id}/position"))
  let req_body = {"position": $position, "skuId": $sku_id, "subCollectionId": $sub_collection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get products from a collection
#
# GET /api/catalog/pvt/collection/{collectionId}/products
# operationId: GET-Productsfromacollection
export def "catalog-pvt-collection-products get-productsfromacollection" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (e.g. 2)
  --page-size: int # Number of the items of the page. (e.g. 15)
  --filter: string # Filter used to refine the Collection's products. (e.g. Pre launch)
  --active: oneof<nothing, bool> # Defines if the status of the product is active or not. (e.g. true)
  --visible: oneof<nothing, bool> # Defines if the product is visible on the store or not. (e.g. true)
  --category-id: int # Product's Category unique identifier. (e.g. 12)
  --brand-id: int # Product's Brand unique identifier. (e.g. 3)
  --supplier-id: int # Product's Supplier unique identifier. (e.g. 1)
  --sales-channel-id: int # Product's Trade Policy unique identifier. (e.g. 1)
  --release-from: string # Product past release date. (e.g. 2069-11-26T15:23:00)
  --release-to: string # Product future release date. (e.g. 2069-11-26T15:23:00)
  --specification-product: string # Product Specification Field Value. You must also fill in `SpecificationFieldId` to use this parameter. (e.g. M)
  --specification-field-id: int # Product Specification Field unique identifier. (e.g. 40)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "Filter" $filter "scalar") (serialize-qp "Active" $active "scalar") (serialize-qp "Visible" $visible "scalar") (serialize-qp "CategoryId" $category_id "scalar") (serialize-qp "BrandId" $brand_id "scalar") (serialize-qp "SupplierId" $supplier_id "scalar") (serialize-qp "SalesChannelId" $sales_channel_id "scalar") (serialize-qp "ReleaseFrom" $release_from "scalar") (serialize-qp "ReleaseTo" $release_to "scalar") (serialize-qp "SpecificationProduct" $specification_product "scalar") (serialize-qp "SpecificationFieldId" $specification_field_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/catalog/pvt/collection/{collection_id}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Remove products from Collection by imported file
#
# POST /api/catalog/pvt/collection/{collectionId}/stockkeepingunit/importexclude
# operationId: POST-Removeproductsbyimportfile
export def "catalog-pvt-collection-stockkeepingunit-importexclude create-removeproductsbyimportfile" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --file: any # XLS file with information about products to be added to a Collection. The file must be an imported template from [Import Collection file example](https://developers.vtex.com/vtex-developer-docs/reference/get-importfileexample) endpoint. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/catalog/pvt/collection/{collection_id}/stockkeepingunit/importexclude"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let effective_ct = ($content_type | default "multipart/form-data")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Add products to Collection by imported file
#
# POST /api/catalog/pvt/collection/{collectionId}/stockkeepingunit/importinsert
# operationId: POST-Addproductsbyimportfile
export def "catalog-pvt-collection-stockkeepingunit-importinsert create-addproductsbyimportfile" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --file: any # XLS file with information about products to be added to a Collection. The file must be an imported template from [Import Collection file example](https://developers.vtex.com/vtex-developer-docs/reference/get-importfileexample) endpoint. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/catalog/pvt/collection/{collection_id}/stockkeepingunit/importinsert"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  let effective_ct = ($content_type | default "multipart/form-data")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Get Subcollection by Collection ID
#
# GET /api/catalog/pvt/collection/{collectionId}/subcollection
export def "catalog-pvt-collection-subcollection get" [
  collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/catalog/pvt/collection/{collection_id}/subcollection"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Product with Category and Brand
#
# POST /api/catalog/pvt/product
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
@deprecated --flag supplier-id
export def "catalog-pvt-product create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --brand-id: int # ID of an existing Brand that will be associated with this product. It is mandatory to use either this field or the `BrandName` field. (e.g. 12121219)
  --brand-name: string # Name of the brand that will be associated with this product. It is mandatory to use either this field or the `BrandId` field. If you wish to create a new brand, that is, in case the brand does not exist yet, use this field instead of `BrandId`. (e.g. Sample Brand)
  --category-id: int # ID of an existing Category that will be associated with this product. It is mandatory to use either this field or the `CategoryPath` field. (e.g. 2000090)
  --category-path: string # Path of categories associated with this product, from the highest level of category to the lowest level, separated by `/`. It is mandatory to use either this field or the `CategoryId` field. (e.g. Mens/Clothing/T-Shirts)
  --description: string # Product description. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  --description-short: string # Short product description. This information can be displayed on both the product page and the shelf, using the following controls: Store Framework: `$product.DescriptionShort`. Legacy CMS Portal: `<vtex.cmc:productDescriptionShort/>`. (e.g. The Nike Zoom Stefan Janoski is made with a premium leather.)
  --id: int # Product’s unique numerical identifier. If not informed, it will be automatically generated by VTEX. (e.g. 42)
  --is-active: oneof<nothing, bool> # Activate (`true`) or inactivate (`false`) product. (e.g. true)
  --is-visible: oneof<nothing, bool> # Shows (`true`) or hides (`false`) the product in search result and product pages, but the product can still be added to the shopping cart. Usually applicable for gifts. (e.g. true)
  --key-words: string # Store Framework: Deprecated. Legacy CMS Portal: Keywords or synonyms related to the product, separated by comma (`,`). "Television", for example, can have a substitute word like "TV". This field is important to make your searches more comprehensive. (e.g. Zoom,Stefan,Janoski)
  --link-id: string # Slug that will be used to build the product page URL. If it not informed, it will be generated according to the product's name replacing spaces and special characters by hyphens (`-`). (e.g. stefan-janoski-canvas-varsity-red)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --meta-tag-description: string # Brief description of the product for SEO. It is recommended not to exceed 150 characters. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  name: string # Product's name. Limited to 150 characters. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
  --ref-id: string # Product Reference Code. (e.g. sr_1_90)
  --release-date: string # Used to assist in the ordering of the search result of the site. Using the `O=OrderByReleaseDateDESC` query string, you can pull this value and show the display order by release date. This attribute is also used as a condition for dynamic collections. (e.g. 2019-01-01T00:00:00)
  --score: int # Value used to set the priority on the search result page. (e.g. 1)
  --show-without-stock: oneof<nothing, bool> # If `true`, activates the [Notify Me](https://help.vtex.com/en/tutorial/setting-up-the-notify-me-option--2VqVifQuf6Co2KG048Yu6e) option when the product is out of stock. (e.g. true)
  --supplier-id: int # DEPRECATED, nullable
  --tax-code: string # Product tax code, used for tax calculation. (e.g. 12345)
  --title: string # Product's Title tag. Limited to 150 characters. It is presented in the browser tab and corresponds to the title of the product page. This field is important for SEO. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
]: any -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/product")
  let req_body = {"AdWordsRemarketingCode": $ad_words_remarketing_code, "BrandId": $brand_id, "BrandName": $brand_name, "CategoryId": $category_id, "CategoryPath": $category_path, "Description": $description, "DescriptionShort": $description_short, "Id": $id, "IsActive": $is_active, "IsVisible": $is_visible, "KeyWords": $key_words, "LinkId": $link_id, "LomadeeCampaignCode": $lomadee_campaign_code, "MetaTagDescription": $meta_tag_description, "Name": $name, "RefId": $ref_id, "ReleaseDate": $release_date, "Score": $score, "ShowWithoutStock": $show_without_stock, "SupplierId": $supplier_id, "TaxCode": $tax_code, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Product by ID
#
# GET /api/catalog/pvt/product/{productId}
# operationId: GetProductbyid
export def "catalog-pvt-product get-productbyid" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog/pvt/product/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Product
#
# PUT /api/catalog/pvt/product/{productId}
@deprecated --flag ad-words-remarketing-code
@deprecated --flag lomadee-campaign-code
@deprecated --flag supplier-id
export def "catalog-pvt-product update" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --ad-words-remarketing-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  brand_id: int # Brand ID associated with this product. (e.g. 12121219)
  category_id: int # Category ID associated with this product. (e.g. 2000090)
  --department-id: int # Department ID according to the product's category. (e.g. 2000089)
  --description: string # Product description. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  --description-short: string # Short product description. This information can be displayed on both the product page and the shelf, using the following controls: Store Framework: `$product.DescriptionShort`. Legacy CMS Portal: `<vtex.cmc:productDescriptionShort/>`. (e.g. The Nike Zoom Stefan Janoski is made with a premium leather.)
  --is-active: oneof<nothing, bool> # Activate (`true`) or inactivate (`false`) product. (e.g. true)
  --is-visible: oneof<nothing, bool> # Shows (`true`) or hides (`false`) the product in search result and product pages, but the product can still be added to the shopping cart. Usually applicable for gifts. (e.g. true)
  --key-words: string # Store Framework: Deprecated. Legacy CMS Portal: Keywords or synonyms related to the product, separated by comma (`,`). "Television", for example, can have a substitute word like "TV". This field is important to make your searches more comprehensive. (e.g. Zoom,Stefan,Janoski)
  --link-id: string # Slug that will be used to build the product page URL. If it not informed, it will be generated according to the product's name replacing spaces and special characters by hyphens (`-`). (e.g. stefan-janoski-canvas-varsity-red)
  --lomadee-campaign-code: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --meta-tag-description: string # Brief description of the product for SEO. It is recommended not to exceed 150 characters. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  name: string # Product's name. Limited to 150 characters. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
  --ref-id: string # Product Reference Code. (e.g. sr_1_90)
  --release-date: string # Used to assist in the ordering of the search result of the site. Using the `O=OrderByReleaseDateDESC` query string, you can pull this value and show the display order by release date. This attribute is also used as a condition for dynamic collections. (e.g. 2019-01-01T00:00:00)
  --score: int # Value used to set the priority on the search result page. (e.g. 1)
  --show-without-stock: oneof<nothing, bool> # If `true`, activates the [Notify Me](https://help.vtex.com/en/tutorial/setting-up-the-notify-me-option--2VqVifQuf6Co2KG048Yu6e) option when the product is out of stock. (e.g. true)
  --supplier-id: int # DEPRECATED, nullable
  --tax-code: string # Product tax code, used for tax calculation. (e.g. 12345)
  --title: string # Product's Title tag. Limited to 150 characters. It is presented in the browser tab and corresponds to the title of the product page. This field is important for SEO. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
]: any -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog/pvt/product/{product_id}"))
  let req_body = {"AdWordsRemarketingCode": $ad_words_remarketing_code, "BrandId": $brand_id, "CategoryId": $category_id, "DepartmentId": $department_id, "Description": $description, "DescriptionShort": $description_short, "IsActive": $is_active, "IsVisible": $is_visible, "KeyWords": $key_words, "LinkId": $link_id, "LomadeeCampaignCode": $lomadee_campaign_code, "MetaTagDescription": $meta_tag_description, "Name": $name, "RefId": $ref_id, "ReleaseDate": $release_date, "Score": $score, "ShowWithoutStock": $show_without_stock, "SupplierId": $supplier_id, "TaxCode": $tax_code, "Title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Trade Policies by Product ID
#
# GET /api/catalog/pvt/product/{productId}/salespolicy
export def "catalog-pvt-product-salespolicy get" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ProductId: int, StoreId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog/pvt/product/{product_id}/salespolicy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Remove Product from Trade Policy
#
# DELETE /api/catalog/pvt/product/{productId}/salespolicy/{tradepolicyId}
export def "catalog-pvt-product-salespolicy delete" [
  product_id: int
  tradepolicy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), tradepolicy_id: (encode-path-segment $tradepolicy_id)} | format pattern "/api/catalog/pvt/product/{product_id}/salespolicy/{tradepolicy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate Product with Trade Policy
#
# POST /api/catalog/pvt/product/{productId}/salespolicy/{tradepolicyId}
export def "catalog-pvt-product-salespolicy create" [
  product_id: int
  tradepolicy_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), tradepolicy_id: (encode-path-segment $tradepolicy_id)} | format pattern "/api/catalog/pvt/product/{product_id}/salespolicy/{tradepolicy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Similar Categories
#
# GET /api/catalog/pvt/product/{productId}/similarcategory/
export def "catalog-pvt-product-similarcategory get" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CategoryId: int, ProductId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog/pvt/product/{product_id}/similarcategory/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Similar Category
#
# DELETE /api/catalog/pvt/product/{productId}/similarcategory/{categoryId}
export def "catalog-pvt-product-similarcategory delete" [
  product_id: int
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog/pvt/product/{product_id}/similarcategory/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add Similar Category
#
# POST /api/catalog/pvt/product/{productId}/similarcategory/{categoryId}
export def "catalog-pvt-product-similarcategory create" [
  product_id: int
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ProductId: int, StoreId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog/pvt/product/{product_id}/similarcategory/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete all Product Specifications by Product ID
#
# DELETE /api/catalog/pvt/product/{productId}/specification
# operationId: DeleteAllProductSpecifications
export def "catalog-pvt-product-specification delete-list" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog/pvt/product/{product_id}/specification"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product Specification and its information by Product ID
#
# GET /api/catalog/pvt/product/{productId}/specification
# operationId: GetProductSpecificationbyProductID
export def "catalog-pvt-product-specification get-specificationby" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog/pvt/product/{product_id}/specification"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate Product Specification
#
# POST /api/catalog/pvt/product/{productId}/specification
export def "catalog-pvt-product-specification create" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  field_id: int # Specification ID. (e.g. 19)
  --field-value-id: int # Specification Value ID. Mandatory for `FieldTypeId` `5`, `6` and `7`. Must not be used for any other field types (e.g. 12)
  --text: string # Value of specification. Only for `FieldTypeId` different from `5`, `6` and `7`. (e.g. Metal)
]: any -> record<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog/pvt/product/{product_id}/specification"))
  let req_body = {"FieldId": $field_id, "FieldValueId": $field_value_id, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete a specific Product Specification
#
# DELETE /api/catalog/pvt/product/{productId}/specification/{specificationId}
# operationId: DeleteaProductSpecification
export def "catalog-pvt-product-specification delete-deletea" [
  product_id: int
  specification_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id), specification_id: (encode-path-segment $specification_id)} | format pattern "/api/catalog/pvt/product/{product_id}/specification/{specification_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate product specification using specification name and group name
#
# PUT /api/catalog/pvt/product/{productId}/specificationvalue
export def "catalog-pvt-product-specificationvalue update" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  field_name: string # Specification name. (e.g. Material)
  field_values: list<string> # Array of specification values. (e.g. [Cotton, Polyester])
  group_name: string # Group name. (e.g. Composition)
  --root-level-specification: oneof<nothing, bool> # Root level specification. (e.g. true)
]: any -> table<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog/pvt/product/{product_id}/specificationvalue"))
  let req_body = {"FieldName": $field_name, "FieldValues": $field_values, "GroupName": $group_name, "RootLevelSpecification": $root_level_specification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Dissociate attachments and SKUs
#
# DELETE /api/catalog/pvt/skuattachment
export def "catalog-pvt-skuattachment delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU ID. By using this query param, you can dissociate all the attachments from an SKU based on its SKU ID. (format: int32, e.g. 1)
  --attachment-id: int # Attachment ID. By using this query param, you can dissociate the given attachment from all previously associated SKUs. (format: int32, e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $sku_id "scalar") (serialize-qp "attachmentId" $attachment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/skuattachment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate SKU Attachment
#
# POST /api/catalog/pvt/skuattachment
export def "catalog-pvt-skuattachment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  attachment_id: int # Attachment ID. (e.g. 1)
  sku_id: int # Unique identifier of an SKU. (e.g. 1)
]: any -> record<AttachmentId: int, Id: int, SkuId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuattachment")
  let req_body = {"AttachmentId": $attachment_id, "SkuId": $sku_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU Attachment by Attachment Association ID
#
# DELETE /api/catalog/pvt/skuattachment/{skuAttachmentAssociationId}
export def "catalog-pvt-skuattachment delete-by-skuAttachmentAssociationId" [
  sku_attachment_association_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_attachment_association_id: (encode-path-segment $sku_attachment_association_id)} | format pattern "/api/catalog/pvt/skuattachment/{sku_attachment_association_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create SKU Complement
#
# POST /api/catalog/pvt/skucomplement
# operationId: CreateSKUComplement
export def "catalog-pvt-skucomplement create-sku-complement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  complement_type_id: int # Complement Type ID. This represents the type of the complement. The possible values are: `1` for Accessory; `2` for Suggestion; `3` for Similar Product; `5` for Show Together. (e.g. 1)
  parent_sku_id: int # ID of the Parent SKU, where the Complement is inserted. (e.g. 1)
  sku_id: int # ID of the SKU which will be inserted as a Complement in the Parent SKU. (e.g. 1)
]: any -> table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skucomplement")
  let req_body = {"ComplementTypeId": $complement_type_id, "ParentSkuId": $parent_sku_id, "SkuId": $sku_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU Complement by SKU Complement ID
#
# DELETE /api/catalog/pvt/skucomplement/{skuComplementId}
# operationId: DeleteSKUComplementbySKUComplementID
export def "catalog-pvt-skucomplement delete-sku-complementby-sku-complement" [
  sku_complement_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_complement_id: (encode-path-segment $sku_complement_id)} | format pattern "/api/catalog/pvt/skucomplement/{sku_complement_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Complement by SKU Complement ID
#
# GET /api/catalog/pvt/skucomplement/{skuComplementId}
# operationId: GetSKUComplementbySKUComplementID
export def "catalog-pvt-skucomplement get-sku-complementby-sku-complement" [
  sku_complement_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_complement_id: (encode-path-segment $sku_complement_id)} | format pattern "/api/catalog/pvt/skucomplement/{sku_complement_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate SKU Service
#
# POST /api/catalog/pvt/skuservice
export def "catalog-pvt-skuservice create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --is-active: oneof<nothing, bool> # Defines if the SKU Service is active or not. (e.g. true)
  name: string # SKU Service Name. Maximum of 50 characters. (e.g. Engraving)
  sku_id: int # SKU ID. (e.g. 1)
  sku_service_type_id: int # SKU Service Type ID. (e.g. 1)
  sku_service_value_id: int # SKU Service Value ID. (e.g. 1)
  text: string # Internal description of the SKU Service. Maximum of 100 characters. (e.g. Name engraving additional service.)
]: any -> record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuservice")
  let req_body = {"IsActive": $is_active, "Name": $name, "SkuId": $sku_id, "SkuServiceTypeId": $sku_service_type_id, "SkuServiceValueId": $sku_service_value_id, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Dissociate SKU Service
#
# DELETE /api/catalog/pvt/skuservice/{skuServiceId}
export def "catalog-pvt-skuservice delete" [
  sku_service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_id: (encode-path-segment $sku_service_id)} | format pattern "/api/catalog/pvt/skuservice/{sku_service_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Service
#
# GET /api/catalog/pvt/skuservice/{skuServiceId}
export def "catalog-pvt-skuservice get" [
  sku_service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_id: (encode-path-segment $sku_service_id)} | format pattern "/api/catalog/pvt/skuservice/{sku_service_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update SKU Service
#
# PUT /api/catalog/pvt/skuservice/{skuServiceId}
export def "catalog-pvt-skuservice update" [
  sku_service_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --is-active: oneof<nothing, bool> # Defines if the SKU Service is active or not. (e.g. true)
  name: string # SKU Service Name. Maximum of 50 characters. (e.g. Test name)
  sku_id: int # SKU ID. (e.g. 1)
  sku_service_type_id: int # SKU Service Type ID. (e.g. 2)
  sku_service_value_id: int # SKU Service Value ID. (e.g. 1)
  text: string # Internal description for the SKU Service. Maximum of 100 characters. (e.g. Text)
]: any -> record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_id: (encode-path-segment $sku_service_id)} | format pattern "/api/catalog/pvt/skuservice/{sku_service_id}"))
  let req_body = {"IsActive": $is_active, "Name": $name, "SkuId": $sku_id, "SkuServiceTypeId": $sku_service_type_id, "SkuServiceValueId": $sku_service_value_id, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create SKU Service Type
#
# POST /api/catalog/pvt/skuservicetype
@deprecated --flag show-on-product-front
export def "catalog-pvt-skuservicetype create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --is-active: oneof<nothing, bool> # Defines if the SKU Service Type is active or not. (default: true)
  --is-gift-card: oneof<nothing, bool> # Defines if the SKU Service Type is displayed as a Gift Card. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the SKU Service type is mandatory. (e.g. false)
  name: string # SKU Service Type Name. Maximum of 100 characters. (default: Test API Sku Services)
  --show-on-attachment-front: oneof<nothing, bool> # Defines if the SKU Service Type has an attachment. (e.g. false)
  --show-on-cart-front: oneof<nothing, bool> # Defines if the SKU Service Type is displayed on the cart screen. (e.g. false)
  --show-on-file-upload: oneof<nothing, bool> # Defines if the SKU Service Type can be associated with an attachment or not. (e.g. false)
  --show-on-product-front: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
]: any -> record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuservicetype")
  let req_body = {"IsActive": $is_active, "IsGiftCard": $is_gift_card, "IsRequired": $is_required, "Name": $name, "ShowOnAttachmentFront": $show_on_attachment_front, "ShowOnCartFront": $show_on_cart_front, "ShowOnFileUpload": $show_on_file_upload, "ShowOnProductFront": $show_on_product_front} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU Service Type
#
# DELETE /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
export def "catalog-pvt-skuservicetype delete" [
  sku_service_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_type_id: (encode-path-segment $sku_service_type_id)} | format pattern "/api/catalog/pvt/skuservicetype/{sku_service_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Service Type
#
# GET /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
export def "catalog-pvt-skuservicetype get" [
  sku_service_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_type_id: (encode-path-segment $sku_service_type_id)} | format pattern "/api/catalog/pvt/skuservicetype/{sku_service_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update SKU Service Type
#
# PUT /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
@deprecated --flag show-on-product-front
export def "catalog-pvt-skuservicetype update" [
  sku_service_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --is-active: oneof<nothing, bool> # Defines if the SKU Service Type is active or not. (default: true)
  --is-gift-card: oneof<nothing, bool> # Defines if the SKU Service Type is displayed as a Gift Card. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the SKU Service type is mandatory. (e.g. false)
  name: string # SKU Service Type Name. Maximum of 100 characters. (default: Test API Sku Services)
  --show-on-attachment-front: oneof<nothing, bool> # Defines if the SKU Service Type has an attachment. (e.g. false)
  --show-on-cart-front: oneof<nothing, bool> # Defines if the SKU Service Type is displayed on the cart screen. (e.g. false)
  --show-on-file-upload: oneof<nothing, bool> # Defines if the SKU Service Type can be associated with an attachment or not. (e.g. false)
  --show-on-product-front: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
]: any -> record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_type_id: (encode-path-segment $sku_service_type_id)} | format pattern "/api/catalog/pvt/skuservicetype/{sku_service_type_id}"))
  let req_body = {"IsActive": $is_active, "IsGiftCard": $is_gift_card, "IsRequired": $is_required, "Name": $name, "ShowOnAttachmentFront": $show_on_attachment_front, "ShowOnCartFront": $show_on_cart_front, "ShowOnFileUpload": $show_on_file_upload, "ShowOnProductFront": $show_on_product_front} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Dissociate Attachment by Attachment ID or SKU Service Type ID
#
# DELETE /api/catalog/pvt/skuservicetypeattachment
export def "catalog-pvt-skuservicetypeattachment delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment-id: int # SKU Service Attachment unique identifier. (e.g. 1)
  --sku-service-type-id: int # SKU Service Type unique identifier. (e.g. 1)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachmentId" $attachment_id "scalar") (serialize-qp "skuServiceTypeId" $sku_service_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/skuservicetypeattachment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate SKU Service Attachment
#
# POST /api/catalog/pvt/skuservicetypeattachment
export def "catalog-pvt-skuservicetypeattachment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  attachment_id: int # Attachment ID. (e.g. 1)
  sku_service_type_id: int # An explanation about the purpose of this instance. (e.g. 1)
]: any -> record<AttachmentId: int, Id: int, SkuServiceTypeId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuservicetypeattachment")
  let req_body = {"AttachmentId": $attachment_id, "SkuServiceTypeId": $sku_service_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Dissociate Attachment from SKU Service Type
#
# DELETE /api/catalog/pvt/skuservicetypeattachment/{skuServiceTypeAttachmentId}
export def "catalog-pvt-skuservicetypeattachment delete-by-skuServiceTypeAttachmentId" [
  sku_service_type_attachment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_type_attachment_id: (encode-path-segment $sku_service_type_attachment_id)} | format pattern "/api/catalog/pvt/skuservicetypeattachment/{sku_service_type_attachment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create SKU Service Value
#
# POST /api/catalog/pvt/skuservicevalue
export def "catalog-pvt-skuservicevalue create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  cost: float # SKU Service Value cost. (e.g. 10.5)
  name: string # SKU Service Value name. Maximum of 100 characters. (e.g. Test ServiceValue API)
  sku_service_type_id: int # SKU Service Type ID. (e.g. 2)
  value: float # SKU Service Value value. (e.g. 10.5)
]: any -> record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuservicevalue")
  let req_body = {"Cost": $cost, "Name": $name, "SkuServiceTypeId": $sku_service_type_id, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU Service Value
#
# DELETE /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
export def "catalog-pvt-skuservicevalue delete" [
  sku_service_value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_value_id: (encode-path-segment $sku_service_value_id)} | format pattern "/api/catalog/pvt/skuservicevalue/{sku_service_value_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Service Value
#
# GET /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
export def "catalog-pvt-skuservicevalue get" [
  sku_service_value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_value_id: (encode-path-segment $sku_service_value_id)} | format pattern "/api/catalog/pvt/skuservicevalue/{sku_service_value_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update SKU Service Value
#
# PUT /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
export def "catalog-pvt-skuservicevalue update" [
  sku_service_value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  cost: float # SKU Service Value cost. (e.g. 10.5)
  name: string # SKU Service Value name. Maximum of 100 characters. (e.g. Test ServiceValue API)
  sku_service_type_id: int # SKU Service Type ID. (e.g. 2)
  value: float # SKU Service Value value. (e.g. 10.5)
]: any -> record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_service_value_id: (encode-path-segment $sku_service_value_id)} | format pattern "/api/catalog/pvt/skuservicevalue/{sku_service_value_id}"))
  let req_body = {"Cost": $cost, "Name": $name, "SkuServiceTypeId": $sku_service_type_id, "Value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create Specification
#
# POST /api/catalog/pvt/specification
@deprecated --flag description
@deprecated --flag is-wizard
export def "catalog-pvt-specification create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --category-id: int # Category ID associated with this specification. (e.g. 1)
  --default-value: string # Specification default value. (e.g. Cotton)
  --description: string # DEPRECATED, nullable, e.g. Composition of the product.
  field_group_id: int # ID of the group of specifications that contains the new specification. (e.g. 22)
  field_type_id: int # Field Type ID can be `1 - Text`, `2 - Multi-Line Text`, `4 - Number`, `5 - Combo`, `6 - Radio`, `7 - Checkbox`, `8 - Indexed Text`, `9 - Indexed Multi-Line Text`. (e.g. 1)
  --is-active: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification. (e.g. true)
  --is-filter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar. (e.g. false)
  --is-on-product-details: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page. (e.g. true)
  --is-required: oneof<nothing, bool> # Makes the specification mandatory (`true`) or optional (`false`). (e.g. false)
  --is-side-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar. (e.g. false)
  --is-stock-keeping-unit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification. If `false`, it will be added as a product specification field. (e.g. false)
  --is-top-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu. (e.g. false)
  --is-wizard: oneof<nothing, bool> # DEPRECATED, nullable
  name: string # Specification name. (e.g. Material)
  --position: int # Store Framework - Deprecated. Legacy CMS Portal - This position number is used in ordering the specifications both in the navigation menu and in the specification listing on the product page. (e.g. 1)
]: any -> record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/specification")
  let req_body = {"CategoryId": $category_id, "DefaultValue": $default_value, "Description": $description, "FieldGroupId": $field_group_id, "FieldTypeId": $field_type_id, "IsActive": $is_active, "IsFilter": $is_filter, "IsOnProductDetails": $is_on_product_details, "IsRequired": $is_required, "IsSideMenuLinkActive": $is_side_menu_link_active, "IsStockKeepingUnit": $is_stock_keeping_unit, "IsTopMenuLinkActive": $is_top_menu_link_active, "IsWizard": $is_wizard, "Name": $name, "Position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete Non Structured Specification by SKU ID
#
# DELETE /api/catalog/pvt/specification/nonstructured
export def "catalog-pvt-specification-nonstructured delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU’s unique numerical identifier. (e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $sku_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/specification/nonstructured" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Non Structured Specification by SKU ID
#
# GET /api/catalog/pvt/specification/nonstructured
export def "catalog-pvt-specification-nonstructured list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU’s unique numerical identifier. (e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<Id: int, SkuId: int, SpecificationName: string, SpecificationValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $sku_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/specification/nonstructured" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Non Structured Specification
#
# DELETE /api/catalog/pvt/specification/nonstructured/{Id}
export def "catalog-pvt-specification-nonstructured delete-by-Id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/catalog/pvt/specification/nonstructured/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Non Structured Specification by ID
#
# GET /api/catalog/pvt/specification/nonstructured/{Id}
export def "catalog-pvt-specification-nonstructured get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<Id: int, SkuId: int, SpecificationName: string, SpecificationValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/catalog/pvt/specification/nonstructured/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Specification
#
# GET /api/catalog/pvt/specification/{specificationId}
export def "catalog-pvt-specification get" [
  specification_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({specification_id: (encode-path-segment $specification_id)} | format pattern "/api/catalog/pvt/specification/{specification_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Specification
#
# PUT /api/catalog/pvt/specification/{specificationId}
@deprecated --flag is-wizard
export def "catalog-pvt-specification update" [
  specification_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  category_id: int # Specification Category ID. (e.g. 0)
  default_value: string # Specification Default Value. (e.g. Leather)
  description: string # Specification Description. (e.g. Composition of the product.)
  field_group_id: int # Numerical ID of the Group of Specifications that contains the new Specification. (e.g. 0)
  field_type_id: int # Field Type can be `1 - Text`, `2 - Multi-Line Text`, `4 - Number`, `5 - Combo`, `6 - Radio`, `7 - Checkbox`, `8 - Indexed Text`, `9 - Indexed Multi-Line Text`. (e.g. 1)
  --is-active: oneof<nothing, bool> # Defines if the Specification is active or not. (e.g. false)
  --is-filter: oneof<nothing, bool> # Defines if the Specification can be used as a Filter. (e.g. false)
  --is-on-product-details: oneof<nothing, bool> # Defines if the Specification will be shown on the Product screen in the specification area. (e.g. false)
  --is-required: oneof<nothing, bool> # Defines if the Specification is required or not. (e.g. false)
  --is-side-menu-link-active: oneof<nothing, bool> # Defines if the Specification is shown in the side menu. (e.g. false)
  --is-stock-keeping-unit: oneof<nothing, bool> # Defines if the Specification is applied to a specific SKU. (e.g. false)
  --is-top-menu-link-active: oneof<nothing, bool> # Defines if the Specification is shown in the main menu of the site. (e.g. false)
  --is-wizard: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
  name: string # Specification Name. (e.g. Material)
  position: int # The current Specification's position in comparison to the other Specifications. (e.g. 1)
]: any -> record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({specification_id: (encode-path-segment $specification_id)} | format pattern "/api/catalog/pvt/specification/{specification_id}"))
  let req_body = {"CategoryId": $category_id, "DefaultValue": $default_value, "Description": $description, "FieldGroupId": $field_group_id, "FieldTypeId": $field_type_id, "IsActive": $is_active, "IsFilter": $is_filter, "IsOnProductDetails": $is_on_product_details, "IsRequired": $is_required, "IsSideMenuLinkActive": $is_side_menu_link_active, "IsStockKeepingUnit": $is_stock_keeping_unit, "IsTopMenuLinkActive": $is_top_menu_link_active, "IsWizard": $is_wizard, "Name": $name, "Position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create Specification Group
#
# POST /api/catalog/pvt/specificationgroup
# operationId: SpecificationGroupInsert2
export def "catalog-pvt-specificationgroup create-specification-group-insert2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  category_id: int # Category ID. (format: int32)
  name: string # Specification Group Name.
]: any -> record<CategoryId: int, Id: int, Name: string, Position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/specificationgroup")
  let req_body = {"CategoryId": $category_id, "Name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Update Specification Group
#
# PUT /api/catalog/pvt/specificationgroup/{groupId}
export def "catalog-pvt-specificationgroup update" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  category_id: int # Category ID where the Specification Group is contained. (e.g. 1)
  id: int # Specification Group ID. (format: int32, e.g. 24)
  name: string # Specification Group Name. (e.g. Sizes)
  position: int # Specification Group Position. (e.g. 1)
]: any -> record<CategoryId: int, Id: int, Name: string, Position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/api/catalog/pvt/specificationgroup/{group_id}"))
  let req_body = {"CategoryId": $category_id, "Id": $id, "Name": $name, "Position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create Specification Value
#
# POST /api/catalog/pvt/specificationvalue
@deprecated --flag text
export def "catalog-pvt-specificationvalue create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  field_id: int # Specification ID associated with this specification value. (e.g. 193)
  --is-active: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification value. (e.g. true)
  name: string # Specification Value name. (e.g. Metal)
  --position: int # The position of the value to be shown on product registration page (`/admin/Site/Produto.aspx`). (e.g. 1)
  --text: string # Specification Value Text. (DEPRECATED, nullable)
]: any -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/specificationvalue")
  let req_body = {"FieldId": $field_id, "IsActive": $is_active, "Name": $name, "Position": $position, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Specification Value
#
# GET /api/catalog/pvt/specificationvalue/{specificationValueId}
export def "catalog-pvt-specificationvalue get" [
  specification_value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({specification_value_id: (encode-path-segment $specification_value_id)} | format pattern "/api/catalog/pvt/specificationvalue/{specification_value_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Specification Value
#
# PUT /api/catalog/pvt/specificationvalue/{specificationValueId}
@deprecated --flag text
export def "catalog-pvt-specificationvalue update" [
  specification_value_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  field_id: int # Specification ID associated with this specification value. (e.g. 193)
  --is-active: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification value. (e.g. true)
  name: string # Specification Value name. (e.g. Metal)
  --position: int # The position of the value to be shown on product registration page (`/admin/Site/Produto.aspx`). (e.g. 1)
  --text: string # Specification Value Text. (DEPRECATED, nullable)
]: any -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({specification_value_id: (encode-path-segment $specification_value_id)} | format pattern "/api/catalog/pvt/specificationvalue/{specification_value_id}"))
  let req_body = {"FieldId": $field_id, "IsActive": $is_active, "Name": $name, "Position": $position, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get SKU by RefId
#
# GET /api/catalog/pvt/stockkeepingunit
export def "catalog-pvt-stockkeepingunit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ref-id: string # SKU Reference ID. (e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: float, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: string, WeightKg: float, Width: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refId" $ref_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create SKU
#
# POST /api/catalog/pvt/stockkeepingunit
export def "catalog-pvt-stockkeepingunit create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --activate-if-possible: oneof<nothing, bool> # When set to `true`, this attribute will automatically update the SKU as active once associated with an image or an active component. (e.g. true)
  --commercial-condition-id: int # Used to define SKU specific promotions or installment rules. In case of no specific condition, use `1` (default value). This field does not accept `0`. Find out more by reading [Registering a commercial condition](https://help.vtex.com/tutorial/registering-a-commercial-condition--tutorials_445). (e.g. 1)
  --creation-date: string # Date and time of the SKU's creation. (e.g. 2020-01-25T15:51:29.2614605)
  --cubic-weight: float # [Cubic weight](https://help.vtex.com/en/tutorial/understanding-the-cubic-weight-factor--tutorials_128). (e.g. 0.1667)
  --ean: string # EAN code. Required only if `RefId` is not informed, but can be used alongside `RefId` as well. (e.g. 8949461894984)
  --estimated-date-arrival: string # To add the product as pre-sale, enter the product estimated arrival date in [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) format. You must take into consideration both the launch date and the freight calculation for the arrival date. (nullable)
  --height: float # SKU real height. (e.g. 1)
  --id: int # SKU unique identifier. If not informed, it will be automatically generated by VTEX. (e.g. 1)
  --is-active: oneof<nothing, bool> # Shows if the SKU is active (`true`) or not (`false`). (e.g. false)
  --is-kit: oneof<nothing, bool> # Flag to set whether the product SKU is made up of one or more SKUs, thereby becoming a bundle. Must be enabled if you are adding a bundle. Once activated, the flag cannot be reverted. (e.g. false)
  --kit-itens-sell-apart: oneof<nothing, bool> # Defines if Kit components can be sold apart. (e.g. false)
  --length: float # SKU real length. (e.g. 1)
  --manufacturer-code: string # Provided by the manufacturers to identify their product. This field should be filled in if the product has a specific manufacturer’s code. (e.g. 123)
  --measurement-unit: string # Used only in cases when you need to convert the unit of measure for sale. If a product is sold in boxes for example, but customers want to buy per square meter (m²). In common cases, use `'un'`. (e.g. un)
  --modal-type: string # Links an unusual type of SKU to a carrier specialized in delivering it. This field should be filled in with the name of the modal (e.g. "Chemicals" or "Refrigerated products"). To learn more about this feature, read our articles [How the modal works](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125) and [Setting up modal for carriers](https://help.vtex.com/en/tutorial/configure-modal--3jhLqxuPhuiq24UoykCcqy). (nullable)
  name: string # SKU name, meaning the variation of the previously added product. For example: **Product** - _Fridge_, **SKU** - _110V_. (e.g. Size 10)
  packaged_height: float # Height used for shipping calculation. (e.g. 10)
  packaged_length: float # Length used for shipping calculation. (e.g. 10)
  packaged_weight_kg: int # Weight used for shipping calculation, in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 10)
  packaged_width: float # Width used for shipping calculation. (e.g. 10)
  product_id: int # ID of the Product associated with this SKU. (e.g. 42)
  --ref-id: string # Reference code used internally for organizational purposes. Must be unique. Required only if `Ean` is not informed, but can be used alongside `Ean` as well. (e.g. B096QW8Y8Z)
  --reward-value: float # Credit that the customer receives when finalizing an order of one specific SKU unit. By filling this field out with `1`, the customer gets U$ 1 credit on the site. (e.g. 1)
  --unit-multiplier: float # This is the multiple number of SKU. If the Multiplier is 5.0000, the product can be added in multiple quantities of 5, 10, 15, 20, onward. (e.g. 2)
  --videos: list<string> # Videos URLs (e.g. [https://www.youtube.com/])
  --weight-kg: float # Weight of the SKU in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 1)
  --width: float # SKU real width. (e.g. 1)
]: any -> record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, Ean: string, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunit")
  let req_body = {"ActivateIfPossible": $activate_if_possible, "CommercialConditionId": $commercial_condition_id, "CreationDate": $creation_date, "CubicWeight": $cubic_weight, "Ean": $ean, "EstimatedDateArrival": $estimated_date_arrival, "Height": $height, "Id": $id, "IsActive": $is_active, "IsKit": $is_kit, "KitItensSellApart": $kit_itens_sell_apart, "Length": $length, "ManufacturerCode": $manufacturer_code, "MeasurementUnit": $measurement_unit, "ModalType": $modal_type, "Name": $name, "PackagedHeight": $packaged_height, "PackagedLength": $packaged_length, "PackagedWeightKg": $packaged_weight_kg, "PackagedWidth": $packaged_width, "ProductId": $product_id, "RefId": $ref_id, "RewardValue": $reward_value, "UnitMultiplier": $unit_multiplier, "Videos": $videos, "WeightKg": $weight_kg, "Width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Copy Files from an SKU to another SKU
#
# PUT /api/catalog/pvt/stockkeepingunit/copy/{skuIdfrom}/{skuIdto}/file/
export def "catalog-pvt-stockkeepingunit-copy-file update" [
  sku_idfrom: int
  sku_idto: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_idfrom: (encode-path-segment $sku_idfrom), sku_idto: (encode-path-segment $sku_idto)} | format pattern "/api/catalog/pvt/stockkeepingunit/copy/{sku_idfrom}/{sku_idto}/file/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Disassociate SKU File
#
# DELETE /api/catalog/pvt/stockkeepingunit/disassociate/{skuId}/file/{skuFileId}
export def "catalog-pvt-stockkeepingunit-disassociate-file delete" [
  sku_id: int
  sku_file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), sku_file_id: (encode-path-segment $sku_file_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/disassociate/{sku_id}/file/{sku_file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}
# operationId: Sku
export def "catalog-pvt-stockkeepingunit get-sku" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update SKU
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}
export def "catalog-pvt-stockkeepingunit update" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --activate-if-possible: oneof<nothing, bool> # When set to `true`, this attribute will automatically update the SKU as active once associated with an image or an active component. (e.g. false)
  --commercial-condition-id: int # Used to define SKU specific promotions or installment rules. In case of no specific condition, use `1` (default value). This field does not accept `0`. Find out more by reading [Registering a commercial condition](https://help.vtex.com/tutorial/registering-a-commercial-condition--tutorials_445). (e.g. 1)
  --creation-date: string # Date and time of the SKU's creation. (e.g. 2020-01-25T15:51:00)
  --cubic-weight: float # [Cubic weight](https://help.vtex.com/en/tutorial/understanding-the-cubic-weight-factor--tutorials_128). (e.g. 0.1667)
  --estimated-date-arrival: string # To add the product as pre-sale, enter the product estimated arrival date in [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) format. You must take into consideration both the launch date and the freight calculation for the arrival date. (nullable)
  --height: float # SKU real height. (e.g. 1)
  --is-active: oneof<nothing, bool> # Shows if the SKU is active (`true`) or not (`false`). (e.g. false)
  --is-kit: oneof<nothing, bool> # Flag to set whether the product SKU is made up of one or more SKUs, thereby becoming a bundle. Must be enabled if you are adding a bundle. Once activated, the flag cannot be reverted. (e.g. false)
  --kit-itens-sell-apart: oneof<nothing, bool> # Defines if Kit components can be sold apart. (e.g. false)
  --length: float # SKU real length. (e.g. 1)
  --manufacturer-code: string # Provided by the manufacturers to identify their product. This field should be filled in if the product has a specific manufacturer’s code. (e.g. 123)
  --measurement-unit: string # Used only in cases when you need to convert the unit of measure for sale. If a product is sold in boxes for example, but customers want to buy per square meter (m²). In common cases, use `'un'`. (e.g. un)
  --modal-type: string # Links an unusual type of SKU to a carrier specialized in delivering it. This field should be filled in with the name of the modal (e.g. "Chemicals" or "Refrigerated products"). To learn more about this feature, read our articles [How the modal works](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125) and [Setting up modal for carriers](https://help.vtex.com/en/tutorial/configure-modal--3jhLqxuPhuiq24UoykCcqy). (nullable)
  name: string # SKU name, meaning the variation of the previously added product. For example: **Product** - _Fridge_, **SKU** - _110V_. (e.g. Size 10)
  packaged_height: float # Height used for shipping calculation. (e.g. 10)
  packaged_length: float # Length used for shipping calculation. (e.g. 10)
  packaged_weight_kg: int # Weight used for shipping calculation, in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 10)
  packaged_width: float # Width used for shipping calculation. (e.g. 10)
  product_id: int # ID of the Product associated with this SKU. (e.g. 42)
  --ref-id: string # Reference code used internally for organizational purposes. Must be unique. It is not required only if EAN code already exists. If not, this field must be provided. (e.g. B096QW8Y8Z)
  --reward-value: float # Credit that the customer receives when finalizing an order of one specific SKU unit. By filling this field out with `1`, the customer gets U$ 1 credit on the site. (e.g. 1)
  --unit-multiplier: float # This is the multiple number of SKU. If the Multiplier is 5.0000, the product can be added in multiple quantities of 5, 10, 15, 20, onward. (e.g. 2)
  --videos: list<string> # Videos URLs (e.g. [https://www.youtube.com/])
  --weight-kg: float # Weight of the SKU in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 1)
  --width: float # SKU real width. (e.g. 1)
]: any -> record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}"))
  let req_body = {"ActivateIfPossible": $activate_if_possible, "CommercialConditionId": $commercial_condition_id, "CreationDate": $creation_date, "CubicWeight": $cubic_weight, "EstimatedDateArrival": $estimated_date_arrival, "Height": $height, "IsActive": $is_active, "IsKit": $is_kit, "KitItensSellApart": $kit_itens_sell_apart, "Length": $length, "ManufacturerCode": $manufacturer_code, "MeasurementUnit": $measurement_unit, "ModalType": $modal_type, "Name": $name, "PackagedHeight": $packaged_height, "PackagedLength": $packaged_length, "PackagedWeightKg": $packaged_weight_kg, "PackagedWidth": $packaged_width, "ProductId": $product_id, "RefId": $ref_id, "RewardValue": $reward_value, "UnitMultiplier": $unit_multiplier, "Videos": $videos, "WeightKg": $weight_kg, "Width": $width} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get SKU Attachments by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/attachment
export def "catalog-pvt-stockkeepingunit-attachment get" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<AttachmentId: int, Id: int, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/attachment"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Complement by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/complement
# operationId: GetSKUComplementbySKUID
export def "catalog-pvt-stockkeepingunit-complement get-sku-complementby" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/complement"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Complements by Complement Type ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/complement/{complementTypeId}
# operationId: GetSKUComplementsbyComplementTypeID
export def "catalog-pvt-stockkeepingunit-complement get-sku-complementsby-type" [
  sku_id: int
  complement_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), complement_type_id: (encode-path-segment $complement_type_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/complement/{complement_type_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete all SKU EAN values
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/ean
export def "catalog-pvt-stockkeepingunit-ean delete-by-skuId" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/ean"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get EAN by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/ean
export def "catalog-pvt-stockkeepingunit-ean get" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/ean"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete SKU EAN
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/ean/{ean}
export def "catalog-pvt-stockkeepingunit-ean delete-by-skuId-ean" [
  sku_id: int
  ean: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), ean: (encode-path-segment $ean)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/ean/{ean}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create SKU EAN
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/ean/{ean}
export def "catalog-pvt-stockkeepingunit-ean create" [
  sku_id: int
  ean: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), ean: (encode-path-segment $ean)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/ean/{ean}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete All SKU Files
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/file
export def "catalog-pvt-stockkeepingunit-file delete-by-skuId" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/file"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Files
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/file
export def "catalog-pvt-stockkeepingunit-file get" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ArchiveId: int, Id: int, IsMain: bool, Label: string, Name: string, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/file"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create SKU File
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/file
export def "catalog-pvt-stockkeepingunit-file create" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --is-main: oneof<nothing, bool> # Defines if the Image is the main image of the SKU. (e.g. true)
  --label: string # SKU image label. (e.g. Main)
  name: string # SKU image name. (e.g. Nike-Red-Janoski-1)
  --text: string # General text of the image. (nullable, e.g. Nike-Red-Janoski)
  url: string # External Image's URL. The URL must start with the protocol identifier (`http://` or `https://`) and end with the file extension (`.jpg`, `.png` or `.gif`). (e.g. https://m.media-amazon.com/images/I/610G2-sJx5L._AC_UX695_.jpg)
]: any -> record<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/file"))
  let req_body = {"IsMain": $is_main, "Label": $label, "Name": $name, "Text": $text, "Url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU Image File
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/file/{skuFileId}
export def "catalog-pvt-stockkeepingunit-file delete-by-skuId-skuFileId" [
  sku_id: int
  sku_file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), sku_file_id: (encode-path-segment $sku_file_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/file/{sku_file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update SKU File
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/file/{skuFileId}
export def "catalog-pvt-stockkeepingunit-file update" [
  sku_id: int
  sku_file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --is-main: oneof<nothing, bool> # Defines if the Image is the main image of the SKU. (e.g. true)
  --label: string # SKU image label. (e.g. Main)
  name: string # SKU image name. (e.g. Nike-Red-Janoski-1)
  --text: string # General text of the image. (nullable, e.g. Nike-Red-Janoski)
  url: string # External Image's URL. The URL must start with the protocol identifier (`http://` or `https://`) and end with the file extension (`.jpg`, `.png` or `.gif`). (e.g. https://m.media-amazon.com/images/I/610G2-sJx5L._AC_UX695_.jpg)
]: any -> record<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), sku_file_id: (encode-path-segment $sku_file_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/file/{sku_file_id}"))
  let req_body = {"IsMain": $is_main, "Label": $label, "Name": $name, "Text": $text, "Url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete all SKU Specifications
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "catalog-pvt-stockkeepingunit-specification delete-by-skuId" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/specification"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Specifications
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "catalog-pvt-stockkeepingunit-specification get" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/specification"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate SKU Specification
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "catalog-pvt-stockkeepingunit-specification create" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  field_id: int # Specification ID. (e.g. 13)
  --field-value-id: int # Specification Value ID. Required only for `FieldTypeId` as `5`, `6` and `7`. (e.g. 101)
]: any -> record<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/specification"))
  let req_body = {"FieldId": $field_id, "FieldValueId": $field_value_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Update SKU Specification
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "catalog-pvt-stockkeepingunit-specification update" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  field_id: int # Specification unique identifier. This field cannot be updated. (e.g. 32)
  field_value_id: int # Specification value unique identifier. This field can only be updated with other values of the same `FieldId`. (e.g. 131)
  id: int # Specification and SKU association unique identifier. This field cannot be updated. (e.g. 65)
  --body-sku-id: int # SKU unique identifier. This field cannot be updated. (e.g. 21)
  --text: string # Specification Value Name. This field is automatically updated if the `FieldValue` is updated. Otherwise, the value cannot be modified. (e.g. Red)
]: any -> table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/specification"))
  let req_body = {"FieldId": $field_id, "FieldValueId": $field_value_id, "Id": $id, "SkuId": $body_sku_id, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU Specification
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/specification/{specificationId}
export def "catalog-pvt-stockkeepingunit-specification delete-by-skuId-specificationId" [
  sku_id: int
  specification_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id), specification_id: (encode-path-segment $specification_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/specification/{specification_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate SKU specification using specification name and group name
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/specificationvalue
export def "catalog-pvt-stockkeepingunit-specificationvalue update" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  field_name: string # Specification name. (e.g. Material)
  field_values: list<string> # Array of specification values. SKU Specifications must contain only one value. (e.g. [M])
  group_name: string # Group name. (e.g. Composition)
  --root-level-specification: oneof<nothing, bool> # Root level specification. (e.g. true)
]: any -> table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/stockkeepingunit/{sku_id}/specificationvalue"))
  let req_body = {"FieldName": $field_name, "FieldValues": $field_values, "GroupName": $group_name, "RootLevelSpecification": $root_level_specification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU Kit by SKU ID or Parent SKU ID
#
# DELETE /api/catalog/pvt/stockkeepingunitkit
export def "catalog-pvt-stockkeepingunitkit delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --parent-sku-id: int # Parent SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $sku_id "scalar") (serialize-qp "parentSkuId" $parent_sku_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunitkit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Kit by SKU ID or Parent SKU ID
#
# GET /api/catalog/pvt/stockkeepingunitkit
export def "catalog-pvt-stockkeepingunitkit list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku-id: int # SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --parent-sku-id: int # Parent SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $sku_id "scalar") (serialize-qp "parentSkuId" $parent_sku_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunitkit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create SKU Kit
#
# POST /api/catalog/pvt/stockkeepingunitkit
export def "catalog-pvt-stockkeepingunitkit create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  quantity: int # Component quantity. (e.g. 3)
  stock_keeping_unit_id: int # Component SKU ID. (e.g. 31018374)
  stock_keeping_unit_parent: int # SKU ID of the SKU Kit. (e.g. 31018373)
  unit_price: float # Component price per unit. (e.g. 15.5)
]: any -> record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunitkit")
  let req_body = {"Quantity": $quantity, "StockKeepingUnitId": $stock_keeping_unit_id, "StockKeepingUnitParent": $stock_keeping_unit_parent, "UnitPrice": $unit_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU Kit by KitId
#
# DELETE /api/catalog/pvt/stockkeepingunitkit/{kitId}
export def "catalog-pvt-stockkeepingunitkit delete-by-kitId" [
  kit_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({kit_id: (encode-path-segment $kit_id)} | format pattern "/api/catalog/pvt/stockkeepingunitkit/{kit_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU Kit
#
# GET /api/catalog/pvt/stockkeepingunitkit/{kitId}
export def "catalog-pvt-stockkeepingunitkit get" [
  kit_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({kit_id: (encode-path-segment $kit_id)} | format pattern "/api/catalog/pvt/stockkeepingunitkit/{kit_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Subcollection
#
# POST /api/catalog/pvt/subcollection
export def "catalog-pvt-subcollection create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  collection_id: int # SubCollection ID. (e.g. 17)
  name: string # SubCollection Name. (e.g. group 1)
  --pre-sale: oneof<nothing, bool> # Defines PreSale date. (e.g. false)
  --release: oneof<nothing, bool> # Defines Release date. (e.g. false)
  type: string # Either `“Exclusive”` (all the products contained in it will not be used) or `“Inclusive”` (all the products contained in it will be used). (e.g. Inclusive)
]: any -> record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/subcollection")
  let req_body = {"CollectionId": $collection_id, "Name": $name, "PreSale": $pre_sale, "Release": $release, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}
export def "catalog-pvt-subcollection delete" [
  sub_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Subcollection
#
# GET /api/catalog/pvt/subcollection/{subCollectionId}
export def "catalog-pvt-subcollection get" [
  sub_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Subcollection
#
# PUT /api/catalog/pvt/subcollection/{subCollectionId}
export def "catalog-pvt-subcollection update" [
  sub_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  collection_id: int # Collection ID. (e.g. 17)
  name: string # Subcollection Name. (e.g. group 1)
  --pre-sale: oneof<nothing, bool> # Defines PreSale date. (e.g. false)
  --release: oneof<nothing, bool> # Defines Release date. (e.g. false)
  type: string # Either `“Exclusive”` (all the products contained in it will not be used) or `“Inclusive”` (all the products contained in it will be used). (e.g. Inclusive)
]: any -> record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}"))
  let req_body = {"CollectionId": $collection_id, "Name": $name, "PreSale": $pre_sale, "Release": $release, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Associate Brand to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/brand
export def "catalog-pvt-subcollection-brand create" [
  sub_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  brand_id: int # Unique identifier of a Brand. (e.g. 2000000)
]: any -> record<BrandId: int, SubCollectionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}/brand"))
  let req_body = {"BrandId": $brand_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete Brand from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/brand/{brandId}
export def "catalog-pvt-subcollection-brand delete-by-subCollectionId-brandId" [
  sub_collection_id: int
  brand_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id), brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}/brand/{brand_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete Category from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/brand/{categoryId}
export def "catalog-pvt-subcollection-brand delete-by-subCollectionId-categoryId" [
  sub_collection_id: int
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id), category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}/brand/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate Category to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/category
export def "catalog-pvt-subcollection-category create" [
  sub_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  category_id: int # Unique identifier of a Category. (e.g. 0)
]: any -> record<CategoryId: int, SubCollectionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}/category"))
  let req_body = {"CategoryId": $category_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Add SKU to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/stockkeepingunit
export def "catalog-pvt-subcollection-stockkeepingunit create" [
  sub_collection_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  sku_id: int # Unique identifier of an SKU. (e.g. 1)
]: any -> record<SkuId: int, SubCollectionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}/stockkeepingunit"))
  let req_body = {"SkuId": $sku_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete SKU from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/stockkeepingunit/{skuId}
export def "catalog-pvt-subcollection-stockkeepingunit delete" [
  sub_collection_id: int
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sub_collection_id: (encode-path-segment $sub_collection_id), sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog/pvt/subcollection/{sub_collection_id}/stockkeepingunit/{sku_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Supplier
#
# POST /api/catalog/pvt/supplier
export def "catalog-pvt-supplier create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  cell_phone: string # Supplier Cellphone. (e.g. 4444444444)
  cnpj: string # Corporate legal ID. (e.g. 33304981001272)
  corporate_name: string # Supplier Corporate Name. (e.g. TopStore)
  corporte_phone: string # Supplier Corporate Phone. (e.g. 5555555555)
  email: string # Supplier email. (e.g. email@email.com)
  --is-active: oneof<nothing, bool> # Defines if the Supplier is active (`true`) or not (`false`). (e.g. false)
  name: string # Supplier Name. (e.g. Supplier)
  phone: string # Supplier Phone. (e.g. 3333333333)
  state_inscription: string # State Inscription. (e.g. 123456)
]: any -> record<CellPhone: string, Cnpj: string, CorporateName: string, CorportePhone: string, Email: string, Id: int, IsActive: bool, Name: string, Phone: string, StateInscription: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/supplier")
  let req_body = {"CellPhone": $cell_phone, "Cnpj": $cnpj, "CorporateName": $corporate_name, "CorportePhone": $corporte_phone, "Email": $email, "IsActive": $is_active, "Name": $name, "Phone": $phone, "StateInscription": $state_inscription} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Delete Supplier
#
# DELETE /api/catalog/pvt/supplier/{supplierId}
export def "catalog-pvt-supplier delete" [
  supplier_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({supplier_id: (encode-path-segment $supplier_id)} | format pattern "/api/catalog/pvt/supplier/{supplier_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Supplier
#
# PUT /api/catalog/pvt/supplier/{supplierId}
export def "catalog-pvt-supplier update" [
  supplier_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  cell_phone: string # Supplier Cellphone. (e.g. 4444444444)
  cnpj: string # Corporate legal ID. (e.g. 33304981001272)
  corporate_name: string # Supplier Corporate Name. (e.g. TopStore)
  corporte_phone: string # Supplier Corporate Phone. (e.g. 5555555555)
  email: string # Supplier email. (e.g. email@email.com)
  --is-active: oneof<nothing, bool> # Defines if the Supplier is active (`true`) or not (`false`). (e.g. false)
  name: string # Supplier Name. (e.g. Supplier)
  phone: string # Supplier Phone. (e.g. 3333333333)
  state_inscription: string # State Inscription. (e.g. 123456)
]: any -> record<CellPhone: string, Cnpj: string, CorporateName: string, CorportePhone: string, Email: string, Id: int, IsActive: bool, Name: string, Phone: string, StateInscription: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({supplier_id: (encode-path-segment $supplier_id)} | format pattern "/api/catalog/pvt/supplier/{supplier_id}"))
  let req_body = {"CellPhone": $cell_phone, "Cnpj": $cnpj, "CorporateName": $corporate_name, "CorportePhone": $corporte_phone, "Email": $email, "IsActive": $is_active, "Name": $name, "Phone": $phone, "StateInscription": $state_inscription} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Category Tree
#
# GET /api/catalog_system/pub/category/tree/{categoryLevels}
# operationId: CategoryTree
export def "catalog-system-pub-category-tree get" [
  category_levels: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<MetaTagDescription: string, Title: string, children: list<record>, hasChildren: bool, id: int, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_levels: (encode-path-segment $category_levels)} | format pattern "/api/catalog_system/pub/category/tree/{category_levels}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product's SKUs by Product ID
#
# GET /api/catalog_system/pub/products/variations/{productId}
# operationId: ProductVariations
export def "catalog-system-pub-products-variations get" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<available: bool, dimensions: list<string>, dimensionsInputType: record, dimensionsMap: record, displayMode: string, name: string, productId: int, salesChannel: string, skus: table<available: bool, availablequantity: int, bestPrice: int, bestPriceFormated: string, cacheVersionUsedToCallCheckout: string, dimensions: record, image: string, installments: int, installmentsInsterestRate: int, installmentsValue: int, listPrice: int, listPriceFormated: string, measures: record, rewardValue: int, sellerId: string, sku: int, skuname: string, spotPrice: int, taxAsInt: int, taxFormated: string, unitMultiplier: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pub/products/variations/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Sales Channel by ID
#
# GET /api/catalog_system/pub/saleschannel/{salesChannelId}
# operationId: SalesChannelbyId
export def "catalog-system-pub-saleschannel get-sales-channelby" [
  sales_channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ConditionRule: string, CountryCode: string, CultureInfo: string, CurrencyCode: string, CurrencyDecimalDigits: int, CurrencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, CurrencyLocale: int, CurrencySymbol: string, Id: int, IsActive: bool, Name: string, Origin: string, Position: int, ProductClusterId: int, TimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sales_channel_id: (encode-path-segment $sales_channel_id)} | format pattern "/api/catalog_system/pub/saleschannel/{sales_channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Retrieve SKU ID list by Reference ID list
#
# POST /api/catalog_system/pub/sku/stockkeepingunitidsbyrefids
# operationId: SkuIdlistbyRefIdlist
export def "catalog-system-pub-sku-stockkeepingunitidsbyrefids create-idlistby-ref-idlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pub/sku/stockkeepingunitidsbyrefids")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Specifications By Category ID
#
# GET /api/catalog_system/pub/specification/field/listByCategoryId/{categoryId}
# operationId: SpecificationsByCategoryId
export def "catalog-system-pub-specification-field-list-by-category-id get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CategoryId: int, FieldId: int, IsActive: bool, IsStockKeepingUnit: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog_system/pub/specification/field/listByCategoryId/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Specifications Tree By Category ID
#
# GET /api/catalog_system/pub/specification/field/listTreeByCategoryId/{categoryId}
# operationId: SpecificationsTreeByCategoryId
export def "catalog-system-pub-specification-field-list-tree-by-category-id get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CategoryId: int, FieldId: int, IsActive: bool, IsStockKeepingUnit: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog_system/pub/specification/field/listTreeByCategoryId/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Specification Field
#
# GET /api/catalog_system/pub/specification/fieldGet/{fieldId}
# operationId: SpecificationsField
export def "catalog-system-pub-specification-field-get get" [
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<DefaultValue: string, Description: string, FieldGroupId: int, FieldGroupName: string, FieldId: int, FieldTypeId: int, FieldTypeName: string, FieldValueId: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/api/catalog_system/pub/specification/fieldGet/{field_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Specification Values By Field ID
#
# GET /api/catalog_system/pub/specification/fieldvalue/{fieldId}
# operationId: SpecificationsValuesByFieldId
export def "catalog-system-pub-specification-fieldvalue get-values-by-field" [
  field_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<FieldValueId: int, IsActive: bool, Position: int, Value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_id: (encode-path-segment $field_id)} | format pattern "/api/catalog_system/pub/specification/fieldvalue/{field_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Specification Group
#
# GET /api/catalog_system/pub/specification/groupGet/{groupId}
# operationId: SpecificationsGroupGet
export def "catalog-system-pub-specification-group-get get" [
  group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<CategoryId: int, Id: int, Name: string, Position: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/api/catalog_system/pub/specification/groupGet/{group_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Brand List
#
# GET /api/catalog_system/pvt/brand/list
# operationId: BrandList
export def "catalog-system-pvt-brand-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/brand/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Brand List Per Page
#
# GET /api/catalog_system/pvt/brand/pagedlist
# operationId: BrandListPerPage
export def "catalog-system-pvt-brand-pagedlist list-per-page" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # Quantity of brands per page. (e.g. 5)
  --page: int # Page number of the brand list. (e.g. 1)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<items: table<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string>, paging: record<page: int, pages: int, perPage: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/brand/pagedlist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Brand
#
# GET /api/catalog_system/pvt/brand/{brandId}
# operationId: Brand
export def "catalog-system-pvt-brand get" [
  brand_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({brand_id: (encode-path-segment $brand_id)} | format pattern "/api/catalog_system/pvt/brand/{brand_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get All Collections
#
# GET /api/catalog_system/pvt/collection/search
# operationId: GET-AllCollections
export def "catalog-system-pvt-collection-search get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (e.g. 2)
  --page-size: int # Number of the items of the page. (e.g. 15)
  --order-by-asc: oneof<nothing, bool> # Defines if the items of the page are in ascending order. (e.g. true)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "orderByAsc" $order_by_asc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/collection/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Collections by search terms
#
# GET /api/catalog_system/pvt/collection/search/{searchTerms}
# operationId: GET-Collectionsbyseachterms
export def "catalog-system-pvt-collection-search get-collectionsbyseachterms" [
  search_terms: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (e.g. 2)
  --page-size: int # Number of the items of the page. (e.g. 15)
  --order-by-asc: oneof<nothing, bool> # Defines if the items of the page are in ascending order. (e.g. true)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "orderByAsc" $order_by_asc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({search_terms: (encode-path-segment $search_terms)} | format pattern "/api/catalog_system/pvt/collection/search/{search_terms}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all commercial conditions
#
# GET /api/catalog_system/pvt/commercialcondition/list
# operationId: GetAllCommercialConditions
export def "catalog-system-pvt-commercialcondition-list get-list-commercial-conditions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<Id: int, IsDefault: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/commercialcondition/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get commercial condition
#
# GET /api/catalog_system/pvt/commercialcondition/{commercialConditionId}
# operationId: GetCommercialConditions
export def "catalog-system-pvt-commercialcondition get-commercial-conditions" [
  commercial_condition_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, IsDefault: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({commercial_condition_id: (encode-path-segment $commercial_condition_id)} | format pattern "/api/catalog_system/pvt/commercialcondition/{commercial_condition_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product Indexed Information
#
# GET /api/catalog_system/pvt/products/GetIndexedInfo/{productId}
# operationId: IndexedInfo
export def "catalog-system-pvt-products-get-indexed-info get" [
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pvt/products/GetIndexedInfo/{product_id}"))
  let accept_val = "xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product and SKU IDs
#
# GET /api/catalog_system/pvt/products/GetProductAndSkuIds
# operationId: ProductAndSkuIds
export def "catalog-system-pvt-products-get-product-and-sku-ids get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-id: int # ID of the category from which you need to retrieve Products and SKUs. (format: int32, e.g. 1)
  --qp-from: int # Insert the ID that will start the request result. (format: int32, e.g. 1)
  --qp-to: int # Insert the ID that will end the request result. (format: int32, e.g. 10)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<data: record<Product_ID: list<any>>, range: record<from: int, to: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryId" $category_id "scalar") (serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/products/GetProductAndSkuIds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product and its general context
#
# GET /api/catalog_system/pvt/products/productget/{productId}
# operationId: ProductandTradePolicy
export def "catalog-system-pvt-products-productget get-productand-trade-policy" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, ListStoreId: list<any>, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pvt/products/productget/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product by RefId
#
# GET /api/catalog_system/pvt/products/productgetbyrefid/{refId}
# operationId: ProductbyRefId
export def "catalog-system-pvt-products-productgetbyrefid get-productby-ref" [
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, ListStoreId: list<int>, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ref_id: (encode-path-segment $ref_id)} | format pattern "/api/catalog_system/pvt/products/productgetbyrefid/{ref_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Product Specification by Product ID
#
# GET /api/catalog_system/pvt/products/{productId}/specification
# operationId: GetProductSpecification
export def "catalog-system-pvt-products-specification get" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<Id: int, Name: string, Value: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pvt/products/{product_id}/specification"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Product Specification by Product ID
#
# POST /api/catalog_system/pvt/products/{productId}/specification
# operationId: UpdateProductSpecification
export def "catalog-system-pvt-products-specification update" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pvt/products/{product_id}/specification"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Sales Channel List
#
# GET /api/catalog_system/pvt/saleschannel/list
# operationId: SalesChannelList
export def "catalog-system-pvt-saleschannel-list list-sales-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ConditionRule: string, CountryCode: string, CultureInfo: string, CurrencyCode: string, CurrencyDecimalDigits: int, CurrencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, CurrencyLocale: int, CurrencySymbol: string, Id: int, IsActive: bool, Name: string, Origin: string, Position: int, ProductClusterId: int, TimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/saleschannel/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Seller
#
# POST /api/catalog_system/pvt/seller
# operationId: CreateSeller
export def "catalog-system-pvt-seller create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  archive_id: int # Seller archive ID. (e.g. 1)
  cnpj: string # Company registration number. (e.g. 12035072751)
  csc_identification: string # CSC identification. (e.g. pedrostore)
  catalog_system_endpoint: string # URL of the endpoint of the seller's catalog. This field will only be displayed if the seller type is VTEX Store. The field format will be as follows: `http://{sellerName}.vtexcommercestable.com.br/api/catalog_system/`. (e.g. http://pedrostore.vtexcommercestable.com.br/api/catalog_system/)
  --category-commission-percentage: string # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. [{"CategoryId":14,"ProductCommission":15.0,"FreightCommission":0.0}])
  delivery_policy: string # Text describing the delivery policy previously agreed between the marketplace and the seller. (e.g. Delivery policy text)
  description: string # Text describing the seller with a marketing tone. You can display this text in the marketplace window display by [customizing the CMS](https://help.vtex.com/en/tutorial/list-of-controls-for-templates--tutorials_563). (e.g. Brief description)
  email: string # Email of the admin responsible for the seller. (e.g. breno@breno.com)
  exchange_return_policy: string # Text describing the exchange and return policy previously agreed between the marketplace and the seller. (e.g. Exchange return policy text)
  freight_commission_percentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  fulfillment_endpoint: string # URL of the endpoint for fulfillment of seller's orders, which the marketplace will use to communicate with the seller. This field applies to all sellers, regardless of their type. However, for `VTEX Stores`, you don’t need to fill it in because the system will do that automatically. You can edit this field once the seller has been successfully added. (e.g. http://pedrostore.vtexcommercestable.com.br/api/fulfillment?affiliateid=LDB&sc=1)
  fulfillment_seller_id: int # Identification code of the seller responsible for fulfilling the order. This is an optional field used when a seller sells SKUs from another seller. If the seller sells their own SKUs, it must be left blank. (e.g. 1)
  --is-active: oneof<nothing, bool> # If the selle is active (`true`) or not (`false`). (e.g. true)
  --is-better-scope: oneof<nothing, bool> # Indicates whether it is a [comprehensive seller](https://help.vtex.com/en/tutorial/comprehensive-seller--5Qn4O2GpjUIzWTPpvLUfkI). (e.g. false)
  --merchant-name: string # Name of the marketplace, used to guide payments. This field should be nulled if the marketplace is responsible for processing payments. Check out our [Split Payment](https://help.vtex.com/en/tutorial/split-payment--6k5JidhYRUxileNolY2VLx) article to know more. (e.g. pedrostore)
  name: string # Name of the account in the seller's environment. You can find it on **Account settings > Account > Account Name**). Applicable only if the seller uses their own payment method. (e.g. My pedrostore)
  password: string # Seller password. (e.g. passoword)
  product_commission_percentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  secutity_privacy_policy: string # Text describing the security policy previously agreed between the marketplace and the seller. (e.g. Secutity privacy policy text)
  seller_id: string # Code used to identify the seller. It is assigned by the marketplace. We recommend filling it in with the seller's account name. (e.g. pedrostore)
  seller_type: int # Seller type. (e.g. 1)
  --trust-policy: string # Seller trust policy. The default value is `'Default'`, but if your store is a B2B marketplace and you want to share the customers'emails with the sellers you need to set this field as `'AllowEmailSharing'`. (e.g. Default)
  url_logo: string # Seller URL logo. (e.g. /myseller)
  --use-hybrid-payment-options: oneof<nothing, bool> # Allows customers to use gift cards from the seller to buy their products on the marketplace. It identifies purchases made with a gift card so that only the final price (with discounts applied) is paid to the seller. (e.g. false)
  user_name: string # Seller username. (e.g. myseller)
]: any -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/seller")
  let req_body = {"ArchiveId": $archive_id, "CNPJ": $cnpj, "CSCIdentification": $csc_identification, "CatalogSystemEndpoint": $catalog_system_endpoint, "CategoryCommissionPercentage": $category_commission_percentage, "DeliveryPolicy": $delivery_policy, "Description": $description, "Email": $email, "ExchangeReturnPolicy": $exchange_return_policy, "FreightCommissionPercentage": $freight_commission_percentage, "FulfillmentEndpoint": $fulfillment_endpoint, "FulfillmentSellerId": $fulfillment_seller_id, "IsActive": $is_active, "IsBetterScope": $is_better_scope, "MerchantName": $merchant_name, "Name": $name, "Password": $password, "ProductCommissionPercentage": $product_commission_percentage, "SecutityPrivacyPolicy": $secutity_privacy_policy, "SellerId": $seller_id, "SellerType": $seller_type, "TrustPolicy": $trust_policy, "UrlLogo": $url_logo, "UseHybridPaymentOptions": $use_hybrid_payment_options, "UserName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Update Seller
#
# PUT /api/catalog_system/pvt/seller
# operationId: UpdateSeller
export def "catalog-system-pvt-seller update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  archive_id: int # Seller archive ID. (e.g. 1)
  cnpj: string # Company registration number. (e.g. 12035072751)
  csc_identification: string # CSC identification. (e.g. pedrostore)
  catalog_system_endpoint: string # URL of the endpoint of the seller's catalog. This field will only be displayed if the seller type is VTEX Store. The field format will be as follows: `http://{sellerName}.vtexcommercestable.com.br/api/catalog_system/`. (e.g. http://pedrostore.vtexcommercestable.com.br/api/catalog_system/)
  --category-commission-percentage: string # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. [{"CategoryId":14,"ProductCommission":15.0,"FreightCommission":0.0}])
  delivery_policy: string # Text describing the delivery policy previously agreed between the marketplace and the seller. (e.g. Delivery policy text)
  description: string # Text describing the seller with a marketing tone. You can display this text in the marketplace window display by [customizing the CMS](https://help.vtex.com/en/tutorial/list-of-controls-for-templates--tutorials_563). (e.g. Brief description)
  email: string # Email of the admin responsible for the seller. (e.g. breno@breno.com)
  exchange_return_policy: string # Text describing the exchange and return policy previously agreed between the marketplace and the seller. (e.g. Exchange return policy text)
  freight_commission_percentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  fulfillment_endpoint: string # URL of the endpoint for fulfillment of seller's orders, which the marketplace will use to communicate with the seller. This field applies to all sellers, regardless of their type. However, for `VTEX Stores`, you don’t need to fill it in because the system will do that automatically. You can edit this field once the seller has been successfully added. (e.g. http://pedrostore.vtexcommercestable.com.br/api/fulfillment?affiliateid=LDB&sc=1)
  fulfillment_seller_id: int # Identification code of the seller responsible for fulfilling the order. This is an optional field used when a seller sells SKUs from another seller. If the seller sells their own SKUs, it must be left blank. (e.g. 1)
  --is-active: oneof<nothing, bool> # If the selle is active (`true`) or not (`false`). (e.g. true)
  --is-better-scope: oneof<nothing, bool> # Indicates whether it is a [comprehensive seller](https://help.vtex.com/en/tutorial/comprehensive-seller--5Qn4O2GpjUIzWTPpvLUfkI). (e.g. false)
  --merchant-name: string # Name of the marketplace, used to guide payments. This field should be nulled if the marketplace is responsible for processing payments. Check out our [Split Payment](https://help.vtex.com/en/tutorial/split-payment--6k5JidhYRUxileNolY2VLx) article to know more. (e.g. pedrostore)
  name: string # Name of the account in the seller's environment. You can find it on **Account settings > Account > Account Name**). Applicable only if the seller uses their own payment method. (e.g. My pedrostore)
  password: string # Seller password. (e.g. passoword)
  product_commission_percentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  secutity_privacy_policy: string # Text describing the security policy previously agreed between the marketplace and the seller. (e.g. Secutity privacy policy text)
  seller_id: string # ID that identifies the seller in the marketplace. It can be the same as the seller name or a unique number. Check the **Sellers management** section in the Admin to get the correct ID. (e.g. pedrostore)
  seller_type: int # Seller type. (e.g. 1)
  --trust-policy: string # Seller trust policy. The default value is `'Default'`, but if your store is a B2B marketplace and you want to share the customers'emails with the sellers you need to set this field as `'AllowEmailSharing'`. (e.g. Default)
  url_logo: string # Seller URL logo. (e.g. /myseller)
  --use-hybrid-payment-options: oneof<nothing, bool> # Allows customers to use gift cards from the seller to buy their products on the marketplace. It identifies purchases made with a gift card so that only the final price (with discounts applied) is paid to the seller. (e.g. false)
  user_name: string # Seller username. (e.g. myseller)
]: any -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/seller")
  let req_body = {"ArchiveId": $archive_id, "CNPJ": $cnpj, "CSCIdentification": $csc_identification, "CatalogSystemEndpoint": $catalog_system_endpoint, "CategoryCommissionPercentage": $category_commission_percentage, "DeliveryPolicy": $delivery_policy, "Description": $description, "Email": $email, "ExchangeReturnPolicy": $exchange_return_policy, "FreightCommissionPercentage": $freight_commission_percentage, "FulfillmentEndpoint": $fulfillment_endpoint, "FulfillmentSellerId": $fulfillment_seller_id, "IsActive": $is_active, "IsBetterScope": $is_better_scope, "MerchantName": $merchant_name, "Name": $name, "Password": $password, "ProductCommissionPercentage": $product_commission_percentage, "SecutityPrivacyPolicy": $secutity_privacy_policy, "SellerId": $seller_id, "SellerType": $seller_type, "TrustPolicy": $trust_policy, "UrlLogo": $url_logo, "UseHybridPaymentOptions": $use_hybrid_payment_options, "UserName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Seller List
#
# GET /api/catalog_system/pvt/seller/list
# operationId: SellerList
export def "catalog-system-pvt-seller-list list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade policy ID. (format: int32, e.g. 1)
  --seller-type: int # Seller type. (format: int32, e.g. 1)
  --is-better-scope: oneof<nothing, bool> # If the seller is better scope. (e.g. false)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar") (serialize-qp "sellerType" $seller_type "scalar") (serialize-qp "isBetterScope" $is_better_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/seller/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Seller by ID
#
# GET /api/catalog_system/pvt/seller/{sellerId}
# operationId: GetSellerbyId
export def "catalog-system-pvt-seller get-sellerby" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/api/catalog_system/pvt/seller/{seller_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Seller by ID
#
# GET /api/catalog_system/pvt/sellers/{sellerId}
# operationId: GetSellersbyId
export def "catalog-system-pvt-sellers get-sellersby" [
  seller_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id)} | format pattern "/api/catalog_system/pvt/sellers/{seller_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Associate attachments to an SKU
#
# POST /api/catalog_system/pvt/sku/associateattachments
# operationId: AssociateattachmentstoSKU
export def "catalog-system-pvt-sku-associateattachments create-associateattachmentsto" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  attachment_names: list<string> # Array with all the names of the attachments that you need to associate to the SKU.
  sku_id: int # Unique identifier of the SKU. (e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/sku/associateattachments")
  let req_body = {"AttachmentNames": $attachment_names, "SkuId": $sku_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get SKU complements by type
#
# GET /api/catalog_system/pvt/sku/complements/{parentSkuId}/{type}
# operationId: GetSKUcomplementsbytype
export def "catalog-system-pvt-sku-complements get-sk-ucomplementsbytype" [
  parent_sku_id: int
  type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ComplementSkuIds: list<int>, ParentSkuId: int, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({parent_sku_id: (encode-path-segment $parent_sku_id), type: (encode-path-segment $type)} | format pattern "/api/catalog_system/pvt/sku/complements/{parent_sku_id}/{type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU list by Product ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitByProductId/{productId}
# operationId: SkulistbyProductId
export def "catalog-system-pvt-sku-stockkeepingunit-by-product-id get-skulistby" [
  product_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ActivateIfPossible: bool, CommercialConditionId: int, CubicWeight: float, DateUpdated: string, EstimatedDateArrival: string, FlagKitItensSellApart: bool, Height: float, Id: int, InternalNote: string, IsActive: bool, IsDynamicKit: string, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsPersisted: bool, IsRemoved: bool, IsTransported: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalId: int, ModalType: string, Name: string, Position: int, ProductId: int, RealHeight: float, RealLength: float, RealWeightKg: float, RealWidth: float, RefId: string, ReferenceStockKeepingUnitId: string, RewardValue: float, UnitMultiplier: float, WeightKg: float, Width: float, isKitOptimized: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({product_id: (encode-path-segment $product_id)} | format pattern "/api/catalog_system/pvt/sku/stockkeepingunitByProductId/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU by Alternate ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyalternateId/{alternateId}
# operationId: SkubyAlternateId
export def "catalog-system-pvt-sku-stockkeepingunitbyalternate-id get-skuby-alternate" [
  alternate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, CategoriesFullPath: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsDirectCategoryActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, PositionsInClusters: record, ProductCategories: record, ProductCategoryIds: string, ProductClusterHighlights: record, ProductClusterNames: record, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({alternate_id: (encode-path-segment $alternate_id)} | format pattern "/api/catalog_system/pvt/sku/stockkeepingunitbyalternateId/{alternate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU by EAN
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyean/{ean}
# operationId: SkubyEAN
export def "catalog-system-pvt-sku-stockkeepingunitbyean get-skuby" [
  ean: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, CategoriesFullPath: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsDirectCategoryActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, PositionsInClusters: record, ProductCategories: record, ProductCategoryIds: string, ProductClusterHighlights: record, ProductClusterNames: record, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ean: (encode-path-segment $ean)} | format pattern "/api/catalog_system/pvt/sku/stockkeepingunitbyean/{ean}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU and context
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyid/{skuId}
# operationId: SkuContext
export def "catalog-system-pvt-sku-stockkeepingunitbyid get-context" [
  sku_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy's unique identifier number. (e.g. 1)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, ProductCategories: record, ProductCategoryIds: string, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog_system/pvt/sku/stockkeepingunitbyid/{sku_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get SKU ID by Reference ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitidbyrefid/{refId}
# operationId: SkuIdbyRefId
export def "catalog-system-pvt-sku-stockkeepingunitidbyrefid get-idby-ref" [
  ref_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ref_id: (encode-path-segment $ref_id)} | format pattern "/api/catalog_system/pvt/sku/stockkeepingunitidbyrefid/{ref_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all SKU IDs
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitids
# operationId: ListallSKUIDs
export def "catalog-system-pvt-sku-stockkeepingunitids get-listall-skui-ds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page from where you need to retrieve SKU IDs. (e.g. 1)
  --pagesize: int # Size of the page from where you need retrieve SKU IDs. The maximum value is `1000`. (e.g. 25)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/sku/stockkeepingunitids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all SKUs of a Trade Policy
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitidsbysaleschannel
export def "catalog-system-pvt-sku-stockkeepingunitidsbysaleschannel get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy’s unique numerical identifier. (e.g. 1)
  --page: int # Page number. (e.g. 1)
  --page-size: int # Number of items in the page. (e.g. 1)
  --only-assigned: oneof<nothing, bool> # If set as `false`, it allows the user to decide if the SKUs that are not assigned to a specific trade policy should be also returned. (e.g. true)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "onlyAssigned" $only_assigned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/sku/stockkeepingunitidsbysaleschannel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Change Notification with Seller ID and Seller SKU ID
#
# POST /api/catalog_system/pvt/skuseller/changenotification/{sellerId}/{sellerSkuId}
export def "catalog-system-pvt-skuseller-changenotification create" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), seller_sku_id: (encode-path-segment $seller_sku_id)} | format pattern "/api/catalog_system/pvt/skuseller/changenotification/{seller_id}/{seller_sku_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Change Notification with SKU ID
#
# POST /api/catalog_system/pvt/skuseller/changenotification/{skuId}
# operationId: ChangeNotification
export def "catalog-system-pvt-skuseller-changenotification create-change-notification" [
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({sku_id: (encode-path-segment $sku_id)} | format pattern "/api/catalog_system/pvt/skuseller/changenotification/{sku_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Remove a seller's SKU binding
#
# POST /api/catalog_system/pvt/skuseller/remove/{sellerId}/{sellerSkuId}
# operationId: DeleteSKUsellerassociation
export def "catalog-system-pvt-skuseller-remove delete-sk-usellerassociation" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), seller_sku_id: (encode-path-segment $seller_sku_id)} | format pattern "/api/catalog_system/pvt/skuseller/remove/{seller_id}/{seller_sku_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get details of a seller's SKU
#
# GET /api/catalog_system/pvt/skuseller/{sellerId}/{sellerSkuId}
# operationId: GetSKUseller
export def "catalog-system-pvt-skuseller get-sk-useller" [
  seller_id: string
  seller_sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<IsActive: bool, IsPersisted: bool, IsRemoved: bool, RequestedUpdateDate: string, SellerId: string, SellerStockKeepingUnitId: string, SkuSellerId: int, StockKeepingUnitId: int, UpdateDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({seller_id: (encode-path-segment $seller_id), seller_sku_id: (encode-path-segment $seller_sku_id)} | format pattern "/api/catalog_system/pvt/skuseller/{seller_id}/{seller_sku_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Specification Field
#
# POST /api/catalog_system/pvt/specification/field
# operationId: SpecificationsInsertField
@deprecated --flag is-wizard
export def "catalog-system-pvt-specification-field create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --category-id: int # Category ID. (nullable)
  --default-value: string # Specification Field default Value. (nullable)
  --description: string # Specification Field Description. (nullable)
  field_group_id: int # Specification Field Group ID. (format: int32)
  field_group_name: string # Specification Field Group Name.
  --field-id: int # Specification Field ID. (nullable)
  field_type_id: int # Specification Field Type ID. (format: int32)
  --field-value-id: int # Specification Field Value ID. (nullable)
  --is-active: oneof<nothing, bool> # Defines if the Specification Field is active. The default value is `true`.
  --is-filter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar.
  --is-on-product-details: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page.
  --is-required: oneof<nothing, bool> # Makes the Specification Field mandatory (`true`) or optional (`false`).
  --is-side-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar.
  --is-stock-keeping-unit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification. If `false`, it will be added as a product specification field.
  --is-top-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu.
  --is-wizard: oneof<nothing, bool> # Deprecated field. (DEPRECATED)
  name: string # Specification Field ID.
  position: int # Specification Field Position. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/specification/field")
  let req_body = {"CategoryId": $category_id, "DefaultValue": $default_value, "Description": $description, "FieldGroupId": $field_group_id, "FieldGroupName": $field_group_name, "FieldId": $field_id, "FieldTypeId": $field_type_id, "FieldValueId": $field_value_id, "IsActive": $is_active, "IsFilter": $is_filter, "IsOnProductDetails": $is_on_product_details, "IsRequired": $is_required, "IsSideMenuLinkActive": $is_side_menu_link_active, "IsStockKeepingUnit": $is_stock_keeping_unit, "IsTopMenuLinkActive": $is_top_menu_link_active, "IsWizard": $is_wizard, "Name": $name, "Position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Update Specification Field
#
# PUT /api/catalog_system/pvt/specification/field
# operationId: SpecificationsInsertFieldUpdate
@deprecated --flag is-wizard
export def "catalog-system-pvt-specification-field create-update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --category-id: int # Category ID. (nullable)
  --default-value: string # Specification Field default Value. (nullable)
  --description: string # Specification Field Description. (nullable)
  field_group_id: int # Specification Field Group ID. (format: int32)
  field_group_name: string # Specification Field Group Name.
  --field-id: int # Specification Field ID. (nullable)
  field_type_id: int # Specification Field Type ID. (format: int32)
  --field-value-id: int # Specification Field Value ID. (nullable)
  --is-active: oneof<nothing, bool> # Enables(`true`) or disables (`false`) the Specification Field. (e.g. true)
  --is-filter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar.
  --is-on-product-details: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page.
  --is-required: oneof<nothing, bool> # Makes the Specification Field mandatory (`true`) or optional (`false`).
  --is-side-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar. (e.g. false)
  --is-stock-keeping-unit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification field. If `false`, it will be added as a product specification field.
  --is-top-menu-link-active: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu.
  --is-wizard: oneof<nothing, bool> # Deprecated field. (DEPRECATED)
  name: string # Specification Field ID.
  position: int # Specification Field Position. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/specification/field")
  let req_body = {"CategoryId": $category_id, "DefaultValue": $default_value, "Description": $description, "FieldGroupId": $field_group_id, "FieldGroupName": $field_group_name, "FieldId": $field_id, "FieldTypeId": $field_type_id, "FieldValueId": $field_value_id, "IsActive": $is_active, "IsFilter": $is_filter, "IsOnProductDetails": $is_on_product_details, "IsRequired": $is_required, "IsSideMenuLinkActive": $is_side_menu_link_active, "IsStockKeepingUnit": $is_stock_keeping_unit, "IsTopMenuLinkActive": $is_top_menu_link_active, "IsWizard": $is_wizard, "Name": $name, "Position": $position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Create Specification Field Value
#
# POST /api/catalog_system/pvt/specification/fieldValue
# operationId: SpecificationsInsertFieldValue
export def "catalog-system-pvt-specification-field-value create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  field_id: int # Specification Field ID. (format: int32)
  --is-active: oneof<nothing, bool> # Defines if the Specification Field Value is active (`true`) or inactive (`false`).
  name: string # Specification Field Value Name.
  position: int # Specification Field Value Position. (format: int32)
  text: string # Specification Field Value Description.
]: any -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/specification/fieldValue")
  let req_body = {"FieldId": $field_id, "IsActive": $is_active, "Name": $name, "Position": $position, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Update Specification Field Value
#
# PUT /api/catalog_system/pvt/specification/fieldValue
# operationId: SpecificationsUpdateFieldValue
export def "catalog-system-pvt-specification-field-value update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --field-id: int # Specification Field ID. (nullable)
  --is-active: oneof<nothing, bool> # Defines if the Specification Field Value is active (`true`) or inactive (`false`).
  name: string # Specification Field Value Name.
  position: int # Specification Field Position. (format: int32)
  --text: string # Specification Field Value Description. (nullable)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/specification/fieldValue")
  let req_body = {"FieldId": $field_id, "IsActive": $is_active, "Name": $name, "Position": $position, "Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body
}

# Get Specification Field Value
#
# GET /api/catalog_system/pvt/specification/fieldValue/{fieldValueId}
# operationId: SpecificationsGetFieldValue
export def "catalog-system-pvt-specification-field-value get" [
  field_value_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({field_value_id: (encode-path-segment $field_value_id)} | format pattern "/api/catalog_system/pvt/specification/fieldValue/{field_value_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List Specification Group by Category
#
# GET /api/catalog_system/pvt/specification/groupbycategory/{categoryId}
# operationId: SpecificationsGroupListbyCategory
export def "catalog-system-pvt-specification-groupbycategory get-group-listby-category" [
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CategoryId: int, Id: int, Name: string, Position: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/api/catalog_system/pvt/specification/groupbycategory/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
