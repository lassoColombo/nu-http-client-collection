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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "addon-pvt-giftlist-get GetGiftList" } } | get name | first)
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
export def "addon-pvt-giftlist-get GetGiftList" [
  listId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<IsPublic: bool, address: string, dateCreated: string, eventCity: string, eventDate: string, eventLocation: string, eventState: string, fileId: int, fileUrl: string, giftCardId: int, giftCardRechargeSkuId: int, giftListId: int, giftListMembers: table<clientId: string, giftListId: int, giftListMemberId: int, isActive: bool, isAdmin: bool, name: string, surname: string, text1: string, text2: string, title: string, userId: string>, giftListSkuIds: list<string>, giftListTypeId: int, giftListTypeName: string, isActive: bool, isAddressOk: bool, memberNames: string, message: string, name: string, profileSystemUserAddressName: string, profileSystemUserId: string, shipsToOwner: bool, telemarketingId: int, telemarketingObservation: string, urlFolder: string, userId: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/addon/pvt/giftlist/get/($listId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Review Rate by Product ID
#
# GET /api/addon/pvt/review/GetProductRate/{productId}
# operationId: ReviewRateProduct
export def "addon-pvt-review-get-product-rate ReviewRateProduct" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/addon/pvt/review/GetProductRate/($productId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create attachment
#
# POST /api/catalog/pvt/attachment
# --Domains item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
export def "catalog-pvt-attachment post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  Domains: list # List of characteristics related to the attachment. — item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
  --IsActive: oneof<nothing, bool> # Defines if the attachment is active or not. (e.g. false)
  --IsRequired: oneof<nothing, bool> # Defines if the attachment is required or not. (e.g. false)
  Name: string # Attachment Name. (e.g. Shirt customization)
]: any -> record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/attachment")
  let body = {Domains: $Domains, IsActive: $IsActive, IsRequired: $IsRequired, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/attachment/($attachmentid)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/attachment/($attachmentid)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update attachment
#
# PUT /api/catalog/pvt/attachment/{attachmentid}
# --Domains item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
export def "catalog-pvt-attachment put" [
  attachmentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  Domains: list # List of characteristics related to the attachment. — item shape: {DomainValues?: string, FieldName?: string, MaxCaracters?: string}
  --IsActive: oneof<nothing, bool> # Defines if the attachment is active or not. (e.g. false)
  --IsRequired: oneof<nothing, bool> # Defines if the attachment is required or not. (e.g. false)
  Name: string # Attachment Name. (e.g. Shirt customization)
]: any -> record<Domains: table<DomainValues: string, FieldName: string, MaxCaracters: string>, Id: int, IsActive: bool, IsRequired: bool, Name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/attachment/($attachmentid)")
  let body = {Domains: $Domains, IsActive: $IsActive, IsRequired: $IsRequired, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Data: table<Domains: list, Id: int, IsActive: bool, IsRequired: bool, Name: string>, Page: int, Size: int, TotalPage: int, TotalRows: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/attachments")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Brand
#
# POST /api/catalog/pvt/brand
@deprecated --flag AdWordsRemarketingCode
@deprecated --flag LomadeeCampaignCode
export def "catalog-pvt-brand post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --Active: oneof<nothing, bool> # Defines if the brand is active (`true`) or not (`false`). (e.g. true)
  --AdWordsRemarketingCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  Id: int # Brand's unique numerical identifier. (e.g. 2000003)
  --Keywords: string # Store Framework - Deprecated. Legacy CMS Portal - Alternative search terms that will lead to the specific brand. The user can find the desired brand even when misspelling it. Used especially when words are of foreign origin and have a distinct spelling that is transcribed into a generic one, or when small spelling mistakes occur.  (e.g. adidas)
  --LinkId: string # Brand page slug. Only lowercase letters and hyphens (`-`) are allowed. (nullable, e.g. adidas-sports)
  --LomadeeCampaignCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --MenuHome: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - Defines if the Brand appears in the Department Menu control (`<vtex.cmc:departmentNavigator/>`).  (e.g. true)
  Name: string # Brand name. (e.g. Adidas)
  --Score: int # Store Framework - Deprecated Legacy CMS Portal - Value used to set the priority on the search result page.  (nullable, e.g. 10)
  --SiteTitle: string # Meta Title for the Brand page. (e.g. Adidas)
  --Text: string # Meta Description for the Brand page. A brief description of the brand, displayed by search engines. Since search engines can only display less than 150 characters, we recommend not exceeding this character limit when creating the description. (e.g. Adidas)
]: any -> record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/brand")
  let body = {Active: $Active, AdWordsRemarketingCode: $AdWordsRemarketingCode, Id: $Id, Keywords: $Keywords, LinkId: $LinkId, LomadeeCampaignCode: $LomadeeCampaignCode, MenuHome: $MenuHome, Name: $Name, Score: $Score, SiteTitle: $SiteTitle, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Brand
#
# DELETE /api/catalog/pvt/brand/{brandId}
export def "catalog-pvt-brand delete" [
  brandId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/brand/($brandId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Brand and context
#
# GET /api/catalog/pvt/brand/{brandId}
export def "catalog-pvt-brand get" [
  brandId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/brand/($brandId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Brand
#
# PUT /api/catalog/pvt/brand/{brandId}
@deprecated --flag AdWordsRemarketingCode
@deprecated --flag LomadeeCampaignCode
export def "catalog-pvt-brand put" [
  brandId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --Active: oneof<nothing, bool> # Defines if the brand is active (`true`) or not (`false`). (e.g. true)
  --AdWordsRemarketingCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  Id: int # Brand's unique numerical identifier. (e.g. 2000003)
  --Keywords: string # Store Framework - Deprecated. Legacy CMS Portal - Alternative search terms that will lead to the specific brand. The user can find the desired brand even when misspelling it. Used especially when words are of foreign origin and have a distinct spelling that is transcribed into a generic one, or when small spelling mistakes occur.  (e.g. adidas)
  --LinkId: string # Brand page slug. Only lowercase letters and hyphens (`-`) are allowed. (nullable, e.g. adidas-sports)
  --LomadeeCampaignCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --MenuHome: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - Defines if the Brand appears in the Department Menu control (`<vtex.cmc:departmentNavigator/>`).  (e.g. true)
  Name: string # Brand name. (e.g. Adidas)
  --Score: int # Store Framework - Deprecated Legacy CMS Portal - Value used to set the priority on the search result page.  (nullable, e.g. 10)
  --SiteTitle: string # Meta Title for the Brand page. (e.g. Adidas)
  --Text: string # Meta Description for the Brand page. A brief description of the brand, displayed by search engines. Since search engines can only display less than 150 characters, we recommend not exceeding this character limit when creating the description. (e.g. Adidas)
]: any -> record<Active: bool, AdWordsRemarketingCode: string, Id: int, Keywords: string, LinkId: string, LomadeeCampaignCode: string, MenuHome: bool, Name: string, Score: int, SiteTitle: string, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/brand/($brandId)")
  let body = {Active: $Active, AdWordsRemarketingCode: $AdWordsRemarketingCode, Id: $Id, Keywords: $Keywords, LinkId: $LinkId, LomadeeCampaignCode: $LomadeeCampaignCode, MenuHome: $MenuHome, Name: $Name, Score: $Score, SiteTitle: $SiteTitle, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Category
#
# POST /api/catalog/pvt/category
@deprecated --flag AdWordsRemarketingCode
@deprecated --flag LomadeeCampaignCode
export def "catalog-pvt-category post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --ActiveStoreFrontLink: oneof<nothing, bool> # If true, the Category link becomes active in store. (e.g. true)
  --AdWordsRemarketingCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, nullable, e.g. Sale)
  Description: string # Text used in meta description tag for Category page. (e.g. Discover our range of home appliances. Find smart vacuums, kitchen and laundry appliances to suit your needs. Order online now.)
  --FatherCategoryId: int # ID of the parent category, apply in case of category and subcategory. (nullable, e.g. 2)
  GlobalCategoryId: int # Google Global Category ID. (e.g. 222)
  --Id: int # Category unique identifier. If not informed, it will be automatically generated by VTEX. (e.g. 1)
  --IsActive: oneof<nothing, bool> # If true, the Category page becomes available in store. (e.g. true)
  Keywords: string # Substitute words for the Category. (e.g. Kitchen, Laundry, Appliances)
  --LomadeeCampaignCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, nullable, e.g. Sale)
  Name: string # Category name. (e.g. Home Appliances)
  --Score: int # Score for search sorting order. (nullable, e.g. 3)
  --ShowBrandFilter: oneof<nothing, bool> # If true, the Category page displays a Brand filter. (e.g. true)
  --ShowInStoreFront: oneof<nothing, bool> # If true, the Category is shown in the top and side menu. (e.g. true)
  StockKeepingUnitSelectionMode: string # Defines how the SKU will be exhibited (e.g. SPECIFICATION)
  Title: string # Text used in title tag for Category page. (e.g. Home Appliances)
]: any -> record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/category")
  let body = {ActiveStoreFrontLink: $ActiveStoreFrontLink, AdWordsRemarketingCode: $AdWordsRemarketingCode, Description: $Description, FatherCategoryId: $FatherCategoryId, GlobalCategoryId: $GlobalCategoryId, Id: $Id, IsActive: $IsActive, Keywords: $Keywords, LomadeeCampaignCode: $LomadeeCampaignCode, Name: $Name, Score: $Score, ShowBrandFilter: $ShowBrandFilter, ShowInStoreFront: $ShowInStoreFront, StockKeepingUnitSelectionMode: $StockKeepingUnitSelectionMode, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Category by ID
#
# GET /api/catalog/pvt/category/{categoryId}
export def "catalog-pvt-category get" [
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/category/($categoryId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Category
#
# PUT /api/catalog/pvt/category/{categoryId}
export def "catalog-pvt-category put" [
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --ActiveStoreFrontLink: oneof<nothing, bool> # If true, the Category link becomes active in store. (e.g. true)
  AdWordsRemarketingCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, e.g. Sale)
  Description: string # Text used in meta description tag for Category page. (e.g. Discover our range of home appliances. Find smart vacuums, kitchen and laundry appliances to suit your needs. Order online now.)
  --FatherCategoryId: int # ID of the parent category, apply in case of category and subcategory. (nullable, e.g. 2)
  GlobalCategoryId: int # Google Global Category ID. (e.g. 222)
  --IsActive: oneof<nothing, bool> # If true, the Category page becomes available in store. (e.g. true)
  Keywords: string # Substitute words for the Category. (e.g. Kitchen, Laundry, Appliances)
  LomadeeCampaignCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED, e.g. Sale)
  Name: string # Category name. (e.g. Home Appliances)
  Score: int # Score for search sorting order. (e.g. 3)
  --ShowBrandFilter: oneof<nothing, bool> # If true, the Category page displays a Brand filter. (e.g. true)
  --ShowInStoreFront: oneof<nothing, bool> # If true, the Category is shown in the top and side menu. (e.g. true)
  StockKeepingUnitSelectionMode: string # Defines how the SKU will be exhibited (e.g. SPECIFICATION)
  Title: string # Text used in title tag for Category page. (e.g. Home Appliances)
]: any -> record<ActiveStoreFrontLink: bool, AdWordsRemarketingCode: string, Description: string, FatherCategoryId: int, GlobalCategoryId: int, HasChildren: bool, Id: int, IsActive: bool, Keywords: string, LinkId: string, LomadeeCampaignCode: string, Name: string, Score: int, ShowBrandFilter: bool, ShowInStoreFront: bool, StockKeepingUnitSelectionMode: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/category/($categoryId)")
  let body = {ActiveStoreFrontLink: $ActiveStoreFrontLink, AdWordsRemarketingCode: $AdWordsRemarketingCode, Description: $Description, FatherCategoryId: $FatherCategoryId, GlobalCategoryId: $GlobalCategoryId, IsActive: $IsActive, Keywords: $Keywords, LomadeeCampaignCode: $LomadeeCampaignCode, Name: $Name, Score: $Score, ShowBrandFilter: $ShowBrandFilter, ShowInStoreFront: $ShowInStoreFront, StockKeepingUnitSelectionMode: $StockKeepingUnitSelectionMode, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Collection
#
# POST /api/catalog/pvt/collection
export def "catalog-pvt-collection post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  DateFrom: string # Initial value date for the Collection. (e.g. 2017-09-27T10:47:00)
  DateTo: string # Final value date for the Collection. (e.g. 2017-09-27T10:47:00)
  --Highlight: oneof<nothing, bool> # Defines if the Collection is highlighted or not. (e.g. false)
  Name: string # Collection Name. (e.g. Test)
  --Searchable: oneof<nothing, bool> # Defines if the Collection is searchable or not. (e.g. true)
]: any -> record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/collection")
  let body = {DateFrom: $DateFrom, DateTo: $DateTo, Highlight: $Highlight, Name: $Name, Searchable: $Searchable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Collection
#
# POST /api/catalog/pvt/collection/
# operationId: POST-CreateCollection
export def "catalog-pvt-collection POST-CreateCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  DateFrom: string # Collection start date and time. If a future date and time are set, the collection will have a scheduled status. (e.g. 2020-11-26T15:23:00)
  DateTo: string # Collection end date and time. (e.g. 2069-11-26T15:23:00)
  Description: string # Collection's description for internal use, with the collection's details. It will not be used for search engines. (e.g. HomeHalloween)
  --Highlight: oneof<nothing, bool> # Option if you want the collection to highlight specific products using a tag. (e.g. false)
  Name: string # Collection's Name. (e.g. Halloween costumes)
  --Searchable: oneof<nothing, bool> # Option making the collection searchable in the store. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/collection/")
  let body = {DateFrom: $DateFrom, DateTo: $DateTo, Description: $Description, Highlight: $Highlight, Name: $Name, Searchable: $Searchable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get All Inactive Collections
#
# GET /api/catalog/pvt/collection/inactive
# operationId: GET-AllInactiveCollections
export def "catalog-pvt-collection-inactive GET-AllInactiveCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/collection/inactive")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Import Collection file example
#
# GET /api/catalog/pvt/collection/stockkeepingunit/importfileexample
# operationId: GET-Importfileexample
export def "catalog-pvt-collection-stockkeepingunit-importfileexample GET-Importfileexample" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/collection/stockkeepingunit/importfileexample")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Collection
#
# DELETE /api/catalog/pvt/collection/{collectionId}
export def "catalog-pvt-collection delete" [
  collectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/collection/($collectionId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Collection
#
# GET /api/catalog/pvt/collection/{collectionId}
export def "catalog-pvt-collection get" [
  collectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/collection/($collectionId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Collection
#
# PUT /api/catalog/pvt/collection/{collectionId}
export def "catalog-pvt-collection put" [
  collectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  DateFrom: string # Initial value date for the Collection. (e.g. 2017-09-27T10:47:00)
  DateTo: string # Final value date for the Collection. (e.g. 2017-09-27T10:47:00)
  --Highlight: oneof<nothing, bool> # Defines if the Collection is highlighted or not (e.g. false)
  Name: string # Collection Name. (e.g. Test)
  --Searchable: oneof<nothing, bool> # Defines if the Collection is searchable or not. (e.g. true)
]: any -> record<DateFrom: string, DateTo: string, Description: string, Highlight: bool, Id: int, Name: string, Searchable: bool, TotalProducts: int, Type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/collection/($collectionId)")
  let body = {DateFrom: $DateFrom, DateTo: $DateTo, Highlight: $Highlight, Name: $Name, Searchable: $Searchable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reposition SKU on the Subcollection
#
# POST /api/catalog/pvt/collection/{collectionId}/position
export def "catalog-pvt-collection-position post" [
  collectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  position: int # SKU position. (e.g. 1)
  skuId: int # SKU ID. (e.g. 1)
  subCollectionId: int # Subcollection ID. (e.g. 17)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/collection/($collectionId)/position")
  let body = {position: $position, skuId: $skuId, subCollectionId: $subCollectionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get products from a collection
#
# GET /api/catalog/pvt/collection/{collectionId}/products
# operationId: GET-Productsfromacollection
export def "catalog-pvt-collection-products GET-Productsfromacollection" [
  collectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (e.g. 2)
  --pageSize: int # Number of the items of the page. (e.g. 15)
  --Filter: string # Filter used to refine the Collection's products. (e.g. Pre launch)
  --Active: oneof<nothing, bool> # Defines if the status of the product is active or not. (e.g. true)
  --Visible: oneof<nothing, bool> # Defines if the product is visible on the store or not. (e.g. true)
  --CategoryId: int # Product's Category unique identifier. (e.g. 12)
  --BrandId: int # Product's Brand unique identifier. (e.g. 3)
  --SupplierId: int # Product's Supplier unique identifier. (e.g. 1)
  --SalesChannelId: int # Product's Trade Policy unique identifier. (e.g. 1)
  --ReleaseFrom: string # Product past release date. (e.g. 2069-11-26T15:23:00)
  --ReleaseTo: string # Product future release date. (e.g. 2069-11-26T15:23:00)
  --SpecificationProduct: string # Product Specification Field Value. You must also fill in `SpecificationFieldId` to use this parameter. (e.g. M)
  --SpecificationFieldId: int # Product Specification Field unique identifier. (e.g. 40)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "Filter" $Filter "scalar") (serialize-qp "Active" $Active "scalar") (serialize-qp "Visible" $Visible "scalar") (serialize-qp "CategoryId" $CategoryId "scalar") (serialize-qp "BrandId" $BrandId "scalar") (serialize-qp "SupplierId" $SupplierId "scalar") (serialize-qp "SalesChannelId" $SalesChannelId "scalar") (serialize-qp "ReleaseFrom" $ReleaseFrom "scalar") (serialize-qp "ReleaseTo" $ReleaseTo "scalar") (serialize-qp "SpecificationProduct" $SpecificationProduct "scalar") (serialize-qp "SpecificationFieldId" $SpecificationFieldId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog/pvt/collection/($collectionId)/products" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove products from Collection by imported file
#
# POST /api/catalog/pvt/collection/{collectionId}/stockkeepingunit/importexclude
# operationId: POST-Removeproductsbyimportfile
export def "catalog-pvt-collection-stockkeepingunit-importexclude POST-Removeproductsbyimportfile" [
  collectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --file: any # XLS file with information about products to be added to a Collection. The file must be an imported template from [Import Collection file example](https://developers.vtex.com/vtex-developer-docs/reference/get-importfileexample) endpoint. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/collection/($collectionId)/stockkeepingunit/importexclude")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Add products to Collection by imported file
#
# POST /api/catalog/pvt/collection/{collectionId}/stockkeepingunit/importinsert
# operationId: POST-Addproductsbyimportfile
export def "catalog-pvt-collection-stockkeepingunit-importinsert POST-Addproductsbyimportfile" [
  collectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --file: any # XLS file with information about products to be added to a Collection. The file must be an imported template from [Import Collection file example](https://developers.vtex.com/vtex-developer-docs/reference/get-importfileexample) endpoint. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/collection/($collectionId)/stockkeepingunit/importinsert")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get Subcollection by Collection ID
#
# GET /api/catalog/pvt/collection/{collectionId}/subcollection
export def "catalog-pvt-collection-subcollection get" [
  collectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/collection/($collectionId)/subcollection")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Product with Category and Brand
#
# POST /api/catalog/pvt/product
@deprecated --flag AdWordsRemarketingCode
@deprecated --flag LomadeeCampaignCode
@deprecated --flag SupplierId
export def "catalog-pvt-product post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --AdWordsRemarketingCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --BrandId: int # ID of an existing Brand that will be associated with this product. It is mandatory to use either this field or the `BrandName` field. (e.g. 12121219)
  --BrandName: string # Name of the brand that will be associated with this product. It is mandatory to use either this field or the `BrandId` field. If you wish to create a new brand, that is, in case the brand does not exist yet, use this field instead of `BrandId`. (e.g. Sample Brand)
  --CategoryId: int # ID of an existing Category that will be associated with this product. It is mandatory to use either this field or the `CategoryPath` field. (e.g. 2000090)
  --CategoryPath: string # Path of categories associated with this product, from the highest level of category to the lowest level, separated by `/`. It is mandatory to use either this field or the `CategoryId` field. (e.g. Mens/Clothing/T-Shirts)
  --Description: string # Product description. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  --DescriptionShort: string # Short product description. This information can be displayed on both the product page and the shelf, using the following controls:  Store Framework:  `$product.DescriptionShort`.  Legacy CMS Portal: `<vtex.cmc:productDescriptionShort/>`.  (e.g. The Nike Zoom Stefan Janoski is made with a premium leather.)
  --Id: int # Product’s unique numerical identifier. If not informed, it will be automatically generated by VTEX. (e.g. 42)
  --IsActive: oneof<nothing, bool> # Activate (`true`) or inactivate (`false`) product. (e.g. true)
  --IsVisible: oneof<nothing, bool> # Shows (`true`) or hides (`false`) the product in search result and product pages, but the product can still be added to the shopping cart. Usually applicable for gifts. (e.g. true)
  --KeyWords: string # Store Framework: Deprecated.  Legacy CMS Portal: Keywords or synonyms related to the product, separated by comma (`,`). "Television", for example, can have a substitute word like "TV". This field is important to make your searches more comprehensive.  (e.g. Zoom,Stefan,Janoski)
  --LinkId: string # Slug that will be used to build the product page URL. If it not informed, it will be generated according to the product's name replacing spaces and special characters by hyphens (`-`). (e.g. stefan-janoski-canvas-varsity-red)
  --LomadeeCampaignCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --MetaTagDescription: string # Brief description of the product for SEO. It is recommended not to exceed 150 characters. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  Name: string # Product's name. Limited to 150 characters. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
  --RefId: string # Product Reference Code. (e.g. sr_1_90)
  --ReleaseDate: string # Used to assist in the ordering of the search result of the site. Using the `O=OrderByReleaseDateDESC` query string, you can pull this value and show the display order by release date. This attribute is also used as a condition for dynamic collections. (e.g. 2019-01-01T00:00:00)
  --Score: int # Value used to set the priority on the search result page. (e.g. 1)
  --ShowWithoutStock: oneof<nothing, bool> # If `true`, activates the [Notify Me](https://help.vtex.com/en/tutorial/setting-up-the-notify-me-option--2VqVifQuf6Co2KG048Yu6e) option when the product is out of stock. (e.g. true)
  --SupplierId: int # DEPRECATED, nullable
  --TaxCode: string # Product tax code, used for tax calculation. (e.g. 12345)
  --Title: string # Product's Title tag. Limited to 150 characters. It is presented in the browser tab and corresponds to the title of the product page. This field is important for SEO. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
]: any -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/product")
  let body = {AdWordsRemarketingCode: $AdWordsRemarketingCode, BrandId: $BrandId, BrandName: $BrandName, CategoryId: $CategoryId, CategoryPath: $CategoryPath, Description: $Description, DescriptionShort: $DescriptionShort, Id: $Id, IsActive: $IsActive, IsVisible: $IsVisible, KeyWords: $KeyWords, LinkId: $LinkId, LomadeeCampaignCode: $LomadeeCampaignCode, MetaTagDescription: $MetaTagDescription, Name: $Name, RefId: $RefId, ReleaseDate: $ReleaseDate, Score: $Score, ShowWithoutStock: $ShowWithoutStock, SupplierId: $SupplierId, TaxCode: $TaxCode, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Product by ID
#
# GET /api/catalog/pvt/product/{productId}
# operationId: GetProductbyid
export def "catalog-pvt-product GetProductbyid" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Product
#
# PUT /api/catalog/pvt/product/{productId}
@deprecated --flag AdWordsRemarketingCode
@deprecated --flag LomadeeCampaignCode
@deprecated --flag SupplierId
export def "catalog-pvt-product put" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --AdWordsRemarketingCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  BrandId: int # Brand ID associated with this product. (e.g. 12121219)
  CategoryId: int # Category ID associated with this product. (e.g. 2000090)
  --DepartmentId: int # Department ID according to the product's category. (e.g. 2000089)
  --Description: string # Product description. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  --DescriptionShort: string # Short product description. This information can be displayed on both the product page and the shelf, using the following controls:  Store Framework:  `$product.DescriptionShort`.  Legacy CMS Portal: `<vtex.cmc:productDescriptionShort/>`.  (e.g. The Nike Zoom Stefan Janoski is made with a premium leather.)
  --IsActive: oneof<nothing, bool> # Activate (`true`) or inactivate (`false`) product. (e.g. true)
  --IsVisible: oneof<nothing, bool> # Shows (`true`) or hides (`false`) the product in search result and product pages, but the product can still be added to the shopping cart. Usually applicable for gifts. (e.g. true)
  --KeyWords: string # Store Framework: Deprecated.  Legacy CMS Portal: Keywords or synonyms related to the product, separated by comma (`,`). "Television", for example, can have a substitute word like "TV". This field is important to make your searches more comprehensive.  (e.g. Zoom,Stefan,Janoski)
  --LinkId: string # Slug that will be used to build the product page URL. If it not informed, it will be generated according to the product's name replacing spaces and special characters by hyphens (`-`). (e.g. stefan-janoski-canvas-varsity-red)
  --LomadeeCampaignCode: string # This is a legacy field. Do not take this information into consideration. (DEPRECATED)
  --MetaTagDescription: string # Brief description of the product for SEO. It is recommended not to exceed 150 characters. (e.g. The Nike Zoom Stefan Janoski Men's Shoe is made with a premium leather upper for superior durability and a flexible midsole for all-day comfort. A tacky gum rubber outsole delivers outstanding traction.)
  Name: string # Product's name. Limited to 150 characters. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
  --RefId: string # Product Reference Code. (e.g. sr_1_90)
  --ReleaseDate: string # Used to assist in the ordering of the search result of the site. Using the `O=OrderByReleaseDateDESC` query string, you can pull this value and show the display order by release date. This attribute is also used as a condition for dynamic collections. (e.g. 2019-01-01T00:00:00)
  --Score: int # Value used to set the priority on the search result page. (e.g. 1)
  --ShowWithoutStock: oneof<nothing, bool> # If `true`, activates the [Notify Me](https://help.vtex.com/en/tutorial/setting-up-the-notify-me-option--2VqVifQuf6Co2KG048Yu6e) option when the product is out of stock. (e.g. true)
  --SupplierId: int # DEPRECATED, nullable
  --TaxCode: string # Product tax code, used for tax calculation. (e.g. 12345)
  --Title: string # Product's Title tag. Limited to 150 characters. It is presented in the browser tab and corresponds to the title of the product page. This field is important for SEO. (e.g. Zoom Stefan Janoski Canvas RM SB Varsity Red)
]: any -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, Score: int, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)")
  let body = {AdWordsRemarketingCode: $AdWordsRemarketingCode, BrandId: $BrandId, CategoryId: $CategoryId, DepartmentId: $DepartmentId, Description: $Description, DescriptionShort: $DescriptionShort, IsActive: $IsActive, IsVisible: $IsVisible, KeyWords: $KeyWords, LinkId: $LinkId, LomadeeCampaignCode: $LomadeeCampaignCode, MetaTagDescription: $MetaTagDescription, Name: $Name, RefId: $RefId, ReleaseDate: $ReleaseDate, Score: $Score, ShowWithoutStock: $ShowWithoutStock, SupplierId: $SupplierId, TaxCode: $TaxCode, Title: $Title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Trade Policies by Product ID
#
# GET /api/catalog/pvt/product/{productId}/salespolicy
export def "catalog-pvt-product-salespolicy get" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ProductId: int, StoreId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/salespolicy")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove Product from Trade Policy
#
# DELETE /api/catalog/pvt/product/{productId}/salespolicy/{tradepolicyId}
export def "catalog-pvt-product-salespolicy delete" [
  productId: int
  tradepolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/salespolicy/($tradepolicyId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate Product with Trade Policy
#
# POST /api/catalog/pvt/product/{productId}/salespolicy/{tradepolicyId}
export def "catalog-pvt-product-salespolicy post" [
  productId: int
  tradepolicyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/salespolicy/($tradepolicyId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Similar Categories
#
# GET /api/catalog/pvt/product/{productId}/similarcategory/
export def "catalog-pvt-product-similarcategory get" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CategoryId: int, ProductId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/similarcategory/")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Similar Category
#
# DELETE /api/catalog/pvt/product/{productId}/similarcategory/{categoryId}
export def "catalog-pvt-product-similarcategory delete" [
  productId: int
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/similarcategory/($categoryId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Similar Category
#
# POST /api/catalog/pvt/product/{productId}/similarcategory/{categoryId}
export def "catalog-pvt-product-similarcategory post" [
  productId: int
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ProductId: int, StoreId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/similarcategory/($categoryId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all Product Specifications by Product ID
#
# DELETE /api/catalog/pvt/product/{productId}/specification
# operationId: DeleteAllProductSpecifications
export def "catalog-pvt-product-specification DeleteAllProductSpecifications" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/specification")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Specification and its information by Product ID
#
# GET /api/catalog/pvt/product/{productId}/specification
# operationId: GetProductSpecificationbyProductID
export def "catalog-pvt-product-specification GetProductSpecificationbyProductID" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/specification")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate Product Specification
#
# POST /api/catalog/pvt/product/{productId}/specification
export def "catalog-pvt-product-specification post" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  FieldId: int # Specification ID. (e.g. 19)
  --FieldValueId: int # Specification Value ID. Mandatory for `FieldTypeId` `5`, `6` and `7`. Must not be used for any other field types (e.g. 12)
  --Text: string # Value of specification. Only for `FieldTypeId` different from `5`, `6` and `7`. (e.g. Metal)
]: any -> record<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/specification")
  let body = {FieldId: $FieldId, FieldValueId: $FieldValueId, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a specific Product Specification
#
# DELETE /api/catalog/pvt/product/{productId}/specification/{specificationId}
# operationId: DeleteaProductSpecification
export def "catalog-pvt-product-specification DeleteaProductSpecification" [
  productId: int
  specificationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/specification/($specificationId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate product specification using specification name and group name
#
# PUT /api/catalog/pvt/product/{productId}/specificationvalue
export def "catalog-pvt-product-specificationvalue put" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  FieldName: string # Specification name. (e.g. Material)
  FieldValues: list # Array of specification values. (e.g. [Cotton, Polyester])
  GroupName: string # Group name. (e.g. Composition)
  --RootLevelSpecification: oneof<nothing, bool> # Root level specification. (e.g. true)
]: any -> table<FieldId: int, FieldValueId: int, Id: int, ProductId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/product/($productId)/specificationvalue")
  let body = {FieldName: $FieldName, FieldValues: $FieldValues, GroupName: $GroupName, RootLevelSpecification: $RootLevelSpecification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --skuId: int # SKU ID. By using this query param, you can dissociate all the attachments from an SKU based on its SKU ID. (format: int32, e.g. 1)
  --attachmentId: int # Attachment ID. By using this query param, you can dissociate the given attachment from all previously associated SKUs. (format: int32, e.g. 1)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $skuId "scalar") (serialize-qp "attachmentId" $attachmentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/skuattachment" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate SKU Attachment
#
# POST /api/catalog/pvt/skuattachment
export def "catalog-pvt-skuattachment post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  AttachmentId: int # Attachment ID. (e.g. 1)
  SkuId: int # Unique identifier of an SKU. (e.g. 1)
]: any -> record<AttachmentId: int, Id: int, SkuId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuattachment")
  let body = {AttachmentId: $AttachmentId, SkuId: $SkuId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete SKU Attachment by Attachment Association ID
#
# DELETE /api/catalog/pvt/skuattachment/{skuAttachmentAssociationId}
export def "catalog-pvt-skuattachment delete-by-skuAttachmentAssociationId" [
  skuAttachmentAssociationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuattachment/($skuAttachmentAssociationId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create SKU Complement
#
# POST /api/catalog/pvt/skucomplement
# operationId: CreateSKUComplement
export def "catalog-pvt-skucomplement CreateSKUComplement" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  ComplementTypeId: int # Complement Type ID. This represents the type of the complement. The possible values are: `1` for Accessory; `2` for Suggestion; `3` for Similar Product; `5` for Show Together. (e.g. 1)
  ParentSkuId: int # ID of the Parent SKU, where the Complement is inserted. (e.g. 1)
  SkuId: int # ID of the SKU which will be inserted as a Complement in the Parent SKU. (e.g. 1)
]: any -> table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skucomplement")
  let body = {ComplementTypeId: $ComplementTypeId, ParentSkuId: $ParentSkuId, SkuId: $SkuId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete SKU Complement by SKU Complement ID
#
# DELETE /api/catalog/pvt/skucomplement/{skuComplementId}
# operationId: DeleteSKUComplementbySKUComplementID
export def "catalog-pvt-skucomplement DeleteSKUComplementbySKUComplementID" [
  skuComplementId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skucomplement/($skuComplementId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Complement by SKU Complement ID
#
# GET /api/catalog/pvt/skucomplement/{skuComplementId}
# operationId: GetSKUComplementbySKUComplementID
export def "catalog-pvt-skucomplement GetSKUComplementbySKUComplementID" [
  skuComplementId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skucomplement/($skuComplementId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate SKU Service
#
# POST /api/catalog/pvt/skuservice
export def "catalog-pvt-skuservice post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --IsActive: oneof<nothing, bool> # Defines if the SKU Service is active or not. (e.g. true)
  Name: string # SKU Service Name. Maximum of 50 characters. (e.g. Engraving)
  SkuId: int # SKU ID. (e.g. 1)
  SkuServiceTypeId: int # SKU Service Type ID. (e.g. 1)
  SkuServiceValueId: int # SKU Service Value ID. (e.g. 1)
  Text: string # Internal description of the SKU Service. Maximum of 100 characters. (e.g. Name engraving additional service.)
]: any -> record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuservice")
  let body = {IsActive: $IsActive, Name: $Name, SkuId: $SkuId, SkuServiceTypeId: $SkuServiceTypeId, SkuServiceValueId: $SkuServiceValueId, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Dissociate SKU Service
#
# DELETE /api/catalog/pvt/skuservice/{skuServiceId}
export def "catalog-pvt-skuservice delete" [
  skuServiceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservice/($skuServiceId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Service
#
# GET /api/catalog/pvt/skuservice/{skuServiceId}
export def "catalog-pvt-skuservice get" [
  skuServiceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservice/($skuServiceId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update SKU Service
#
# PUT /api/catalog/pvt/skuservice/{skuServiceId}
export def "catalog-pvt-skuservice put" [
  skuServiceId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --IsActive: oneof<nothing, bool> # Defines if the SKU Service is active or not. (e.g. true)
  Name: string # SKU Service Name. Maximum of 50 characters. (e.g. Test name)
  SkuId: int # SKU ID. (e.g. 1)
  SkuServiceTypeId: int # SKU Service Type ID. (e.g. 2)
  SkuServiceValueId: int # SKU Service Value ID. (e.g. 1)
  Text: string # Internal description for the SKU Service. Maximum of 100 characters. (e.g. Text)
]: any -> record<Id: int, IsActive: bool, Name: string, SkuId: int, SkuServiceTypeId: int, SkuServiceValueId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservice/($skuServiceId)")
  let body = {IsActive: $IsActive, Name: $Name, SkuId: $SkuId, SkuServiceTypeId: $SkuServiceTypeId, SkuServiceValueId: $SkuServiceValueId, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create SKU Service Type
#
# POST /api/catalog/pvt/skuservicetype
@deprecated --flag ShowOnProductFront
export def "catalog-pvt-skuservicetype post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --IsActive: oneof<nothing, bool> # Defines if the SKU Service Type is active or not. (default: true)
  --IsGiftCard: oneof<nothing, bool> # Defines if the SKU Service Type is displayed as a Gift Card. (e.g. false)
  --IsRequired: oneof<nothing, bool> # Defines if the SKU Service type is mandatory. (e.g. false)
  Name: string # SKU Service Type Name. Maximum of 100 characters. (default: Test API Sku Services)
  --ShowOnAttachmentFront: oneof<nothing, bool> # Defines if the SKU Service Type has an attachment. (e.g. false)
  --ShowOnCartFront: oneof<nothing, bool> # Defines if the SKU Service Type is displayed on the cart screen. (e.g. false)
  --ShowOnFileUpload: oneof<nothing, bool> # Defines if the SKU Service Type can be associated with an attachment or not. (e.g. false)
  --ShowOnProductFront: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
]: any -> record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuservicetype")
  let body = {IsActive: $IsActive, IsGiftCard: $IsGiftCard, IsRequired: $IsRequired, Name: $Name, ShowOnAttachmentFront: $ShowOnAttachmentFront, ShowOnCartFront: $ShowOnCartFront, ShowOnFileUpload: $ShowOnFileUpload, ShowOnProductFront: $ShowOnProductFront} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete SKU Service Type
#
# DELETE /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
export def "catalog-pvt-skuservicetype delete" [
  skuServiceTypeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservicetype/($skuServiceTypeId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Service Type
#
# GET /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
export def "catalog-pvt-skuservicetype get" [
  skuServiceTypeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservicetype/($skuServiceTypeId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update SKU Service Type
#
# PUT /api/catalog/pvt/skuservicetype/{skuServiceTypeId}
@deprecated --flag ShowOnProductFront
export def "catalog-pvt-skuservicetype put" [
  skuServiceTypeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --IsActive: oneof<nothing, bool> # Defines if the SKU Service Type is active or not. (default: true)
  --IsGiftCard: oneof<nothing, bool> # Defines if the SKU Service Type is displayed as a Gift Card. (e.g. false)
  --IsRequired: oneof<nothing, bool> # Defines if the SKU Service type is mandatory. (e.g. false)
  Name: string # SKU Service Type Name. Maximum of 100 characters. (default: Test API Sku Services)
  --ShowOnAttachmentFront: oneof<nothing, bool> # Defines if the SKU Service Type has an attachment. (e.g. false)
  --ShowOnCartFront: oneof<nothing, bool> # Defines if the SKU Service Type is displayed on the cart screen. (e.g. false)
  --ShowOnFileUpload: oneof<nothing, bool> # Defines if the SKU Service Type can be associated with an attachment or not. (e.g. false)
  --ShowOnProductFront: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
]: any -> record<Id: int, IsActive: bool, IsGiftCard: bool, IsRequired: bool, Name: string, ShowOnAttachmentFront: bool, ShowOnCartFront: bool, ShowOnFileUpload: bool, ShowOnProductFront: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservicetype/($skuServiceTypeId)")
  let body = {IsActive: $IsActive, IsGiftCard: $IsGiftCard, IsRequired: $IsRequired, Name: $Name, ShowOnAttachmentFront: $ShowOnAttachmentFront, ShowOnCartFront: $ShowOnCartFront, ShowOnFileUpload: $ShowOnFileUpload, ShowOnProductFront: $ShowOnProductFront} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachmentId: int # SKU Service Attachment unique identifier. (e.g. 1)
  --skuServiceTypeId: int # SKU Service Type unique identifier. (e.g. 1)
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attachmentId" $attachmentId "scalar") (serialize-qp "skuServiceTypeId" $skuServiceTypeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/skuservicetypeattachment" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate SKU Service Attachment
#
# POST /api/catalog/pvt/skuservicetypeattachment
export def "catalog-pvt-skuservicetypeattachment post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  AttachmentId: int # Attachment ID. (e.g. 1)
  SkuServiceTypeId: int # An explanation about the purpose of this instance. (e.g. 1)
]: any -> record<AttachmentId: int, Id: int, SkuServiceTypeId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuservicetypeattachment")
  let body = {AttachmentId: $AttachmentId, SkuServiceTypeId: $SkuServiceTypeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Dissociate Attachment from SKU Service Type
#
# DELETE /api/catalog/pvt/skuservicetypeattachment/{skuServiceTypeAttachmentId}
export def "catalog-pvt-skuservicetypeattachment delete-by-skuServiceTypeAttachmentId" [
  skuServiceTypeAttachmentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservicetypeattachment/($skuServiceTypeAttachmentId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create SKU Service Value
#
# POST /api/catalog/pvt/skuservicevalue
export def "catalog-pvt-skuservicevalue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  Cost: float # SKU Service Value cost. (e.g. 10.5)
  Name: string # SKU Service Value name. Maximum of 100 characters. (e.g. Test ServiceValue API)
  SkuServiceTypeId: int # SKU Service Type ID. (e.g. 2)
  Value: float # SKU Service Value value. (e.g. 10.5)
]: any -> record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/skuservicevalue")
  let body = {Cost: $Cost, Name: $Name, SkuServiceTypeId: $SkuServiceTypeId, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete SKU Service Value
#
# DELETE /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
export def "catalog-pvt-skuservicevalue delete" [
  skuServiceValueId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservicevalue/($skuServiceValueId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Service Value
#
# GET /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
export def "catalog-pvt-skuservicevalue get" [
  skuServiceValueId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservicevalue/($skuServiceValueId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update SKU Service Value
#
# PUT /api/catalog/pvt/skuservicevalue/{skuServiceValueId}
export def "catalog-pvt-skuservicevalue put" [
  skuServiceValueId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  Cost: float # SKU Service Value cost. (e.g. 10.5)
  Name: string # SKU Service Value name. Maximum of 100 characters. (e.g. Test ServiceValue API)
  SkuServiceTypeId: int # SKU Service Type ID. (e.g. 2)
  Value: float # SKU Service Value value. (e.g. 10.5)
]: any -> record<Cost: float, Id: int, Name: string, SkuServiceTypeId: int, Value: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/skuservicevalue/($skuServiceValueId)")
  let body = {Cost: $Cost, Name: $Name, SkuServiceTypeId: $SkuServiceTypeId, Value: $Value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Specification
#
# POST /api/catalog/pvt/specification
@deprecated --flag Description
@deprecated --flag IsWizard
export def "catalog-pvt-specification post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --CategoryId: int # Category ID associated with this specification. (e.g. 1)
  --DefaultValue: string # Specification default value. (e.g. Cotton)
  --Description: string # DEPRECATED, nullable, e.g. Composition of the product.
  FieldGroupId: int # ID of the group of specifications that contains the new specification. (e.g. 22)
  FieldTypeId: int # Field Type ID can be `1 - Text`, `2 - Multi-Line Text`, `4 - Number`, `5 - Combo`, `6 - Radio`, `7 - Checkbox`, `8 - Indexed Text`, `9 - Indexed Multi-Line Text`. (e.g. 1)
  --IsActive: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification. (e.g. true)
  --IsFilter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar.  (e.g. false)
  --IsOnProductDetails: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page.  (e.g. true)
  --IsRequired: oneof<nothing, bool> # Makes the specification mandatory (`true`) or optional (`false`). (e.g. false)
  --IsSideMenuLinkActive: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar.  (e.g. false)
  --IsStockKeepingUnit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification. If `false`, it will be added as a product specification field. (e.g. false)
  --IsTopMenuLinkActive: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu.  (e.g. false)
  --IsWizard: oneof<nothing, bool> # DEPRECATED, nullable
  Name: string # Specification name. (e.g. Material)
  --Position: int # Store Framework - Deprecated. Legacy CMS Portal - This position number is used in ordering the specifications both in the navigation menu and in the specification listing on the product page.  (e.g. 1)
]: any -> record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/specification")
  let body = {CategoryId: $CategoryId, DefaultValue: $DefaultValue, Description: $Description, FieldGroupId: $FieldGroupId, FieldTypeId: $FieldTypeId, IsActive: $IsActive, IsFilter: $IsFilter, IsOnProductDetails: $IsOnProductDetails, IsRequired: $IsRequired, IsSideMenuLinkActive: $IsSideMenuLinkActive, IsStockKeepingUnit: $IsStockKeepingUnit, IsTopMenuLinkActive: $IsTopMenuLinkActive, IsWizard: $IsWizard, Name: $Name, Position: $Position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --skuId: int # SKU’s unique numerical identifier. (e.g. 1)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $skuId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/specification/nonstructured" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --skuId: int # SKU’s unique numerical identifier. (e.g. 1)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<Id: int, SkuId: int, SpecificationName: string, SpecificationValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $skuId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/specification/nonstructured" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Non Structured Specification
#
# DELETE /api/catalog/pvt/specification/nonstructured/{Id}
export def "catalog-pvt-specification-nonstructured delete-by-Id" [
  Id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/specification/nonstructured/($Id)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Non Structured Specification by ID
#
# GET /api/catalog/pvt/specification/nonstructured/{Id}
export def "catalog-pvt-specification-nonstructured get" [
  Id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<Id: int, SkuId: int, SpecificationName: string, SpecificationValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/specification/nonstructured/($Id)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Specification
#
# GET /api/catalog/pvt/specification/{specificationId}
export def "catalog-pvt-specification get" [
  specificationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/specification/($specificationId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Specification
#
# PUT /api/catalog/pvt/specification/{specificationId}
@deprecated --flag IsWizard
export def "catalog-pvt-specification put" [
  specificationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  CategoryId: int # Specification Category ID. (e.g. 0)
  DefaultValue: string # Specification Default Value. (e.g. Leather)
  Description: string # Specification Description. (e.g. Composition of the product.)
  FieldGroupId: int # Numerical ID of the Group of Specifications that contains the new Specification. (e.g. 0)
  FieldTypeId: int # Field Type can be `1 - Text`, `2 - Multi-Line Text`, `4 - Number`, `5 - Combo`, `6 - Radio`, `7 - Checkbox`, `8 - Indexed Text`, `9 - Indexed Multi-Line Text`. (e.g. 1)
  --IsActive: oneof<nothing, bool> # Defines if the Specification is active or not. (e.g. false)
  --IsFilter: oneof<nothing, bool> # Defines if the Specification can be used as a Filter. (e.g. false)
  --IsOnProductDetails: oneof<nothing, bool> # Defines if the Specification will be  shown on the Product screen in the specification area. (e.g. false)
  --IsRequired: oneof<nothing, bool> # Defines if the Specification is required or not. (e.g. false)
  --IsSideMenuLinkActive: oneof<nothing, bool> # Defines if the Specification is shown in the side menu. (e.g. false)
  --IsStockKeepingUnit: oneof<nothing, bool> # Defines if the Specification is applied to a specific SKU. (e.g. false)
  --IsTopMenuLinkActive: oneof<nothing, bool> # Defines if the Specification is shown in the main menu of the site. (e.g. false)
  --IsWizard: oneof<nothing, bool> # Deprecated (DEPRECATED, e.g. false)
  Name: string # Specification Name. (e.g. Material)
  Position: int # The current Specification's position in comparison to the other Specifications. (e.g. 1)
]: any -> record<CategoryId: int, DefaultValue: string, Description: string, FieldGroupId: int, FieldTypeId: int, Id: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/specification/($specificationId)")
  let body = {CategoryId: $CategoryId, DefaultValue: $DefaultValue, Description: $Description, FieldGroupId: $FieldGroupId, FieldTypeId: $FieldTypeId, IsActive: $IsActive, IsFilter: $IsFilter, IsOnProductDetails: $IsOnProductDetails, IsRequired: $IsRequired, IsSideMenuLinkActive: $IsSideMenuLinkActive, IsStockKeepingUnit: $IsStockKeepingUnit, IsTopMenuLinkActive: $IsTopMenuLinkActive, IsWizard: $IsWizard, Name: $Name, Position: $Position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Specification Group
#
# POST /api/catalog/pvt/specificationgroup
# operationId: SpecificationGroupInsert2
export def "catalog-pvt-specificationgroup SpecificationGroupInsert2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  CategoryId: int # Category ID. (format: int32)
  Name: string # Specification Group Name.
]: any -> record<CategoryId: int, Id: int, Name: string, Position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/specificationgroup")
  let body = {CategoryId: $CategoryId, Name: $Name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Specification Group
#
# PUT /api/catalog/pvt/specificationgroup/{groupId}
export def "catalog-pvt-specificationgroup put" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  CategoryId: int # Category ID where the Specification Group is contained. (e.g. 1)
  Id: int # Specification Group ID. (format: int32, e.g. 24)
  Name: string # Specification Group Name. (e.g. Sizes)
  Position: int # Specification Group Position. (e.g. 1)
]: any -> record<CategoryId: int, Id: int, Name: string, Position: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/specificationgroup/($groupId)")
  let body = {CategoryId: $CategoryId, Id: $Id, Name: $Name, Position: $Position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Specification Value
#
# POST /api/catalog/pvt/specificationvalue
@deprecated --flag Text
export def "catalog-pvt-specificationvalue post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  FieldId: int # Specification ID associated with this specification value. (e.g. 193)
  --IsActive: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification value. (e.g. true)
  Name: string # Specification Value name. (e.g. Metal)
  --Position: int # The position of the value to be shown on product registration page (`/admin/Site/Produto.aspx`). (e.g. 1)
  --Text: string # Specification Value Text. (DEPRECATED, nullable)
]: any -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/specificationvalue")
  let body = {FieldId: $FieldId, IsActive: $IsActive, Name: $Name, Position: $Position, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Specification Value
#
# GET /api/catalog/pvt/specificationvalue/{specificationValueId}
export def "catalog-pvt-specificationvalue get" [
  specificationValueId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/specificationvalue/($specificationValueId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Specification Value
#
# PUT /api/catalog/pvt/specificationvalue/{specificationValueId}
@deprecated --flag Text
export def "catalog-pvt-specificationvalue put" [
  specificationValueId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  FieldId: int # Specification ID associated with this specification value. (e.g. 193)
  --IsActive: oneof<nothing, bool> # Enable (`true`) or disable (`false`) specification value. (e.g. true)
  Name: string # Specification Value name. (e.g. Metal)
  --Position: int # The position of the value to be shown on product registration page (`/admin/Site/Produto.aspx`). (e.g. 1)
  --Text: string # Specification Value Text. (DEPRECATED, nullable)
]: any -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/specificationvalue/($specificationValueId)")
  let body = {FieldId: $FieldId, IsActive: $IsActive, Name: $Name, Position: $Position, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --refId: string # SKU Reference ID. (e.g. 1)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: float, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: string, WeightKg: float, Width: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refId" $refId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunit" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create SKU
#
# POST /api/catalog/pvt/stockkeepingunit
export def "catalog-pvt-stockkeepingunit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --ActivateIfPossible: oneof<nothing, bool> # When set to `true`, this attribute will automatically update the SKU as active once associated with an image or an active component. (e.g. true)
  --CommercialConditionId: int # Used to define SKU specific promotions or installment rules. In case of no specific condition, use `1` (default value). This field does not accept `0`. Find out more by reading [Registering a commercial condition](https://help.vtex.com/tutorial/registering-a-commercial-condition--tutorials_445). (e.g. 1)
  --CreationDate: string # Date and time of the SKU's creation. (e.g. 2020-01-25T15:51:29.2614605)
  --CubicWeight: float # [Cubic weight](https://help.vtex.com/en/tutorial/understanding-the-cubic-weight-factor--tutorials_128). (e.g. 0.1667)
  --Ean: string # EAN code. Required only if `RefId` is not informed, but can be used alongside `RefId` as well. (e.g. 8949461894984)
  --EstimatedDateArrival: string # To add the product as pre-sale, enter the product estimated arrival date in [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) format. You must take into consideration both the launch date and the freight calculation for the arrival date. (nullable)
  --Height: float # SKU real height. (e.g. 1)
  --Id: int # SKU unique identifier. If not informed, it will be automatically generated by VTEX. (e.g. 1)
  --IsActive: oneof<nothing, bool> # Shows if the SKU is active (`true`) or not (`false`). (e.g. false)
  --IsKit: oneof<nothing, bool> # Flag to set whether the product SKU is made up of one or more SKUs, thereby becoming a bundle. Must be enabled if you are adding a bundle. Once activated, the flag cannot be reverted. (e.g. false)
  --KitItensSellApart: oneof<nothing, bool> # Defines if Kit components can be sold apart. (e.g. false)
  --Length: float # SKU real length. (e.g. 1)
  --ManufacturerCode: string # Provided by the manufacturers to identify their product. This field should be filled in if the product has a specific manufacturer’s code. (e.g. 123)
  --MeasurementUnit: string # Used only in cases when you need to convert the unit of measure for sale. If a product is sold in boxes for example, but customers want to buy per square meter (m²). In common cases, use `'un'`. (e.g. un)
  --ModalType: string # Links an unusual type of SKU to a carrier specialized in delivering it. This field should be filled in with the name of the modal (e.g. "Chemicals" or "Refrigerated products"). To learn more about this feature, read our articles [How the modal works](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125) and [Setting up modal for carriers](https://help.vtex.com/en/tutorial/configure-modal--3jhLqxuPhuiq24UoykCcqy). (nullable)
  Name: string # SKU name, meaning the variation of the previously added product. For example: **Product** - _Fridge_, **SKU** - _110V_. (e.g. Size 10)
  PackagedHeight: float # Height used for shipping calculation. (e.g. 10)
  PackagedLength: float # Length used for shipping calculation. (e.g. 10)
  PackagedWeightKg: int # Weight used for shipping calculation, in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 10)
  PackagedWidth: float # Width used for shipping calculation. (e.g. 10)
  ProductId: int # ID of the Product associated with this SKU. (e.g. 42)
  --RefId: string # Reference code used internally for organizational purposes. Must be unique. Required only if `Ean` is not informed, but can be used alongside `Ean` as well. (e.g. B096QW8Y8Z)
  --RewardValue: float # Credit that the customer receives when finalizing an order of one specific SKU unit. By filling this field out with `1`, the customer gets U$ 1 credit on the site. (e.g. 1)
  --UnitMultiplier: float # This is the multiple number of SKU. If the Multiplier is 5.0000, the product can be added in multiple quantities of 5, 10, 15, 20, onward. (e.g. 2)
  --Videos: list # Videos URLs (e.g. [https://www.youtube.com/])
  --WeightKg: float # Weight of the SKU in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 1)
  --Width: float # SKU real width. (e.g. 1)
]: any -> record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, Ean: string, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunit")
  let body = {ActivateIfPossible: $ActivateIfPossible, CommercialConditionId: $CommercialConditionId, CreationDate: $CreationDate, CubicWeight: $CubicWeight, Ean: $Ean, EstimatedDateArrival: $EstimatedDateArrival, Height: $Height, Id: $Id, IsActive: $IsActive, IsKit: $IsKit, KitItensSellApart: $KitItensSellApart, Length: $Length, ManufacturerCode: $ManufacturerCode, MeasurementUnit: $MeasurementUnit, ModalType: $ModalType, Name: $Name, PackagedHeight: $PackagedHeight, PackagedLength: $PackagedLength, PackagedWeightKg: $PackagedWeightKg, PackagedWidth: $PackagedWidth, ProductId: $ProductId, RefId: $RefId, RewardValue: $RewardValue, UnitMultiplier: $UnitMultiplier, Videos: $Videos, WeightKg: $WeightKg, Width: $Width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy Files from an SKU to another SKU
#
# PUT /api/catalog/pvt/stockkeepingunit/copy/{skuIdfrom}/{skuIdto}/file/
export def "catalog-pvt-stockkeepingunit-copy-file put" [
  skuIdfrom: int
  skuIdto: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/copy/($skuIdfrom)/($skuIdto)/file/")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disassociate SKU File
#
# DELETE /api/catalog/pvt/stockkeepingunit/disassociate/{skuId}/file/{skuFileId}
export def "catalog-pvt-stockkeepingunit-disassociate-file delete" [
  skuId: int
  skuFileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/disassociate/($skuId)/file/($skuFileId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}
# operationId: Sku
export def "catalog-pvt-stockkeepingunit Sku" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update SKU
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}
export def "catalog-pvt-stockkeepingunit put" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --ActivateIfPossible: oneof<nothing, bool> # When set to `true`, this attribute will automatically update the SKU as active once associated with an image or an active component. (e.g. false)
  --CommercialConditionId: int # Used to define SKU specific promotions or installment rules. In case of no specific condition, use `1` (default value). This field does not accept `0`. Find out more by reading [Registering a commercial condition](https://help.vtex.com/tutorial/registering-a-commercial-condition--tutorials_445). (e.g. 1)
  --CreationDate: string # Date and time of the SKU's creation. (e.g. 2020-01-25T15:51:00)
  --CubicWeight: float # [Cubic weight](https://help.vtex.com/en/tutorial/understanding-the-cubic-weight-factor--tutorials_128). (e.g. 0.1667)
  --EstimatedDateArrival: string # To add the product as pre-sale, enter the product estimated arrival date in [ISO-8601](https://en.wikipedia.org/wiki/ISO_8601) format. You must take into consideration both the launch date and the freight calculation for the arrival date. (nullable)
  --Height: float # SKU real height. (e.g. 1)
  --IsActive: oneof<nothing, bool> # Shows if the SKU is active (`true`) or not (`false`). (e.g. false)
  --IsKit: oneof<nothing, bool> # Flag to set whether the product SKU is made up of one or more SKUs, thereby becoming a bundle. Must be enabled if you are adding a bundle. Once activated, the flag cannot be reverted. (e.g. false)
  --KitItensSellApart: oneof<nothing, bool> # Defines if Kit components can be sold apart. (e.g. false)
  --Length: float # SKU real length. (e.g. 1)
  --ManufacturerCode: string # Provided by the manufacturers to identify their product. This field should be filled in if the product has a specific manufacturer’s code. (e.g. 123)
  --MeasurementUnit: string # Used only in cases when you need to convert the unit of measure for sale. If a product is sold in boxes for example, but customers want to buy per square meter (m²). In common cases, use `'un'`. (e.g. un)
  --ModalType: string # Links an unusual type of SKU to a carrier specialized in delivering it. This field should be filled in with the name of the modal (e.g. "Chemicals" or "Refrigerated products"). To learn more about this feature, read our articles [How the modal works](https://help.vtex.com/en/tutorial/how-does-the-modal-work--tutorials_125) and [Setting up modal for carriers](https://help.vtex.com/en/tutorial/configure-modal--3jhLqxuPhuiq24UoykCcqy). (nullable)
  Name: string # SKU name, meaning the variation of the previously added product. For example: **Product** - _Fridge_, **SKU** - _110V_. (e.g. Size 10)
  PackagedHeight: float # Height used for shipping calculation. (e.g. 10)
  PackagedLength: float # Length used for shipping calculation. (e.g. 10)
  PackagedWeightKg: int # Weight used for shipping calculation, in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 10)
  PackagedWidth: float # Width used for shipping calculation. (e.g. 10)
  ProductId: int # ID of the Product associated with this SKU. (e.g. 42)
  --RefId: string # Reference code used internally for organizational purposes. Must be unique. It is not required only if EAN code already exists. If not, this field must be provided. (e.g. B096QW8Y8Z)
  --RewardValue: float # Credit that the customer receives when finalizing an order of one specific SKU unit. By filling this field out with `1`, the customer gets U$ 1 credit on the site. (e.g. 1)
  --UnitMultiplier: float # This is the multiple number of SKU. If the Multiplier is 5.0000, the product can be added in multiple quantities of 5, 10, 15, 20, onward. (e.g. 2)
  --Videos: list # Videos URLs (e.g. [https://www.youtube.com/])
  --WeightKg: float # Weight of the SKU in the measurement [configured in the store](https://help.vtex.com/en/tutorial/filling-in-system-settings--tutorials_269), which by default is in grams. (e.g. 1)
  --Width: float # SKU real width. (e.g. 1)
]: any -> record<ActivateIfPossible: bool, CommercialConditionId: int, CreationDate: string, CubicWeight: float, EstimatedDateArrival: string, Height: float, Id: int, IsActive: bool, IsKit: bool, KitItensSellApart: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, Name: string, PackagedHeight: float, PackagedLength: float, PackagedWeightKg: int, PackagedWidth: float, ProductId: int, RefId: string, RewardValue: float, UnitMultiplier: float, Videos: list<string>, WeightKg: float, Width: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)")
  let body = {ActivateIfPossible: $ActivateIfPossible, CommercialConditionId: $CommercialConditionId, CreationDate: $CreationDate, CubicWeight: $CubicWeight, EstimatedDateArrival: $EstimatedDateArrival, Height: $Height, IsActive: $IsActive, IsKit: $IsKit, KitItensSellApart: $KitItensSellApart, Length: $Length, ManufacturerCode: $ManufacturerCode, MeasurementUnit: $MeasurementUnit, ModalType: $ModalType, Name: $Name, PackagedHeight: $PackagedHeight, PackagedLength: $PackagedLength, PackagedWeightKg: $PackagedWeightKg, PackagedWidth: $PackagedWidth, ProductId: $ProductId, RefId: $RefId, RewardValue: $RewardValue, UnitMultiplier: $UnitMultiplier, Videos: $Videos, WeightKg: $WeightKg, Width: $Width} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get SKU Attachments by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/attachment
export def "catalog-pvt-stockkeepingunit-attachment get" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<AttachmentId: int, Id: int, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/attachment")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Complement by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/complement
# operationId: GetSKUComplementbySKUID
export def "catalog-pvt-stockkeepingunit-complement GetSKUComplementbySKUID" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/complement")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Complements by Complement Type ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/complement/{complementTypeId}
# operationId: GetSKUComplementsbyComplementTypeID
export def "catalog-pvt-stockkeepingunit-complement GetSKUComplementsbyComplementTypeID" [
  skuId: int
  complementTypeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ComplementTypeId: int, Id: int, ParentSkuId: int, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/complement/($complementTypeId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete all SKU EAN values
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/ean
export def "catalog-pvt-stockkeepingunit-ean delete-by-skuId" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/ean")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get EAN by SKU ID
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/ean
export def "catalog-pvt-stockkeepingunit-ean get" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/ean")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete SKU EAN
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/ean/{ean}
export def "catalog-pvt-stockkeepingunit-ean delete-by-skuId-ean" [
  skuId: int
  ean: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/ean/($ean)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create SKU EAN
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/ean/{ean}
export def "catalog-pvt-stockkeepingunit-ean post" [
  skuId: int
  ean: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/ean/($ean)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete All SKU Files
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/file
export def "catalog-pvt-stockkeepingunit-file delete-by-skuId" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/file")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Files
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/file
export def "catalog-pvt-stockkeepingunit-file get" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ArchiveId: int, Id: int, IsMain: bool, Label: string, Name: string, SkuId: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/file")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create SKU File
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/file
export def "catalog-pvt-stockkeepingunit-file post" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --IsMain: oneof<nothing, bool> # Defines if the Image is the main image of the SKU. (e.g. true)
  --Label: string # SKU image label. (e.g. Main)
  Name: string # SKU image name. (e.g. Nike-Red-Janoski-1)
  --Text: string # General text of the image. (nullable, e.g. Nike-Red-Janoski)
  Url: string # External Image's URL.  The URL must start with the protocol identifier (`http://` or `https://`) and end with the file extension (`.jpg`, `.png` or `.gif`). (e.g. https://m.media-amazon.com/images/I/610G2-sJx5L._AC_UX695_.jpg)
]: any -> record<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/file")
  let body = {IsMain: $IsMain, Label: $Label, Name: $Name, Text: $Text, Url: $Url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete SKU Image File
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/file/{skuFileId}
export def "catalog-pvt-stockkeepingunit-file delete-by-skuId-skuFileId" [
  skuId: int
  skuFileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/file/($skuFileId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update SKU File
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/file/{skuFileId}
export def "catalog-pvt-stockkeepingunit-file put" [
  skuId: int
  skuFileId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --IsMain: oneof<nothing, bool> # Defines if the Image is the main image of the SKU. (e.g. true)
  --Label: string # SKU image label. (e.g. Main)
  Name: string # SKU image name. (e.g. Nike-Red-Janoski-1)
  --Text: string # General text of the image. (nullable, e.g. Nike-Red-Janoski)
  Url: string # External Image's URL.  The URL must start with the protocol identifier (`http://` or `https://`) and end with the file extension (`.jpg`, `.png` or `.gif`). (e.g. https://m.media-amazon.com/images/I/610G2-sJx5L._AC_UX695_.jpg)
]: any -> record<ArchiveId: int, Id: int, IsMain: bool, Label: string, SkuId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/file/($skuFileId)")
  let body = {IsMain: $IsMain, Label: $Label, Name: $Name, Text: $Text, Url: $Url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete all SKU Specifications
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "catalog-pvt-stockkeepingunit-specification delete-by-skuId" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/specification")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Specifications
#
# GET /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "catalog-pvt-stockkeepingunit-specification get" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/specification")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate SKU Specification
#
# POST /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "catalog-pvt-stockkeepingunit-specification post" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  FieldId: int # Specification ID. (e.g. 13)
  --FieldValueId: int # Specification Value ID. Required only for `FieldTypeId` as `5`, `6` and `7`. (e.g. 101)
]: any -> record<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/specification")
  let body = {FieldId: $FieldId, FieldValueId: $FieldValueId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update SKU Specification
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/specification
export def "catalog-pvt-stockkeepingunit-specification put" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  FieldId: int # Specification unique identifier. This field cannot be updated. (e.g. 32)
  FieldValueId: int # Specification value unique identifier. This field can only be updated with other values of the same `FieldId`. (e.g. 131)
  Id: int # Specification and SKU association unique identifier. This field cannot be updated. (e.g. 65)
  --SkuId: int # SKU unique identifier. This field cannot be updated. (e.g. 21)
  --Text: string # Specification Value Name. This field is automatically updated if the `FieldValue` is updated. Otherwise, the value cannot be modified. (e.g. Red)
]: any -> table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/specification")
  let body = {FieldId: $FieldId, FieldValueId: $FieldValueId, Id: $Id, SkuId: $SkuId, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete SKU Specification
#
# DELETE /api/catalog/pvt/stockkeepingunit/{skuId}/specification/{specificationId}
export def "catalog-pvt-stockkeepingunit-specification delete-by-skuId-specificationId" [
  skuId: int
  specificationId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/specification/($specificationId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate SKU specification using specification name and group name
#
# PUT /api/catalog/pvt/stockkeepingunit/{skuId}/specificationvalue
export def "catalog-pvt-stockkeepingunit-specificationvalue put" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  FieldName: string # Specification name. (e.g. Material)
  FieldValues: list # Array of specification values. SKU Specifications must contain only one value. (e.g. [M])
  GroupName: string # Group name. (e.g. Composition)
  --RootLevelSpecification: oneof<nothing, bool> # Root level specification. (e.g. true)
]: any -> table<FieldId: int, FieldValueId: int, Id: int, SkuId: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunit/($skuId)/specificationvalue")
  let body = {FieldName: $FieldName, FieldValues: $FieldValues, GroupName: $GroupName, RootLevelSpecification: $RootLevelSpecification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --skuId: int # SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --parentSkuId: int # Parent SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $skuId "scalar") (serialize-qp "parentSkuId" $parentSkuId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunitkit" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --skuId: int # SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --parentSkuId: int # Parent SKU’s unique numerical identifier. (format: int32, e.g. 1)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "skuId" $skuId "scalar") (serialize-qp "parentSkuId" $parentSkuId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunitkit" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create SKU Kit
#
# POST /api/catalog/pvt/stockkeepingunitkit
export def "catalog-pvt-stockkeepingunitkit post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  Quantity: int # Component quantity. (e.g. 3)
  StockKeepingUnitId: int # Component SKU ID. (e.g. 31018374)
  StockKeepingUnitParent: int # SKU ID of the SKU Kit. (e.g. 31018373)
  UnitPrice: float # Component price per unit. (e.g. 15.5)
]: any -> record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/stockkeepingunitkit")
  let body = {Quantity: $Quantity, StockKeepingUnitId: $StockKeepingUnitId, StockKeepingUnitParent: $StockKeepingUnitParent, UnitPrice: $UnitPrice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete SKU Kit by KitId
#
# DELETE /api/catalog/pvt/stockkeepingunitkit/{kitId}
export def "catalog-pvt-stockkeepingunitkit delete-by-kitId" [
  kitId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunitkit/($kitId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU Kit
#
# GET /api/catalog/pvt/stockkeepingunitkit/{kitId}
export def "catalog-pvt-stockkeepingunitkit get" [
  kitId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, Quantity: int, StockKeepingUnitId: int, StockKeepingUnitParent: int, UnitPrice: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/stockkeepingunitkit/($kitId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Subcollection
#
# POST /api/catalog/pvt/subcollection
export def "catalog-pvt-subcollection post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  CollectionId: int # SubCollection ID. (e.g. 17)
  Name: string # SubCollection Name. (e.g. group 1)
  --PreSale: oneof<nothing, bool> # Defines PreSale date. (e.g. false)
  --Release: oneof<nothing, bool> # Defines Release date. (e.g. false)
  Type: string # Either `“Exclusive”` (all the products contained in it will not be used) or `“Inclusive”` (all the products contained in it will be used). (e.g. Inclusive)
]: any -> record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/subcollection")
  let body = {CollectionId: $CollectionId, Name: $Name, PreSale: $PreSale, Release: $Release, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}
export def "catalog-pvt-subcollection delete" [
  subCollectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Subcollection
#
# GET /api/catalog/pvt/subcollection/{subCollectionId}
export def "catalog-pvt-subcollection get" [
  subCollectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Subcollection
#
# PUT /api/catalog/pvt/subcollection/{subCollectionId}
export def "catalog-pvt-subcollection put" [
  subCollectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  CollectionId: int # Collection ID. (e.g. 17)
  Name: string # Subcollection Name. (e.g. group 1)
  --PreSale: oneof<nothing, bool> # Defines PreSale date. (e.g. false)
  --Release: oneof<nothing, bool> # Defines Release date. (e.g. false)
  Type: string # Either `“Exclusive”` (all the products contained in it will not be used) or `“Inclusive”` (all the products contained in it will be used). (e.g. Inclusive)
]: any -> record<CollectionId: int, Id: int, Name: string, PreSale: bool, Release: bool, Type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)")
  let body = {CollectionId: $CollectionId, Name: $Name, PreSale: $PreSale, Release: $Release, Type: $Type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Associate Brand to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/brand
export def "catalog-pvt-subcollection-brand post" [
  subCollectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  BrandId: int # Unique identifier of a Brand. (e.g. 2000000)
]: any -> record<BrandId: int, SubCollectionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)/brand")
  let body = {BrandId: $BrandId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Brand from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/brand/{brandId}
export def "catalog-pvt-subcollection-brand delete-by-subCollectionId-brandId" [
  subCollectionId: int
  brandId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)/brand/($brandId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Category from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/brand/{categoryId}
export def "catalog-pvt-subcollection-brand delete-by-subCollectionId-categoryId" [
  subCollectionId: int
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)/brand/($categoryId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate Category to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/category
export def "catalog-pvt-subcollection-category post" [
  subCollectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  CategoryId: int # Unique identifier of a Category. (e.g. 0)
]: any -> record<CategoryId: int, SubCollectionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)/category")
  let body = {CategoryId: $CategoryId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add SKU to Subcollection
#
# POST /api/catalog/pvt/subcollection/{subCollectionId}/stockkeepingunit
export def "catalog-pvt-subcollection-stockkeepingunit post" [
  subCollectionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  SkuId: int # Unique identifier of an SKU. (e.g. 1)
]: any -> record<SkuId: int, SubCollectionId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)/stockkeepingunit")
  let body = {SkuId: $SkuId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete SKU from Subcollection
#
# DELETE /api/catalog/pvt/subcollection/{subCollectionId}/stockkeepingunit/{skuId}
export def "catalog-pvt-subcollection-stockkeepingunit delete" [
  subCollectionId: int
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/subcollection/($subCollectionId)/stockkeepingunit/($skuId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Supplier
#
# POST /api/catalog/pvt/supplier
export def "catalog-pvt-supplier post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  CellPhone: string # Supplier Cellphone. (e.g. 4444444444)
  Cnpj: string # Corporate legal ID. (e.g. 33304981001272)
  CorporateName: string # Supplier Corporate Name. (e.g. TopStore)
  CorportePhone: string # Supplier Corporate Phone. (e.g. 5555555555)
  Email: string # Supplier email. (e.g. email@email.com)
  --IsActive: oneof<nothing, bool> # Defines if the Supplier is active (`true`) or not (`false`). (e.g. false)
  Name: string # Supplier Name. (e.g. Supplier)
  Phone: string # Supplier Phone. (e.g. 3333333333)
  StateInscription: string # State Inscription. (e.g. 123456)
]: any -> record<CellPhone: string, Cnpj: string, CorporateName: string, CorportePhone: string, Email: string, Id: int, IsActive: bool, Name: string, Phone: string, StateInscription: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog/pvt/supplier")
  let body = {CellPhone: $CellPhone, Cnpj: $Cnpj, CorporateName: $CorporateName, CorportePhone: $CorportePhone, Email: $Email, IsActive: $IsActive, Name: $Name, Phone: $Phone, StateInscription: $StateInscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Supplier
#
# DELETE /api/catalog/pvt/supplier/{supplierId}
export def "catalog-pvt-supplier delete" [
  supplierId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/supplier/($supplierId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Supplier
#
# PUT /api/catalog/pvt/supplier/{supplierId}
export def "catalog-pvt-supplier put" [
  supplierId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  CellPhone: string # Supplier Cellphone. (e.g. 4444444444)
  Cnpj: string # Corporate legal ID. (e.g. 33304981001272)
  CorporateName: string # Supplier Corporate Name. (e.g. TopStore)
  CorportePhone: string # Supplier Corporate Phone. (e.g. 5555555555)
  Email: string # Supplier email. (e.g. email@email.com)
  --IsActive: oneof<nothing, bool> # Defines if the Supplier is active (`true`) or not (`false`). (e.g. false)
  Name: string # Supplier Name. (e.g. Supplier)
  Phone: string # Supplier Phone. (e.g. 3333333333)
  StateInscription: string # State Inscription. (e.g. 123456)
]: any -> record<CellPhone: string, Cnpj: string, CorporateName: string, CorportePhone: string, Email: string, Id: int, IsActive: bool, Name: string, Phone: string, StateInscription: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog/pvt/supplier/($supplierId)")
  let body = {CellPhone: $CellPhone, Cnpj: $Cnpj, CorporateName: $CorporateName, CorportePhone: $CorportePhone, Email: $Email, IsActive: $IsActive, Name: $Name, Phone: $Phone, StateInscription: $StateInscription} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Category Tree
#
# GET /api/catalog_system/pub/category/tree/{categoryLevels}
# operationId: CategoryTree
export def "catalog-system-pub-category-tree CategoryTree" [
  categoryLevels: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<MetaTagDescription: string, Title: string, children: list<record>, hasChildren: bool, id: int, name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/category/tree/($categoryLevels)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product's SKUs by Product ID
#
# GET /api/catalog_system/pub/products/variations/{productId}
# operationId: ProductVariations
export def "catalog-system-pub-products-variations ProductVariations" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<available: bool, dimensions: list<string>, dimensionsInputType: record, dimensionsMap: record, displayMode: string, name: string, productId: int, salesChannel: string, skus: table<available: bool, availablequantity: int, bestPrice: int, bestPriceFormated: string, cacheVersionUsedToCallCheckout: string, dimensions: record, image: string, installments: int, installmentsInsterestRate: int, installmentsValue: int, listPrice: int, listPriceFormated: string, measures: record, rewardValue: int, sellerId: string, sku: int, skuname: string, spotPrice: int, taxAsInt: int, taxFormated: string, unitMultiplier: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/products/variations/($productId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Sales Channel by ID
#
# GET /api/catalog_system/pub/saleschannel/{salesChannelId}
# operationId: SalesChannelbyId
export def "catalog-system-pub-saleschannel SalesChannelbyId" [
  salesChannelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ConditionRule: string, CountryCode: string, CultureInfo: string, CurrencyCode: string, CurrencyDecimalDigits: int, CurrencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, CurrencyLocale: int, CurrencySymbol: string, Id: int, IsActive: bool, Name: string, Origin: string, Position: int, ProductClusterId: int, TimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/saleschannel/($salesChannelId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve SKU ID list by Reference ID list
#
# POST /api/catalog_system/pub/sku/stockkeepingunitidsbyrefids
# operationId: SkuIdlistbyRefIdlist
export def "catalog-system-pub-sku-stockkeepingunitidsbyrefids SkuIdlistbyRefIdlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pub/sku/stockkeepingunitidsbyrefids")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Specifications By Category ID
#
# GET /api/catalog_system/pub/specification/field/listByCategoryId/{categoryId}
# operationId: SpecificationsByCategoryId
export def "catalog-system-pub-specification-field-list-by-category-id SpecificationsByCategoryId" [
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CategoryId: int, FieldId: int, IsActive: bool, IsStockKeepingUnit: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/specification/field/listByCategoryId/($categoryId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Specifications Tree By Category ID
#
# GET /api/catalog_system/pub/specification/field/listTreeByCategoryId/{categoryId}
# operationId: SpecificationsTreeByCategoryId
export def "catalog-system-pub-specification-field-list-tree-by-category-id SpecificationsTreeByCategoryId" [
  categoryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CategoryId: int, FieldId: int, IsActive: bool, IsStockKeepingUnit: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/specification/field/listTreeByCategoryId/($categoryId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Specification Field
#
# GET /api/catalog_system/pub/specification/fieldGet/{fieldId}
# operationId: SpecificationsField
export def "catalog-system-pub-specification-field-get SpecificationsField" [
  fieldId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<DefaultValue: string, Description: string, FieldGroupId: int, FieldGroupName: string, FieldId: int, FieldTypeId: int, FieldTypeName: string, FieldValueId: int, IsActive: bool, IsFilter: bool, IsOnProductDetails: bool, IsRequired: bool, IsSideMenuLinkActive: bool, IsStockKeepingUnit: bool, IsTopMenuLinkActive: bool, IsWizard: bool, Name: string, Position: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/specification/fieldGet/($fieldId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Specification Values By Field ID
#
# GET /api/catalog_system/pub/specification/fieldvalue/{fieldId}
# operationId: SpecificationsValuesByFieldId
export def "catalog-system-pub-specification-fieldvalue SpecificationsValuesByFieldId" [
  fieldId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<FieldValueId: int, IsActive: bool, Position: int, Value: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/specification/fieldvalue/($fieldId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Specification Group
#
# GET /api/catalog_system/pub/specification/groupGet/{groupId}
# operationId: SpecificationsGroupGet
export def "catalog-system-pub-specification-group-get SpecificationsGroupGet" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<CategoryId: int, Id: int, Name: string, Position: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pub/specification/groupGet/($groupId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Brand List
#
# GET /api/catalog_system/pvt/brand/list
# operationId: BrandList
export def "catalog-system-pvt-brand-list BrandList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/brand/list")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Brand List Per Page
#
# GET /api/catalog_system/pvt/brand/pagedlist
# operationId: BrandListPerPage
export def "catalog-system-pvt-brand-pagedlist BrandListPerPage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # Quantity of brands per page. (e.g. 5)
  --page: int # Page number of the brand list. (e.g. 1)
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<items: table<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string>, paging: record<page: int, pages: int, perPage: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/brand/pagedlist" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Brand
#
# GET /api/catalog_system/pvt/brand/{brandId}
# operationId: Brand
export def "catalog-system-pvt-brand Brand" [
  brandId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<id: int, imageUrl: string, isActive: bool, metaTagDescription: string, name: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/brand/($brandId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get All Collections
#
# GET /api/catalog_system/pvt/collection/search
# operationId: GET-AllCollections
export def "catalog-system-pvt-collection-search GET-AllCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (e.g. 2)
  --pageSize: int # Number of the items of the page. (e.g. 15)
  --orderByAsc: oneof<nothing, bool> # Defines if the items of the page are in ascending order. (e.g. true)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "orderByAsc" $orderByAsc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/collection/search" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Collections by search terms
#
# GET /api/catalog_system/pvt/collection/search/{searchTerms}
# operationId: GET-Collectionsbyseachterms
export def "catalog-system-pvt-collection-search GET-Collectionsbyseachterms" [
  searchTerms: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number. (e.g. 2)
  --pageSize: int # Number of the items of the page. (e.g. 15)
  --orderByAsc: oneof<nothing, bool> # Defines if the items of the page are in ascending order. (e.g. true)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "orderByAsc" $orderByAsc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog_system/pvt/collection/search/($searchTerms)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all commercial conditions
#
# GET /api/catalog_system/pvt/commercialcondition/list
# operationId: GetAllCommercialConditions
export def "catalog-system-pvt-commercialcondition-list GetAllCommercialConditions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<Id: int, IsDefault: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/commercialcondition/list")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get commercial condition
#
# GET /api/catalog_system/pvt/commercialcondition/{commercialConditionId}
# operationId: GetCommercialConditions
export def "catalog-system-pvt-commercialcondition GetCommercialConditions" [
  commercialConditionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<Id: int, IsDefault: bool, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/commercialcondition/($commercialConditionId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Indexed Information
#
# GET /api/catalog_system/pvt/products/GetIndexedInfo/{productId}
# operationId: IndexedInfo
export def "catalog-system-pvt-products-get-indexed-info IndexedInfo" [
  productId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/products/GetIndexedInfo/($productId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product and SKU IDs
#
# GET /api/catalog_system/pvt/products/GetProductAndSkuIds
# operationId: ProductAndSkuIds
export def "catalog-system-pvt-products-get-product-and-sku-ids ProductAndSkuIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categoryId: int # ID of the category from which you need to retrieve Products and SKUs. (format: int32, e.g. 1)
  --qp-from: int # Insert the ID that will start the request result. (format: int32, e.g. 1)
  --qp-to: int # Insert the ID that will end the request result. (format: int32, e.g. 10)
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<data: record<Product_ID: list<any>>, range: record<from: int, to: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryId" $categoryId "scalar") (serialize-qp "_from" $qp_from "scalar") (serialize-qp "_to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/products/GetProductAndSkuIds" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product and its general context
#
# GET /api/catalog_system/pvt/products/productget/{productId}
# operationId: ProductandTradePolicy
export def "catalog-system-pvt-products-productget ProductandTradePolicy" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, ListStoreId: list<any>, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/products/productget/($productId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product by RefId
#
# GET /api/catalog_system/pvt/products/productgetbyrefid/{refId}
# operationId: ProductbyRefId
export def "catalog-system-pvt-products-productgetbyrefid ProductbyRefId" [
  refId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AdWordsRemarketingCode: string, BrandId: int, CategoryId: int, DepartmentId: int, Description: string, DescriptionShort: string, Id: int, IsActive: bool, IsVisible: bool, KeyWords: string, LinkId: string, ListStoreId: list<int>, LomadeeCampaignCode: string, MetaTagDescription: string, Name: string, RefId: string, ReleaseDate: string, ShowWithoutStock: bool, SupplierId: int, TaxCode: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/products/productgetbyrefid/($refId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Product Specification by Product ID
#
# GET /api/catalog_system/pvt/products/{productId}/specification
# operationId: GetProductSpecification
export def "catalog-system-pvt-products-specification GetProductSpecification" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<Id: int, Name: string, Value: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/products/($productId)/specification")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Product Specification by Product ID
#
# POST /api/catalog_system/pvt/products/{productId}/specification
# operationId: UpdateProductSpecification
export def "catalog-system-pvt-products-specification UpdateProductSpecification" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/products/($productId)/specification")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Sales Channel List
#
# GET /api/catalog_system/pvt/saleschannel/list
# operationId: SalesChannelList
export def "catalog-system-pvt-saleschannel-list SalesChannelList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ConditionRule: string, CountryCode: string, CultureInfo: string, CurrencyCode: string, CurrencyDecimalDigits: int, CurrencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, CurrencyLocale: int, CurrencySymbol: string, Id: int, IsActive: bool, Name: string, Origin: string, Position: int, ProductClusterId: int, TimeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/saleschannel/list")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Seller
#
# POST /api/catalog_system/pvt/seller
# operationId: CreateSeller
export def "catalog-system-pvt-seller CreateSeller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  ArchiveId: int # Seller archive ID. (e.g. 1)
  CNPJ: string # Company registration number. (e.g. 12035072751)
  CSCIdentification: string # CSC identification. (e.g. pedrostore)
  CatalogSystemEndpoint: string # URL of the endpoint of the seller's catalog. This field will only be displayed if the seller type is VTEX Store. The field format will be as follows: `http://{sellerName}.vtexcommercestable.com.br/api/catalog_system/`. (e.g. http://pedrostore.vtexcommercestable.com.br/api/catalog_system/)
  --CategoryCommissionPercentage: string # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. [{"CategoryId":14,"ProductCommission":15.0,"FreightCommission":0.0}])
  DeliveryPolicy: string # Text describing the delivery policy previously agreed between the marketplace and the seller. (e.g. Delivery policy text)
  Description: string # Text describing the seller with a marketing tone. You can display this text in the marketplace window display by [customizing the CMS](https://help.vtex.com/en/tutorial/list-of-controls-for-templates--tutorials_563). (e.g. Brief description)
  Email: string # Email of the admin responsible for the seller. (e.g. breno@breno.com)
  ExchangeReturnPolicy: string # Text describing the exchange and return policy previously agreed between the marketplace and the seller. (e.g. Exchange return policy text)
  FreightCommissionPercentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  FulfillmentEndpoint: string # URL of the endpoint for fulfillment of seller's orders, which the marketplace will use to communicate with the seller. This field applies to all sellers, regardless of their type. However, for `VTEX Stores`, you don’t need to fill it in because the system will do that automatically. You can edit this field once the seller has been successfully added. (e.g. http://pedrostore.vtexcommercestable.com.br/api/fulfillment?affiliateid=LDB&sc=1)
  FulfillmentSellerId: int # Identification code of the seller responsible for fulfilling the order. This is an optional field used when a seller sells SKUs from another seller. If the seller sells their own SKUs, it must be left blank. (e.g. 1)
  --IsActive: oneof<nothing, bool> # If the selle is active (`true`) or not (`false`). (e.g. true)
  --IsBetterScope: oneof<nothing, bool> # Indicates whether it is a [comprehensive seller](https://help.vtex.com/en/tutorial/comprehensive-seller--5Qn4O2GpjUIzWTPpvLUfkI). (e.g. false)
  --MerchantName: string # Name of the marketplace, used to guide payments. This field should be nulled if the marketplace is responsible for processing payments. Check out our [Split Payment](https://help.vtex.com/en/tutorial/split-payment--6k5JidhYRUxileNolY2VLx) article to know more. (e.g. pedrostore)
  Name: string # Name of the account in the seller's environment. You can find it on **Account settings > Account > Account Name**). Applicable only if the seller uses their own payment method. (e.g. My pedrostore)
  Password: string # Seller password. (e.g. passoword)
  ProductCommissionPercentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  SecutityPrivacyPolicy: string # Text describing the security policy previously agreed between the marketplace and the seller. (e.g. Secutity privacy policy text)
  SellerId: string # Code used to identify the seller. It is assigned by the marketplace. We recommend filling it in with the seller's account name. (e.g. pedrostore)
  SellerType: int # Seller type. (e.g. 1)
  --TrustPolicy: string # Seller trust policy. The default value is `'Default'`, but if your store is a B2B marketplace and you want to share the customers'emails with the sellers you need to set this field as `'AllowEmailSharing'`. (e.g. Default)
  UrlLogo: string # Seller URL logo. (e.g. /myseller)
  --UseHybridPaymentOptions: oneof<nothing, bool> # Allows customers to use gift cards from the seller to buy their products on the marketplace. It identifies purchases made with a gift card so that only the final price (with discounts applied) is paid to the seller. (e.g. false)
  UserName: string # Seller username. (e.g. myseller)
]: any -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/seller")
  let body = {ArchiveId: $ArchiveId, CNPJ: $CNPJ, CSCIdentification: $CSCIdentification, CatalogSystemEndpoint: $CatalogSystemEndpoint, CategoryCommissionPercentage: $CategoryCommissionPercentage, DeliveryPolicy: $DeliveryPolicy, Description: $Description, Email: $Email, ExchangeReturnPolicy: $ExchangeReturnPolicy, FreightCommissionPercentage: $FreightCommissionPercentage, FulfillmentEndpoint: $FulfillmentEndpoint, FulfillmentSellerId: $FulfillmentSellerId, IsActive: $IsActive, IsBetterScope: $IsBetterScope, MerchantName: $MerchantName, Name: $Name, Password: $Password, ProductCommissionPercentage: $ProductCommissionPercentage, SecutityPrivacyPolicy: $SecutityPrivacyPolicy, SellerId: $SellerId, SellerType: $SellerType, TrustPolicy: $TrustPolicy, UrlLogo: $UrlLogo, UseHybridPaymentOptions: $UseHybridPaymentOptions, UserName: $UserName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Seller
#
# PUT /api/catalog_system/pvt/seller
# operationId: UpdateSeller
export def "catalog-system-pvt-seller UpdateSeller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  ArchiveId: int # Seller archive ID. (e.g. 1)
  CNPJ: string # Company registration number. (e.g. 12035072751)
  CSCIdentification: string # CSC identification. (e.g. pedrostore)
  CatalogSystemEndpoint: string # URL of the endpoint of the seller's catalog. This field will only be displayed if the seller type is VTEX Store. The field format will be as follows: `http://{sellerName}.vtexcommercestable.com.br/api/catalog_system/`. (e.g. http://pedrostore.vtexcommercestable.com.br/api/catalog_system/)
  --CategoryCommissionPercentage: string # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. [{"CategoryId":14,"ProductCommission":15.0,"FreightCommission":0.0}])
  DeliveryPolicy: string # Text describing the delivery policy previously agreed between the marketplace and the seller. (e.g. Delivery policy text)
  Description: string # Text describing the seller with a marketing tone. You can display this text in the marketplace window display by [customizing the CMS](https://help.vtex.com/en/tutorial/list-of-controls-for-templates--tutorials_563). (e.g. Brief description)
  Email: string # Email of the admin responsible for the seller. (e.g. breno@breno.com)
  ExchangeReturnPolicy: string # Text describing the exchange and return policy previously agreed between the marketplace and the seller. (e.g. Exchange return policy text)
  FreightCommissionPercentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  FulfillmentEndpoint: string # URL of the endpoint for fulfillment of seller's orders, which the marketplace will use to communicate with the seller. This field applies to all sellers, regardless of their type. However, for `VTEX Stores`, you don’t need to fill it in because the system will do that automatically. You can edit this field once the seller has been successfully added. (e.g. http://pedrostore.vtexcommercestable.com.br/api/fulfillment?affiliateid=LDB&sc=1)
  FulfillmentSellerId: int # Identification code of the seller responsible for fulfilling the order. This is an optional field used when a seller sells SKUs from another seller. If the seller sells their own SKUs, it must be left blank. (e.g. 1)
  --IsActive: oneof<nothing, bool> # If the selle is active (`true`) or not (`false`). (e.g. true)
  --IsBetterScope: oneof<nothing, bool> # Indicates whether it is a [comprehensive seller](https://help.vtex.com/en/tutorial/comprehensive-seller--5Qn4O2GpjUIzWTPpvLUfkI). (e.g. false)
  --MerchantName: string # Name of the marketplace, used to guide payments. This field should be nulled if the marketplace is responsible for processing payments. Check out our [Split Payment](https://help.vtex.com/en/tutorial/split-payment--6k5JidhYRUxileNolY2VLx) article to know more. (e.g. pedrostore)
  Name: string # Name of the account in the seller's environment. You can find it on **Account settings > Account > Account Name**). Applicable only if the seller uses their own payment method. (e.g. My pedrostore)
  Password: string # Seller password. (e.g. passoword)
  ProductCommissionPercentage: float # The percentage that must be filled in as agreed between the marketplace and the seller. If there is no such commission, please fill in the field with the value: `0.00`. (e.g. 0)
  SecutityPrivacyPolicy: string # Text describing the security policy previously agreed between the marketplace and the seller. (e.g. Secutity privacy policy text)
  SellerId: string # ID that identifies the seller in the marketplace. It can be the same as the seller name or a unique number. Check the **Sellers management** section in the Admin to get the correct ID. (e.g. pedrostore)
  SellerType: int # Seller type. (e.g. 1)
  --TrustPolicy: string # Seller trust policy. The default value is `'Default'`, but if your store is a B2B marketplace and you want to share the customers'emails with the sellers you need to set this field as `'AllowEmailSharing'`. (e.g. Default)
  UrlLogo: string # Seller URL logo. (e.g. /myseller)
  --UseHybridPaymentOptions: oneof<nothing, bool> # Allows customers to use gift cards from the seller to buy their products on the marketplace. It identifies purchases made with a gift card so that only the final price (with discounts applied) is paid to the seller. (e.g. false)
  UserName: string # Seller username. (e.g. myseller)
]: any -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/seller")
  let body = {ArchiveId: $ArchiveId, CNPJ: $CNPJ, CSCIdentification: $CSCIdentification, CatalogSystemEndpoint: $CatalogSystemEndpoint, CategoryCommissionPercentage: $CategoryCommissionPercentage, DeliveryPolicy: $DeliveryPolicy, Description: $Description, Email: $Email, ExchangeReturnPolicy: $ExchangeReturnPolicy, FreightCommissionPercentage: $FreightCommissionPercentage, FulfillmentEndpoint: $FulfillmentEndpoint, FulfillmentSellerId: $FulfillmentSellerId, IsActive: $IsActive, IsBetterScope: $IsBetterScope, MerchantName: $MerchantName, Name: $Name, Password: $Password, ProductCommissionPercentage: $ProductCommissionPercentage, SecutityPrivacyPolicy: $SecutityPrivacyPolicy, SellerId: $SellerId, SellerType: $SellerType, TrustPolicy: $TrustPolicy, UrlLogo: $UrlLogo, UseHybridPaymentOptions: $UseHybridPaymentOptions, UserName: $UserName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Seller List
#
# GET /api/catalog_system/pvt/seller/list
# operationId: SellerList
export def "catalog-system-pvt-seller-list SellerList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade policy ID. (format: int32, e.g. 1)
  --sellerType: int # Seller type. (format: int32, e.g. 1)
  --isBetterScope: oneof<nothing, bool> # If the seller is better scope. (e.g. false)
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar") (serialize-qp "sellerType" $sellerType "scalar") (serialize-qp "isBetterScope" $isBetterScope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/seller/list" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Seller by ID
#
# GET /api/catalog_system/pvt/seller/{sellerId}
# operationId: GetSellerbyId
export def "catalog-system-pvt-seller GetSellerbyId" [
  sellerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/seller/($sellerId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Seller by ID
#
# GET /api/catalog_system/pvt/sellers/{sellerId}
# operationId: GetSellersbyId
export def "catalog-system-pvt-sellers GetSellersbyId" [
  sellerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ArchiveId: int, CNPJ: string, CSCIdentification: string, CatalogSystemEndpoint: string, CategoryCommissionPercentage: string, DeliveryPolicy: string, Description: string, Email: string, ExchangeReturnPolicy: string, FreightCommissionPercentage: float, FulfillmentEndpoint: string, FulfillmentSellerId: int, IsActive: bool, IsBetterScope: bool, MerchantName: string, Name: string, Password: string, ProductCommissionPercentage: float, SecutityPrivacyPolicy: string, SellerId: string, SellerType: int, TrustPolicy: string, UrlLogo: string, UseHybridPaymentOptions: bool, UserName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/sellers/($sellerId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate attachments to an SKU
#
# POST /api/catalog_system/pvt/sku/associateattachments
# operationId: AssociateattachmentstoSKU
export def "catalog-system-pvt-sku-associateattachments AssociateattachmentstoSKU" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  AttachmentNames: list # Array with all the names of the attachments that you need to associate to the SKU.
  SkuId: int # Unique identifier of the SKU. (e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/sku/associateattachments")
  let body = {AttachmentNames: $AttachmentNames, SkuId: $SkuId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get SKU complements by type
#
# GET /api/catalog_system/pvt/sku/complements/{parentSkuId}/{type}
# operationId: GetSKUcomplementsbytype
export def "catalog-system-pvt-sku-complements GetSKUcomplementsbytype" [
  parentSkuId: int
  type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<ComplementSkuIds: list<int>, ParentSkuId: int, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/sku/complements/($parentSkuId)/($type)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU list by Product ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitByProductId/{productId}
# operationId: SkulistbyProductId
export def "catalog-system-pvt-sku-stockkeepingunit-by-product-id SkulistbyProductId" [
  productId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<ActivateIfPossible: bool, CommercialConditionId: int, CubicWeight: float, DateUpdated: string, EstimatedDateArrival: string, FlagKitItensSellApart: bool, Height: float, Id: int, InternalNote: string, IsActive: bool, IsDynamicKit: string, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsPersisted: bool, IsRemoved: bool, IsTransported: bool, Length: float, ManufacturerCode: string, MeasurementUnit: string, ModalId: int, ModalType: string, Name: string, Position: int, ProductId: int, RealHeight: float, RealLength: float, RealWeightKg: float, RealWidth: float, RefId: string, ReferenceStockKeepingUnitId: string, RewardValue: float, UnitMultiplier: float, WeightKg: float, Width: float, isKitOptimized: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/sku/stockkeepingunitByProductId/($productId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU by Alternate ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyalternateId/{alternateId}
# operationId: SkubyAlternateId
export def "catalog-system-pvt-sku-stockkeepingunitbyalternate-id SkubyAlternateId" [
  alternateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, CategoriesFullPath: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsDirectCategoryActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, PositionsInClusters: record, ProductCategories: record, ProductCategoryIds: string, ProductClusterHighlights: record, ProductClusterNames: record, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/sku/stockkeepingunitbyalternateId/($alternateId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU by EAN
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyean/{ean}
# operationId: SkubyEAN
export def "catalog-system-pvt-sku-stockkeepingunitbyean SkubyEAN" [
  ean: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, CategoriesFullPath: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsDirectCategoryActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, PositionsInClusters: record, ProductCategories: record, ProductCategoryIds: string, ProductClusterHighlights: record, ProductClusterNames: record, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/sku/stockkeepingunitbyean/($ean)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU and context
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitbyid/{skuId}
# operationId: SkuContext
export def "catalog-system-pvt-sku-stockkeepingunitbyid SkuContext" [
  skuId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy's unique identifier number. (e.g. 1)
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<AlternateIdValues: list<string>, AlternateIds: record<Ean: string, RefId: string>, Attachments: table<Fields: list, Id: int, IsActive: bool, IsRequired: bool, Keys: list, Name: string>, BrandId: string, BrandName: string, CSCIdentification: string, Categories: list<string>, Collections: list<string>, CommercialConditionId: int, ComplementName: string, DetailUrl: string, Dimension: record<cubicweight: float, height: float, length: float, weight: float, width: float>, EstimatedDateArrival: string, Id: int, ImageUrl: string, Images: table<FileId: int, ImageName: string, ImageUrl: string>, InformationSource: string, IsActive: bool, IsGiftCardRecharge: bool, IsInventoried: bool, IsKit: bool, IsProductActive: bool, IsTransported: bool, KeyWords: string, KitItems: list<string>, ManufacturerCode: string, MeasurementUnit: string, ModalType: string, NameComplete: string, ProductCategories: record, ProductCategoryIds: string, ProductClustersIds: string, ProductDescription: string, ProductFinalScore: int, ProductGlobalCategoryId: int, ProductId: int, ProductIsVisible: bool, ProductName: string, ProductRefId: string, ProductSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, RealDimension: record<realCubicWeight: float, realHeight: float, realLength: float, realWeight: float, realWidth: float>, ReleaseDate: string, RewardValue: float, SalesChannels: list<int>, Services: list<string>, ShowIfNotAvailable: bool, SkuName: string, SkuSellers: table<FreightCommissionPercentage: float, IsActive: bool, ProductCommissionPercentage: float, SellerId: string, SellerStockKeepingUnitId: string, StockKeepingUnitId: int>, SkuSpecifications: table<FieldId: int, FieldName: string, FieldValueIds: list, FieldValues: list>, TaxCode: string, UnitMultiplier: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog_system/pvt/sku/stockkeepingunitbyid/($skuId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get SKU ID by Reference ID
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitidbyrefid/{refId}
# operationId: SkuIdbyRefId
export def "catalog-system-pvt-sku-stockkeepingunitidbyrefid SkuIdbyRefId" [
  refId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/sku/stockkeepingunitidbyrefid/($refId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all SKU IDs
#
# GET /api/catalog_system/pvt/sku/stockkeepingunitids
# operationId: ListallSKUIDs
export def "catalog-system-pvt-sku-stockkeepingunitids ListallSKUIDs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Number of the page from where you need to retrieve SKU IDs. (e.g. 1)
  --pagesize: int # Size of the page from where you need retrieve SKU IDs. The maximum value is `1000`. (e.g. 25)
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pagesize" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/sku/stockkeepingunitids" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy’s unique numerical identifier. (e.g. 1)
  --page: int # Page number. (e.g. 1)
  --pageSize: int # Number of items in the page. (e.g. 1)
  --onlyAssigned: oneof<nothing, bool> # If set as `false`, it allows the user to decide if the SKUs that are not assigned to a specific trade policy should be also returned. (e.g. true)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "onlyAssigned" $onlyAssigned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog_system/pvt/sku/stockkeepingunitidsbysaleschannel" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change Notification with Seller ID and Seller SKU ID
#
# POST /api/catalog_system/pvt/skuseller/changenotification/{sellerId}/{sellerSkuId}
export def "catalog-system-pvt-skuseller-changenotification post" [
  sellerId: string
  sellerSkuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/skuseller/changenotification/($sellerId)/($sellerSkuId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change Notification with SKU ID
#
# POST /api/catalog_system/pvt/skuseller/changenotification/{skuId}
# operationId: ChangeNotification
export def "catalog-system-pvt-skuseller-changenotification ChangeNotification" [
  skuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/skuseller/changenotification/($skuId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a seller's SKU binding
#
# POST /api/catalog_system/pvt/skuseller/remove/{sellerId}/{sellerSkuId}
# operationId: DeleteSKUsellerassociation
export def "catalog-system-pvt-skuseller-remove DeleteSKUsellerassociation" [
  sellerId: string
  sellerSkuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/skuseller/remove/($sellerId)/($sellerSkuId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of a seller's SKU
#
# GET /api/catalog_system/pvt/skuseller/{sellerId}/{sellerSkuId}
# operationId: GetSKUseller
export def "catalog-system-pvt-skuseller GetSKUseller" [
  sellerId: string
  sellerSkuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<IsActive: bool, IsPersisted: bool, IsRemoved: bool, RequestedUpdateDate: string, SellerId: string, SellerStockKeepingUnitId: string, SkuSellerId: int, StockKeepingUnitId: int, UpdateDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/skuseller/($sellerId)/($sellerSkuId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Specification Field
#
# POST /api/catalog_system/pvt/specification/field
# operationId: SpecificationsInsertField
@deprecated --flag IsWizard
export def "catalog-system-pvt-specification-field SpecificationsInsertField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --CategoryId: int # Category ID. (nullable)
  --DefaultValue: string # Specification Field default Value. (nullable)
  --Description: string # Specification Field Description. (nullable)
  FieldGroupId: int # Specification Field Group ID. (format: int32)
  FieldGroupName: string # Specification Field Group Name.
  --FieldId: int # Specification Field ID. (nullable)
  FieldTypeId: int # Specification Field Type ID. (format: int32)
  --FieldValueId: int # Specification Field Value ID. (nullable)
  --IsActive: oneof<nothing, bool> # Defines if the Specification Field is active. The default value is `true`.
  --IsFilter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar.
  --IsOnProductDetails: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page.
  --IsRequired: oneof<nothing, bool> # Makes the Specification Field mandatory (`true`) or optional (`false`).
  --IsSideMenuLinkActive: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar.
  --IsStockKeepingUnit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification. If `false`, it will be added as a product specification field.
  --IsTopMenuLinkActive: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu.
  --IsWizard: oneof<nothing, bool> # Deprecated field. (DEPRECATED)
  Name: string # Specification Field ID.
  Position: int # Specification Field Position. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/specification/field")
  let body = {CategoryId: $CategoryId, DefaultValue: $DefaultValue, Description: $Description, FieldGroupId: $FieldGroupId, FieldGroupName: $FieldGroupName, FieldId: $FieldId, FieldTypeId: $FieldTypeId, FieldValueId: $FieldValueId, IsActive: $IsActive, IsFilter: $IsFilter, IsOnProductDetails: $IsOnProductDetails, IsRequired: $IsRequired, IsSideMenuLinkActive: $IsSideMenuLinkActive, IsStockKeepingUnit: $IsStockKeepingUnit, IsTopMenuLinkActive: $IsTopMenuLinkActive, IsWizard: $IsWizard, Name: $Name, Position: $Position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Specification Field
#
# PUT /api/catalog_system/pvt/specification/field
# operationId: SpecificationsInsertFieldUpdate
@deprecated --flag IsWizard
export def "catalog-system-pvt-specification-field SpecificationsInsertFieldUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --CategoryId: int # Category ID. (nullable)
  --DefaultValue: string # Specification Field default Value. (nullable)
  --Description: string # Specification Field Description. (nullable)
  FieldGroupId: int # Specification Field Group ID. (format: int32)
  FieldGroupName: string # Specification Field Group Name.
  --FieldId: int # Specification Field ID. (nullable)
  FieldTypeId: int # Specification Field Type ID. (format: int32)
  --FieldValueId: int # Specification Field Value ID. (nullable)
  --IsActive: oneof<nothing, bool> # Enables(`true`) or disables (`false`) the Specification Field. (e.g. true)
  --IsFilter: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To allow the specification to be used as a facet (filter) on the search navigation bar.
  --IsOnProductDetails: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal -If specification is visible on the product page.
  --IsRequired: oneof<nothing, bool> # Makes the Specification Field mandatory (`true`) or optional (`false`).
  --IsSideMenuLinkActive: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification field clickable in the search navigation bar.  (e.g. false)
  --IsStockKeepingUnit: oneof<nothing, bool> # If `true`, it will be added as a SKU specification field. If `false`, it will be added as a product specification field.
  --IsTopMenuLinkActive: oneof<nothing, bool> # Store Framework - Deprecated. Legacy CMS Portal - To make the specification visible in the store's upper menu.
  --IsWizard: oneof<nothing, bool> # Deprecated field. (DEPRECATED)
  Name: string # Specification Field ID.
  Position: int # Specification Field Position. (format: int32)
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/specification/field")
  let body = {CategoryId: $CategoryId, DefaultValue: $DefaultValue, Description: $Description, FieldGroupId: $FieldGroupId, FieldGroupName: $FieldGroupName, FieldId: $FieldId, FieldTypeId: $FieldTypeId, FieldValueId: $FieldValueId, IsActive: $IsActive, IsFilter: $IsFilter, IsOnProductDetails: $IsOnProductDetails, IsRequired: $IsRequired, IsSideMenuLinkActive: $IsSideMenuLinkActive, IsStockKeepingUnit: $IsStockKeepingUnit, IsTopMenuLinkActive: $IsTopMenuLinkActive, IsWizard: $IsWizard, Name: $Name, Position: $Position} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Specification Field Value
#
# POST /api/catalog_system/pvt/specification/fieldValue
# operationId: SpecificationsInsertFieldValue
export def "catalog-system-pvt-specification-field-value SpecificationsInsertFieldValue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  FieldId: int # Specification Field ID. (format: int32)
  --IsActive: oneof<nothing, bool> # Defines if the Specification Field Value is active (`true`) or inactive (`false`).
  Name: string # Specification Field Value Name.
  Position: int # Specification Field Value Position. (format: int32)
  Text: string # Specification Field Value Description.
]: any -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/specification/fieldValue")
  let body = {FieldId: $FieldId, IsActive: $IsActive, Name: $Name, Position: $Position, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Specification Field Value
#
# PUT /api/catalog_system/pvt/specification/fieldValue
# operationId: SpecificationsUpdateFieldValue
export def "catalog-system-pvt-specification-field-value SpecificationsUpdateFieldValue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --FieldId: int # Specification Field ID. (nullable)
  --IsActive: oneof<nothing, bool> # Defines if the Specification Field Value is active (`true`) or inactive (`false`).
  Name: string # Specification Field Value Name.
  Position: int # Specification Field Position. (format: int32)
  --Text: string # Specification Field Value Description. (nullable)
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/catalog_system/pvt/specification/fieldValue")
  let body = {FieldId: $FieldId, IsActive: $IsActive, Name: $Name, Position: $Position, Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Specification Field Value
#
# GET /api/catalog_system/pvt/specification/fieldValue/{fieldValueId}
# operationId: SpecificationsGetFieldValue
export def "catalog-system-pvt-specification-field-value SpecificationsGetFieldValue" [
  fieldValueId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<FieldId: int, FieldValueId: int, IsActive: bool, Name: string, Position: int, Text: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/specification/fieldValue/($fieldValueId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Specification Group by Category
#
# GET /api/catalog_system/pvt/specification/groupbycategory/{categoryId}
# operationId: SpecificationsGroupListbyCategory
export def "catalog-system-pvt-specification-groupbycategory SpecificationsGroupListbyCategory" [
  categoryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Describes the type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> table<CategoryId: int, Id: int, Name: string, Position: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog_system/pvt/specification/groupbycategory/($categoryId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
