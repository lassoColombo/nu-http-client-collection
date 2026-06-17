# Auto-generated client for App Store Connect API v1.4.1
# Source: https://api.apis.guru/v2/specs/apple.com/app-store-connect/1.4.1/openapi.json
# Auth: --token flag or $env.APP_STORE_CONNECT_API_TOKEN

const BASE_URL = "https://api.appstoreconnect.apple.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APP_STORE_CONNECT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.appstoreconnect.apple.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "age-rating-declarations instance" } } | get name | first)
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

# PATCH /v1/ageRatingDeclarations/{id}
#
# operationId: ageRatingDeclarations-update_instance
# --data shape: {attributes?: record, id: string, type: "ageRatingDeclarations"}
export def "age-rating-declarations instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "ageRatingDeclarations"}
]: any -> record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/ageRatingDeclarations/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appCategories
#
# operationId: appCategories-get_collection
export def "app-categories collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-platforms: list # filter by attribute 'platforms'
  --exists-parent: list # filter by existence or non-existence of related 'parent'
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --limit-subcategories: int # maximum number of related subcategories returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[platforms]" $filter_platforms "csv") (serialize-qp "exists[parent]" $exists_parent "csv") (serialize-qp "fields[appCategories]" $fields_app_categories "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "limit[subcategories]" $limit_subcategories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/appCategories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appCategories/{id}
#
# operationId: appCategories-get_instance
export def "app-categories instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
  --include: list # comma-separated list of relationships to include
  --limit-subcategories: int # maximum number of related subcategories returned (when they are included)
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv") (serialize-qp "include" $include "csv") (serialize-qp "limit[subcategories]" $limit_subcategories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appCategories/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appCategories/{id}/parent
#
# operationId: appCategories-parent-get_to_one_related
export def "app-categories-parent related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appCategories/{id}/parent") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appCategories/{id}/subcategories
#
# operationId: appCategories-subcategories-get_to_many_related
export def "app-categories-subcategories related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appCategories/{id}/subcategories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appEncryptionDeclarations
#
# operationId: appEncryptionDeclarations-get_collection
export def "app-encryption-declarations collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-platform: list # filter by attribute 'platform'
  --filter-app: list # filter by id(s) of related 'app'
  --filter-builds: list # filter by id(s) of related 'builds'
  --fields-app-encryption-declarations: list # the fields to include for returned resources of type appEncryptionDeclarations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[platform]" $filter_platform "csv") (serialize-qp "filter[app]" $filter_app "csv") (serialize-qp "filter[builds]" $filter_builds "csv") (serialize-qp "fields[appEncryptionDeclarations]" $fields_app_encryption_declarations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/appEncryptionDeclarations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appEncryptionDeclarations/{id}
#
# operationId: appEncryptionDeclarations-get_instance
export def "app-encryption-declarations instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-encryption-declarations: list # the fields to include for returned resources of type appEncryptionDeclarations
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<appEncryptionDeclarationState: string, availableOnFrenchStore: bool, codeValue: string, containsProprietaryCryptography: bool, containsThirdPartyCryptography: bool, documentName: string, documentType: string, documentUrl: string, exempt: bool, platform: string, uploadedDate: string, usesEncryption: bool>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appEncryptionDeclarations]" $fields_app_encryption_declarations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appEncryptionDeclarations/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appEncryptionDeclarations/{id}/app
#
# operationId: appEncryptionDeclarations-app-get_to_one_related
export def "app-encryption-declarations-app related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appEncryptionDeclarations/{id}/app") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/appEncryptionDeclarations/{id}/relationships/builds
#
# operationId: appEncryptionDeclarations-builds-create_to_many_relationship
# --data item shape: {id: string, type: "builds"}
export def "app-encryption-declarations-relationships-builds relationship" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appEncryptionDeclarations/{id}/relationships/builds"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/appInfoLocalizations
#
# operationId: appInfoLocalizations-create_instance
# --data shape: {attributes: record, relationships: record, type: "appInfoLocalizations"}
export def "app-info-localizations instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appInfoLocalizations"}
]: any -> record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appInfoLocalizations")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appInfoLocalizations/{id}
#
# operationId: appInfoLocalizations-delete_instance
export def "app-info-localizations instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfoLocalizations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appInfoLocalizations/{id}
#
# operationId: appInfoLocalizations-get_instance
export def "app-info-localizations instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-info-localizations: list # the fields to include for returned resources of type appInfoLocalizations
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appInfoLocalizations]" $fields_app_info_localizations "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfoLocalizations/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appInfoLocalizations/{id}
#
# operationId: appInfoLocalizations-update_instance
# --data shape: {attributes?: record, id: string, type: "appInfoLocalizations"}
export def "app-info-localizations instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "appInfoLocalizations"}
]: any -> record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfoLocalizations/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appInfos/{id}
#
# operationId: appInfos-get_instance
export def "app-infos instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-infos: list # the fields to include for returned resources of type appInfos
  --include: list # comma-separated list of relationships to include
  --fields-age-rating-declarations: list # the fields to include for returned resources of type ageRatingDeclarations
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
  --fields-app-info-localizations: list # the fields to include for returned resources of type appInfoLocalizations
  --limit-app-info-localizations: int # maximum number of related appInfoLocalizations returned (when they are included)
]: nothing -> record<data: record<attributes: record<appStoreAgeRating: string, appStoreState: string, brazilAgeRating: string, kidsAgeBand: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appInfoLocalizations: record, primaryCategory: record, primarySubcategoryOne: record, primarySubcategoryTwo: record, secondaryCategory: record, secondarySubcategoryOne: record, secondarySubcategoryTwo: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appInfos]" $fields_app_infos "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[ageRatingDeclarations]" $fields_age_rating_declarations "csv") (serialize-qp "fields[appCategories]" $fields_app_categories "csv") (serialize-qp "fields[appInfoLocalizations]" $fields_app_info_localizations "csv") (serialize-qp "limit[appInfoLocalizations]" $limit_app_info_localizations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appInfos/{id}
#
# operationId: appInfos-update_instance
# --data shape: {id: string, relationships?: record, type: "appInfos"}
export def "app-infos instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {id: string, relationships?: record, type: "appInfos"}
]: any -> record<data: record<attributes: record<appStoreAgeRating: string, appStoreState: string, brazilAgeRating: string, kidsAgeBand: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appInfoLocalizations: record, primaryCategory: record, primarySubcategoryOne: record, primarySubcategoryTwo: record, secondaryCategory: record, secondarySubcategoryOne: record, secondarySubcategoryTwo: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appInfos/{id}/ageRatingDeclaration
#
# operationId: appInfos-ageRatingDeclaration-get_to_one_related
export def "app-infos-age-rating-declaration related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-age-rating-declarations: list # the fields to include for returned resources of type ageRatingDeclarations
]: nothing -> record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[ageRatingDeclarations]" $fields_age_rating_declarations "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}/ageRatingDeclaration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appInfos/{id}/appInfoLocalizations
#
# operationId: appInfos-appInfoLocalizations-get_to_many_related
export def "app-infos-app-info-localizations related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-locale: list # filter by attribute 'locale'
  --fields-app-infos: list # the fields to include for returned resources of type appInfos
  --fields-app-info-localizations: list # the fields to include for returned resources of type appInfoLocalizations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[locale]" $filter_locale "csv") (serialize-qp "fields[appInfos]" $fields_app_infos "csv") (serialize-qp "fields[appInfoLocalizations]" $fields_app_info_localizations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}/appInfoLocalizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appInfos/{id}/primaryCategory
#
# operationId: appInfos-primaryCategory-get_to_one_related
export def "app-infos-primary-category related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}/primaryCategory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appInfos/{id}/primarySubcategoryOne
#
# operationId: appInfos-primarySubcategoryOne-get_to_one_related
export def "app-infos-primary-subcategory-one related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}/primarySubcategoryOne") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appInfos/{id}/primarySubcategoryTwo
#
# operationId: appInfos-primarySubcategoryTwo-get_to_one_related
export def "app-infos-primary-subcategory-two related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}/primarySubcategoryTwo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appInfos/{id}/secondaryCategory
#
# operationId: appInfos-secondaryCategory-get_to_one_related
export def "app-infos-secondary-category related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}/secondaryCategory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appInfos/{id}/secondarySubcategoryOne
#
# operationId: appInfos-secondarySubcategoryOne-get_to_one_related
export def "app-infos-secondary-subcategory-one related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}/secondarySubcategoryOne") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appInfos/{id}/secondarySubcategoryTwo
#
# operationId: appInfos-secondarySubcategoryTwo-get_to_one_related
export def "app-infos-secondary-subcategory-two related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fields_app_categories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appInfos/{id}/secondarySubcategoryTwo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/appPreOrders
#
# operationId: appPreOrders-create_instance
# --data shape: {attributes?: record, relationships: record, type: "appPreOrders"}
export def "app-pre-orders instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, relationships: record, type: "appPreOrders"}
]: any -> record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appPreOrders")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appPreOrders/{id}
#
# operationId: appPreOrders-delete_instance
export def "app-pre-orders instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreOrders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPreOrders/{id}
#
# operationId: appPreOrders-get_instance
export def "app-pre-orders instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-pre-orders: list # the fields to include for returned resources of type appPreOrders
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreOrders]" $fields_app_pre_orders "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreOrders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appPreOrders/{id}
#
# operationId: appPreOrders-update_instance
# --data shape: {attributes?: record, id: string, type: "appPreOrders"}
export def "app-pre-orders instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "appPreOrders"}
]: any -> record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreOrders/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/appPreviewSets
#
# operationId: appPreviewSets-create_instance
# --data shape: {attributes: record, relationships: record, type: "appPreviewSets"}
export def "app-preview-sets instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appPreviewSets"}
]: any -> record<data: record<attributes: record<previewType: string>, id: string, links: record<self: string>, relationships: record<appPreviews: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appPreviewSets")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appPreviewSets/{id}
#
# operationId: appPreviewSets-delete_instance
export def "app-preview-sets instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreviewSets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPreviewSets/{id}
#
# operationId: appPreviewSets-get_instance
export def "app-preview-sets instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-preview-sets: list # the fields to include for returned resources of type appPreviewSets
  --include: list # comma-separated list of relationships to include
  --fields-app-previews: list # the fields to include for returned resources of type appPreviews
  --limit-app-previews: int # maximum number of related appPreviews returned (when they are included)
]: nothing -> record<data: record<attributes: record<previewType: string>, id: string, links: record<self: string>, relationships: record<appPreviews: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreviewSets]" $fields_app_preview_sets "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appPreviews]" $fields_app_previews "csv") (serialize-qp "limit[appPreviews]" $limit_app_previews "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreviewSets/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPreviewSets/{id}/appPreviews
#
# operationId: appPreviewSets-appPreviews-get_to_many_related
export def "app-preview-sets-app-previews related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-previews: list # the fields to include for returned resources of type appPreviews
  --fields-app-preview-sets: list # the fields to include for returned resources of type appPreviewSets
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreviews]" $fields_app_previews "csv") (serialize-qp "fields[appPreviewSets]" $fields_app_preview_sets "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreviewSets/{id}/appPreviews") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPreviewSets/{id}/relationships/appPreviews
#
# operationId: appPreviewSets-appPreviews-get_to_many_relationship
export def "app-preview-sets-relationships-app-previews relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreviewSets/{id}/relationships/appPreviews") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appPreviewSets/{id}/relationships/appPreviews
#
# operationId: appPreviewSets-appPreviews-replace_to_many_relationship
# --data item shape: {id: string, type: "appPreviews"}
export def "app-preview-sets-relationships-app-previews relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "appPreviews"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreviewSets/{id}/relationships/appPreviews"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/appPreviews
#
# operationId: appPreviews-create_instance
# --data shape: {attributes: record, relationships: record, type: "appPreviews"}
export def "app-previews instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appPreviews"}
]: any -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appPreviews")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appPreviews/{id}
#
# operationId: appPreviews-delete_instance
export def "app-previews instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreviews/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPreviews/{id}
#
# operationId: appPreviews-get_instance
export def "app-previews instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-previews: list # the fields to include for returned resources of type appPreviews
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreviews]" $fields_app_previews "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreviews/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appPreviews/{id}
#
# operationId: appPreviews-update_instance
# --data shape: {attributes?: record, id: string, type: "appPreviews"}
export def "app-previews instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "appPreviews"}
]: any -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPreviews/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appPricePoints
#
# operationId: appPricePoints-get_collection
export def "app-price-points collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-price-tier: list # filter by id(s) of related 'priceTier'
  --filter-territory: list # filter by id(s) of related 'territory'
  --fields-app-price-points: list # the fields to include for returned resources of type appPricePoints
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-territories: list # the fields to include for returned resources of type territories
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[priceTier]" $filter_price_tier "csv") (serialize-qp "filter[territory]" $filter_territory "csv") (serialize-qp "fields[appPricePoints]" $fields_app_price_points "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[territories]" $fields_territories "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/appPricePoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPricePoints/{id}
#
# operationId: appPricePoints-get_instance
export def "app-price-points instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-price-points: list # the fields to include for returned resources of type appPricePoints
  --include: list # comma-separated list of relationships to include
  --fields-territories: list # the fields to include for returned resources of type territories
]: nothing -> record<data: record<attributes: record<customerPrice: string, proceeds: string>, id: string, links: record<self: string>, relationships: record<priceTier: record, territory: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPricePoints]" $fields_app_price_points "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[territories]" $fields_territories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPricePoints/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPricePoints/{id}/territory
#
# operationId: appPricePoints-territory-get_to_one_related
export def "app-price-points-territory related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-territories: list # the fields to include for returned resources of type territories
]: nothing -> record<data: record<attributes: record<currency: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[territories]" $fields_territories "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPricePoints/{id}/territory") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPriceTiers
#
# operationId: appPriceTiers-get_collection
export def "app-price-tiers collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-id: list # filter by id(s)
  --fields-app-price-tiers: list # the fields to include for returned resources of type appPriceTiers
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-app-price-points: list # the fields to include for returned resources of type appPricePoints
  --limit-price-points: int # maximum number of related pricePoints returned (when they are included)
]: nothing -> record<data: table<id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "fields[appPriceTiers]" $fields_app_price_tiers "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[appPricePoints]" $fields_app_price_points "csv") (serialize-qp "limit[pricePoints]" $limit_price_points "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/appPriceTiers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPriceTiers/{id}
#
# operationId: appPriceTiers-get_instance
export def "app-price-tiers instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-price-tiers: list # the fields to include for returned resources of type appPriceTiers
  --include: list # comma-separated list of relationships to include
  --fields-app-price-points: list # the fields to include for returned resources of type appPricePoints
  --limit-price-points: int # maximum number of related pricePoints returned (when they are included)
]: nothing -> record<data: record<id: string, links: record<self: string>, relationships: record<pricePoints: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPriceTiers]" $fields_app_price_tiers "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appPricePoints]" $fields_app_price_points "csv") (serialize-qp "limit[pricePoints]" $limit_price_points "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPriceTiers/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPriceTiers/{id}/pricePoints
#
# operationId: appPriceTiers-pricePoints-get_to_many_related
export def "app-price-tiers-price-points related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-price-points: list # the fields to include for returned resources of type appPricePoints
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPricePoints]" $fields_app_price_points "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPriceTiers/{id}/pricePoints") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appPrices/{id}
#
# operationId: appPrices-get_instance
export def "app-prices instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-prices: list # the fields to include for returned resources of type appPrices
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<id: string, links: record<self: string>, relationships: record<app: record, priceTier: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPrices]" $fields_app_prices "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appPrices/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/appScreenshotSets
#
# operationId: appScreenshotSets-create_instance
# --data shape: {attributes: record, relationships: record, type: "appScreenshotSets"}
export def "app-screenshot-sets instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appScreenshotSets"}
]: any -> record<data: record<attributes: record<screenshotDisplayType: string>, id: string, links: record<self: string>, relationships: record<appScreenshots: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appScreenshotSets")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appScreenshotSets/{id}
#
# operationId: appScreenshotSets-delete_instance
export def "app-screenshot-sets instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appScreenshotSets/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appScreenshotSets/{id}
#
# operationId: appScreenshotSets-get_instance
export def "app-screenshot-sets instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-screenshot-sets: list # the fields to include for returned resources of type appScreenshotSets
  --include: list # comma-separated list of relationships to include
  --fields-app-screenshots: list # the fields to include for returned resources of type appScreenshots
  --limit-app-screenshots: int # maximum number of related appScreenshots returned (when they are included)
]: nothing -> record<data: record<attributes: record<screenshotDisplayType: string>, id: string, links: record<self: string>, relationships: record<appScreenshots: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appScreenshotSets]" $fields_app_screenshot_sets "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appScreenshots]" $fields_app_screenshots "csv") (serialize-qp "limit[appScreenshots]" $limit_app_screenshots "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appScreenshotSets/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appScreenshotSets/{id}/appScreenshots
#
# operationId: appScreenshotSets-appScreenshots-get_to_many_related
export def "app-screenshot-sets-app-screenshots related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-screenshot-sets: list # the fields to include for returned resources of type appScreenshotSets
  --fields-app-screenshots: list # the fields to include for returned resources of type appScreenshots
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appScreenshotSets]" $fields_app_screenshot_sets "csv") (serialize-qp "fields[appScreenshots]" $fields_app_screenshots "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appScreenshotSets/{id}/appScreenshots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appScreenshotSets/{id}/relationships/appScreenshots
#
# operationId: appScreenshotSets-appScreenshots-get_to_many_relationship
export def "app-screenshot-sets-relationships-app-screenshots relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appScreenshotSets/{id}/relationships/appScreenshots") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appScreenshotSets/{id}/relationships/appScreenshots
#
# operationId: appScreenshotSets-appScreenshots-replace_to_many_relationship
# --data item shape: {id: string, type: "appScreenshots"}
export def "app-screenshot-sets-relationships-app-screenshots relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "appScreenshots"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appScreenshotSets/{id}/relationships/appScreenshots"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/appScreenshots
#
# operationId: appScreenshots-create_instance
# --data shape: {attributes: record, relationships: record, type: "appScreenshots"}
export def "app-screenshots instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appScreenshots"}
]: any -> record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appScreenshots")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appScreenshots/{id}
#
# operationId: appScreenshots-delete_instance
export def "app-screenshots instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appScreenshots/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appScreenshots/{id}
#
# operationId: appScreenshots-get_instance
export def "app-screenshots instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-screenshots: list # the fields to include for returned resources of type appScreenshots
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appScreenshots]" $fields_app_screenshots "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appScreenshots/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appScreenshots/{id}
#
# operationId: appScreenshots-update_instance
# --data shape: {attributes?: record, id: string, type: "appScreenshots"}
export def "app-screenshots instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "appScreenshots"}
]: any -> record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appScreenshots/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/appStoreReviewAttachments
#
# operationId: appStoreReviewAttachments-create_instance
# --data shape: {attributes: record, relationships: record, type: "appStoreReviewAttachments"}
export def "app-store-review-attachments instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appStoreReviewAttachments"}
]: any -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appStoreReviewAttachments")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appStoreReviewAttachments/{id}
#
# operationId: appStoreReviewAttachments-delete_instance
export def "app-store-review-attachments instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreReviewAttachments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreReviewAttachments/{id}
#
# operationId: appStoreReviewAttachments-get_instance
export def "app-store-review-attachments instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-review-attachments: list # the fields to include for returned resources of type appStoreReviewAttachments
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreReviewAttachments]" $fields_app_store_review_attachments "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreReviewAttachments/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appStoreReviewAttachments/{id}
#
# operationId: appStoreReviewAttachments-update_instance
# --data shape: {attributes?: record, id: string, type: "appStoreReviewAttachments"}
export def "app-store-review-attachments instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "appStoreReviewAttachments"}
]: any -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreReviewAttachments/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/appStoreReviewDetails
#
# operationId: appStoreReviewDetails-create_instance
# --data shape: {attributes?: record, relationships: record, type: "appStoreReviewDetails"}
export def "app-store-review-details instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, relationships: record, type: "appStoreReviewDetails"}
]: any -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appStoreReviewDetails")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appStoreReviewDetails/{id}
#
# operationId: appStoreReviewDetails-get_instance
export def "app-store-review-details instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-review-details: list # the fields to include for returned resources of type appStoreReviewDetails
  --include: list # comma-separated list of relationships to include
  --fields-app-store-review-attachments: list # the fields to include for returned resources of type appStoreReviewAttachments
  --limit-app-store-review-attachments: int # maximum number of related appStoreReviewAttachments returned (when they are included)
]: nothing -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreReviewDetails]" $fields_app_store_review_details "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appStoreReviewAttachments]" $fields_app_store_review_attachments "csv") (serialize-qp "limit[appStoreReviewAttachments]" $limit_app_store_review_attachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreReviewDetails/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appStoreReviewDetails/{id}
#
# operationId: appStoreReviewDetails-update_instance
# --data shape: {attributes?: record, id: string, type: "appStoreReviewDetails"}
export def "app-store-review-details instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "appStoreReviewDetails"}
]: any -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreReviewDetails/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appStoreReviewDetails/{id}/appStoreReviewAttachments
#
# operationId: appStoreReviewDetails-appStoreReviewAttachments-get_to_many_related
export def "app-store-review-details-app-store-review-attachments related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-review-details: list # the fields to include for returned resources of type appStoreReviewDetails
  --fields-app-store-review-attachments: list # the fields to include for returned resources of type appStoreReviewAttachments
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreReviewDetails]" $fields_app_store_review_details "csv") (serialize-qp "fields[appStoreReviewAttachments]" $fields_app_store_review_attachments "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreReviewDetails/{id}/appStoreReviewAttachments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/appStoreVersionLocalizations
#
# operationId: appStoreVersionLocalizations-create_instance
# --data shape: {attributes: record, relationships: record, type: "appStoreVersionLocalizations"}
export def "app-store-version-localizations instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appStoreVersionLocalizations"}
]: any -> record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appStoreVersionLocalizations")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appStoreVersionLocalizations/{id}
#
# operationId: appStoreVersionLocalizations-delete_instance
export def "app-store-version-localizations instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersionLocalizations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersionLocalizations/{id}
#
# operationId: appStoreVersionLocalizations-get_instance
export def "app-store-version-localizations instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-version-localizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --include: list # comma-separated list of relationships to include
  --fields-app-screenshot-sets: list # the fields to include for returned resources of type appScreenshotSets
  --fields-app-preview-sets: list # the fields to include for returned resources of type appPreviewSets
  --limit-app-preview-sets: int # maximum number of related appPreviewSets returned (when they are included)
  --limit-app-screenshot-sets: int # maximum number of related appScreenshotSets returned (when they are included)
]: nothing -> record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersionLocalizations]" $fields_app_store_version_localizations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appScreenshotSets]" $fields_app_screenshot_sets "csv") (serialize-qp "fields[appPreviewSets]" $fields_app_preview_sets "csv") (serialize-qp "limit[appPreviewSets]" $limit_app_preview_sets "scalar") (serialize-qp "limit[appScreenshotSets]" $limit_app_screenshot_sets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersionLocalizations/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appStoreVersionLocalizations/{id}
#
# operationId: appStoreVersionLocalizations-update_instance
# --data shape: {attributes?: record, id: string, type: "appStoreVersionLocalizations"}
export def "app-store-version-localizations instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "appStoreVersionLocalizations"}
]: any -> record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersionLocalizations/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appStoreVersionLocalizations/{id}/appPreviewSets
#
# operationId: appStoreVersionLocalizations-appPreviewSets-get_to_many_related
export def "app-store-version-localizations-app-preview-sets related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-preview-type: list # filter by attribute 'previewType'
  --fields-app-store-version-localizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --fields-app-previews: list # the fields to include for returned resources of type appPreviews
  --fields-app-preview-sets: list # the fields to include for returned resources of type appPreviewSets
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[previewType]" $filter_preview_type "csv") (serialize-qp "fields[appStoreVersionLocalizations]" $fields_app_store_version_localizations "csv") (serialize-qp "fields[appPreviews]" $fields_app_previews "csv") (serialize-qp "fields[appPreviewSets]" $fields_app_preview_sets "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersionLocalizations/{id}/appPreviewSets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersionLocalizations/{id}/appScreenshotSets
#
# operationId: appStoreVersionLocalizations-appScreenshotSets-get_to_many_related
export def "app-store-version-localizations-app-screenshot-sets related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-screenshot-display-type: list # filter by attribute 'screenshotDisplayType'
  --fields-app-store-version-localizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --fields-app-screenshot-sets: list # the fields to include for returned resources of type appScreenshotSets
  --fields-app-screenshots: list # the fields to include for returned resources of type appScreenshots
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[screenshotDisplayType]" $filter_screenshot_display_type "csv") (serialize-qp "fields[appStoreVersionLocalizations]" $fields_app_store_version_localizations "csv") (serialize-qp "fields[appScreenshotSets]" $fields_app_screenshot_sets "csv") (serialize-qp "fields[appScreenshots]" $fields_app_screenshots "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersionLocalizations/{id}/appScreenshotSets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/appStoreVersionPhasedReleases
#
# operationId: appStoreVersionPhasedReleases-create_instance
# --data shape: {attributes?: record, relationships: record, type: "appStoreVersionPhasedReleases"}
export def "app-store-version-phased-releases instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, relationships: record, type: "appStoreVersionPhasedReleases"}
]: any -> record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appStoreVersionPhasedReleases")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appStoreVersionPhasedReleases/{id}
#
# operationId: appStoreVersionPhasedReleases-delete_instance
export def "app-store-version-phased-releases instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersionPhasedReleases/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appStoreVersionPhasedReleases/{id}
#
# operationId: appStoreVersionPhasedReleases-update_instance
# --data shape: {attributes?: record, id: string, type: "appStoreVersionPhasedReleases"}
export def "app-store-version-phased-releases instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "appStoreVersionPhasedReleases"}
]: any -> record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersionPhasedReleases/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/appStoreVersionSubmissions
#
# operationId: appStoreVersionSubmissions-create_instance
# --data shape: {relationships: record, type: "appStoreVersionSubmissions"}
export def "app-store-version-submissions instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {relationships: record, type: "appStoreVersionSubmissions"}
]: any -> record<data: record<id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appStoreVersionSubmissions")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appStoreVersionSubmissions/{id}
#
# operationId: appStoreVersionSubmissions-delete_instance
export def "app-store-version-submissions instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersionSubmissions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/appStoreVersions
#
# operationId: appStoreVersions-create_instance
# --data shape: {attributes: record, relationships: record, type: "appStoreVersions"}
export def "app-store-versions instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "appStoreVersions"}
]: any -> record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/appStoreVersions")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/appStoreVersions/{id}
#
# operationId: appStoreVersions-delete_instance
export def "app-store-versions instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}
#
# operationId: appStoreVersions-get_instance
@deprecated --flag fields-age-rating-declarations
export def "app-store-versions instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
  --include: list # comma-separated list of relationships to include
  --fields-app-store-version-localizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --fields-idfa-declarations: list # the fields to include for returned resources of type idfaDeclarations
  --fields-routing-app-coverages: list # the fields to include for returned resources of type routingAppCoverages
  --fields-app-store-version-phased-releases: list # the fields to include for returned resources of type appStoreVersionPhasedReleases
  --fields-age-rating-declarations: list # the fields to include for returned resources of type ageRatingDeclarations (DEPRECATED)
  --fields-app-store-review-details: list # the fields to include for returned resources of type appStoreReviewDetails
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-app-store-version-submissions: list # the fields to include for returned resources of type appStoreVersionSubmissions
  --limit-app-store-version-localizations: int # maximum number of related appStoreVersionLocalizations returned (when they are included)
]: nothing -> record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appStoreVersionLocalizations]" $fields_app_store_version_localizations "csv") (serialize-qp "fields[idfaDeclarations]" $fields_idfa_declarations "csv") (serialize-qp "fields[routingAppCoverages]" $fields_routing_app_coverages "csv") (serialize-qp "fields[appStoreVersionPhasedReleases]" $fields_app_store_version_phased_releases "csv") (serialize-qp "fields[ageRatingDeclarations]" $fields_age_rating_declarations "csv") (serialize-qp "fields[appStoreReviewDetails]" $fields_app_store_review_details "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[appStoreVersionSubmissions]" $fields_app_store_version_submissions "csv") (serialize-qp "limit[appStoreVersionLocalizations]" $limit_app_store_version_localizations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appStoreVersions/{id}
#
# operationId: appStoreVersions-update_instance
# --data shape: {attributes?: record, id: string, relationships?: record, type: "appStoreVersions"}
export def "app-store-versions instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "appStoreVersions"}
]: any -> record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appStoreVersions/{id}/ageRatingDeclaration
#
# DEPRECATED
# operationId: appStoreVersions-ageRatingDeclaration-get_to_one_related
@deprecated
@deprecated --flag fields-age-rating-declarations
export def "app-store-versions-age-rating-declaration related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-age-rating-declarations: list # the fields to include for returned resources of type ageRatingDeclarations (DEPRECATED)
]: nothing -> record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[ageRatingDeclarations]" $fields_age_rating_declarations "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/ageRatingDeclaration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}/appStoreReviewDetail
#
# operationId: appStoreVersions-appStoreReviewDetail-get_to_one_related
export def "app-store-versions-app-store-review-detail related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-review-details: list # the fields to include for returned resources of type appStoreReviewDetails
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
  --fields-app-store-review-attachments: list # the fields to include for returned resources of type appStoreReviewAttachments
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreReviewDetails]" $fields_app_store_review_details "csv") (serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv") (serialize-qp "fields[appStoreReviewAttachments]" $fields_app_store_review_attachments "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/appStoreReviewDetail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}/appStoreVersionLocalizations
#
# operationId: appStoreVersions-appStoreVersionLocalizations-get_to_many_related
export def "app-store-versions-app-store-version-localizations related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-version-localizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersionLocalizations]" $fields_app_store_version_localizations "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/appStoreVersionLocalizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}/appStoreVersionPhasedRelease
#
# operationId: appStoreVersions-appStoreVersionPhasedRelease-get_to_one_related
export def "app-store-versions-app-store-version-phased-release related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-version-phased-releases: list # the fields to include for returned resources of type appStoreVersionPhasedReleases
]: nothing -> record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersionPhasedReleases]" $fields_app_store_version_phased_releases "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/appStoreVersionPhasedRelease") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}/appStoreVersionSubmission
#
# operationId: appStoreVersions-appStoreVersionSubmission-get_to_one_related
export def "app-store-versions-app-store-version-submission related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
  --fields-app-store-version-submissions: list # the fields to include for returned resources of type appStoreVersionSubmissions
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv") (serialize-qp "fields[appStoreVersionSubmissions]" $fields_app_store_version_submissions "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/appStoreVersionSubmission") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}/build
#
# operationId: appStoreVersions-build-get_to_one_related
export def "app-store-versions-build related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/build") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}/idfaDeclaration
#
# operationId: appStoreVersions-idfaDeclaration-get_to_one_related
export def "app-store-versions-idfa-declaration related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-idfa-declarations: list # the fields to include for returned resources of type idfaDeclarations
]: nothing -> record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[idfaDeclarations]" $fields_idfa_declarations "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/idfaDeclaration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}/relationships/build
#
# operationId: appStoreVersions-build-get_to_one_relationship
export def "app-store-versions-relationships-build relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/relationships/build"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/appStoreVersions/{id}/relationships/build
#
# operationId: appStoreVersions-build-update_to_one_relationship
# --data shape: {id: string, type: "builds"}
export def "app-store-versions-relationships-build relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {id: string, type: "builds"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/relationships/build"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/appStoreVersions/{id}/routingAppCoverage
#
# operationId: appStoreVersions-routingAppCoverage-get_to_one_related
export def "app-store-versions-routing-app-coverage related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-routing-app-coverages: list # the fields to include for returned resources of type routingAppCoverages
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[routingAppCoverages]" $fields_routing_app_coverages "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/appStoreVersions/{id}/routingAppCoverage") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps
#
# operationId: apps-get_collection
export def "apps collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-app-store-versions-app-store-state: list # filter by attribute 'appStoreVersions.appStoreState'
  --filter-app-store-versions-platform: list # filter by attribute 'appStoreVersions.platform'
  --filter-bundle-id: list # filter by attribute 'bundleId'
  --filter-name: list # filter by attribute 'name'
  --filter-sku: list # filter by attribute 'sku'
  --filter-app-store-versions: list # filter by id(s) of related 'appStoreVersions'
  --filter-id: list # filter by id(s)
  --exists-game-center-enabled-versions: list # filter by existence or non-existence of related 'gameCenterEnabledVersions'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-beta-groups: list # the fields to include for returned resources of type betaGroups
  --fields-perf-power-metrics: list # the fields to include for returned resources of type perfPowerMetrics
  --fields-app-infos: list # the fields to include for returned resources of type appInfos
  --fields-app-pre-orders: list # the fields to include for returned resources of type appPreOrders
  --fields-pre-release-versions: list # the fields to include for returned resources of type preReleaseVersions
  --fields-app-prices: list # the fields to include for returned resources of type appPrices
  --fields-in-app-purchases: list # the fields to include for returned resources of type inAppPurchases
  --fields-beta-app-review-details: list # the fields to include for returned resources of type betaAppReviewDetails
  --fields-territories: list # the fields to include for returned resources of type territories
  --fields-game-center-enabled-versions: list # the fields to include for returned resources of type gameCenterEnabledVersions
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-beta-app-localizations: list # the fields to include for returned resources of type betaAppLocalizations
  --fields-beta-license-agreements: list # the fields to include for returned resources of type betaLicenseAgreements
  --fields-end-user-license-agreements: list # the fields to include for returned resources of type endUserLicenseAgreements
  --limit-app-infos: int # maximum number of related appInfos returned (when they are included)
  --limit-app-store-versions: int # maximum number of related appStoreVersions returned (when they are included)
  --limit-available-territories: int # maximum number of related availableTerritories returned (when they are included)
  --limit-beta-app-localizations: int # maximum number of related betaAppLocalizations returned (when they are included)
  --limit-beta-groups: int # maximum number of related betaGroups returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
  --limit-game-center-enabled-versions: int # maximum number of related gameCenterEnabledVersions returned (when they are included)
  --limit-in-app-purchases: int # maximum number of related inAppPurchases returned (when they are included)
  --limit-pre-release-versions: int # maximum number of related preReleaseVersions returned (when they are included)
  --limit-prices: int # maximum number of related prices returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[appStoreVersions.appStoreState]" $filter_app_store_versions_app_store_state "csv") (serialize-qp "filter[appStoreVersions.platform]" $filter_app_store_versions_platform "csv") (serialize-qp "filter[bundleId]" $filter_bundle_id "csv") (serialize-qp "filter[name]" $filter_name "csv") (serialize-qp "filter[sku]" $filter_sku "csv") (serialize-qp "filter[appStoreVersions]" $filter_app_store_versions "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "exists[gameCenterEnabledVersions]" $exists_game_center_enabled_versions "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[betaGroups]" $fields_beta_groups "csv") (serialize-qp "fields[perfPowerMetrics]" $fields_perf_power_metrics "csv") (serialize-qp "fields[appInfos]" $fields_app_infos "csv") (serialize-qp "fields[appPreOrders]" $fields_app_pre_orders "csv") (serialize-qp "fields[preReleaseVersions]" $fields_pre_release_versions "csv") (serialize-qp "fields[appPrices]" $fields_app_prices "csv") (serialize-qp "fields[inAppPurchases]" $fields_in_app_purchases "csv") (serialize-qp "fields[betaAppReviewDetails]" $fields_beta_app_review_details "csv") (serialize-qp "fields[territories]" $fields_territories "csv") (serialize-qp "fields[gameCenterEnabledVersions]" $fields_game_center_enabled_versions "csv") (serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[betaAppLocalizations]" $fields_beta_app_localizations "csv") (serialize-qp "fields[betaLicenseAgreements]" $fields_beta_license_agreements "csv") (serialize-qp "fields[endUserLicenseAgreements]" $fields_end_user_license_agreements "csv") (serialize-qp "limit[appInfos]" $limit_app_infos "scalar") (serialize-qp "limit[appStoreVersions]" $limit_app_store_versions "scalar") (serialize-qp "limit[availableTerritories]" $limit_available_territories "scalar") (serialize-qp "limit[betaAppLocalizations]" $limit_beta_app_localizations "scalar") (serialize-qp "limit[betaGroups]" $limit_beta_groups "scalar") (serialize-qp "limit[builds]" $limit_builds "scalar") (serialize-qp "limit[gameCenterEnabledVersions]" $limit_game_center_enabled_versions "scalar") (serialize-qp "limit[inAppPurchases]" $limit_in_app_purchases "scalar") (serialize-qp "limit[preReleaseVersions]" $limit_pre_release_versions "scalar") (serialize-qp "limit[prices]" $limit_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/apps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}
#
# operationId: apps-get_instance
export def "apps instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
  --include: list # comma-separated list of relationships to include
  --fields-beta-groups: list # the fields to include for returned resources of type betaGroups
  --fields-perf-power-metrics: list # the fields to include for returned resources of type perfPowerMetrics
  --fields-app-infos: list # the fields to include for returned resources of type appInfos
  --fields-app-pre-orders: list # the fields to include for returned resources of type appPreOrders
  --fields-pre-release-versions: list # the fields to include for returned resources of type preReleaseVersions
  --fields-app-prices: list # the fields to include for returned resources of type appPrices
  --fields-in-app-purchases: list # the fields to include for returned resources of type inAppPurchases
  --fields-beta-app-review-details: list # the fields to include for returned resources of type betaAppReviewDetails
  --fields-territories: list # the fields to include for returned resources of type territories
  --fields-game-center-enabled-versions: list # the fields to include for returned resources of type gameCenterEnabledVersions
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-beta-app-localizations: list # the fields to include for returned resources of type betaAppLocalizations
  --fields-beta-license-agreements: list # the fields to include for returned resources of type betaLicenseAgreements
  --fields-end-user-license-agreements: list # the fields to include for returned resources of type endUserLicenseAgreements
  --limit-app-infos: int # maximum number of related appInfos returned (when they are included)
  --limit-app-store-versions: int # maximum number of related appStoreVersions returned (when they are included)
  --limit-available-territories: int # maximum number of related availableTerritories returned (when they are included)
  --limit-beta-app-localizations: int # maximum number of related betaAppLocalizations returned (when they are included)
  --limit-beta-groups: int # maximum number of related betaGroups returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
  --limit-game-center-enabled-versions: int # maximum number of related gameCenterEnabledVersions returned (when they are included)
  --limit-in-app-purchases: int # maximum number of related inAppPurchases returned (when they are included)
  --limit-pre-release-versions: int # maximum number of related preReleaseVersions returned (when they are included)
  --limit-prices: int # maximum number of related prices returned (when they are included)
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[betaGroups]" $fields_beta_groups "csv") (serialize-qp "fields[perfPowerMetrics]" $fields_perf_power_metrics "csv") (serialize-qp "fields[appInfos]" $fields_app_infos "csv") (serialize-qp "fields[appPreOrders]" $fields_app_pre_orders "csv") (serialize-qp "fields[preReleaseVersions]" $fields_pre_release_versions "csv") (serialize-qp "fields[appPrices]" $fields_app_prices "csv") (serialize-qp "fields[inAppPurchases]" $fields_in_app_purchases "csv") (serialize-qp "fields[betaAppReviewDetails]" $fields_beta_app_review_details "csv") (serialize-qp "fields[territories]" $fields_territories "csv") (serialize-qp "fields[gameCenterEnabledVersions]" $fields_game_center_enabled_versions "csv") (serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[betaAppLocalizations]" $fields_beta_app_localizations "csv") (serialize-qp "fields[betaLicenseAgreements]" $fields_beta_license_agreements "csv") (serialize-qp "fields[endUserLicenseAgreements]" $fields_end_user_license_agreements "csv") (serialize-qp "limit[appInfos]" $limit_app_infos "scalar") (serialize-qp "limit[appStoreVersions]" $limit_app_store_versions "scalar") (serialize-qp "limit[availableTerritories]" $limit_available_territories "scalar") (serialize-qp "limit[betaAppLocalizations]" $limit_beta_app_localizations "scalar") (serialize-qp "limit[betaGroups]" $limit_beta_groups "scalar") (serialize-qp "limit[builds]" $limit_builds "scalar") (serialize-qp "limit[gameCenterEnabledVersions]" $limit_game_center_enabled_versions "scalar") (serialize-qp "limit[inAppPurchases]" $limit_in_app_purchases "scalar") (serialize-qp "limit[preReleaseVersions]" $limit_pre_release_versions "scalar") (serialize-qp "limit[prices]" $limit_prices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/apps/{id}
#
# operationId: apps-update_instance
# --data shape: {attributes?: record, id: string, relationships?: record, type: "apps"}
export def "apps instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "apps"}
]: any -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/apps/{id}/appInfos
#
# operationId: apps-appInfos-get_to_many_related
export def "apps-app-infos related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-age-rating-declarations: list # the fields to include for returned resources of type ageRatingDeclarations
  --fields-app-infos: list # the fields to include for returned resources of type appInfos
  --fields-app-categories: list # the fields to include for returned resources of type appCategories
  --fields-app-info-localizations: list # the fields to include for returned resources of type appInfoLocalizations
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[ageRatingDeclarations]" $fields_age_rating_declarations "csv") (serialize-qp "fields[appInfos]" $fields_app_infos "csv") (serialize-qp "fields[appCategories]" $fields_app_categories "csv") (serialize-qp "fields[appInfoLocalizations]" $fields_app_info_localizations "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/appInfos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/appStoreVersions
#
# operationId: apps-appStoreVersions-get_to_many_related
export def "apps-app-store-versions related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-app-store-state: list # filter by attribute 'appStoreState'
  --filter-platform: list # filter by attribute 'platform'
  --filter-version-string: list # filter by attribute 'versionString'
  --filter-id: list # filter by id(s)
  --fields-idfa-declarations: list # the fields to include for returned resources of type idfaDeclarations
  --fields-app-store-version-localizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --fields-routing-app-coverages: list # the fields to include for returned resources of type routingAppCoverages
  --fields-app-store-version-phased-releases: list # the fields to include for returned resources of type appStoreVersionPhasedReleases
  --fields-age-rating-declarations: list # the fields to include for returned resources of type ageRatingDeclarations
  --fields-app-store-review-details: list # the fields to include for returned resources of type appStoreReviewDetails
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-app-store-version-submissions: list # the fields to include for returned resources of type appStoreVersionSubmissions
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[appStoreState]" $filter_app_store_state "csv") (serialize-qp "filter[platform]" $filter_platform "csv") (serialize-qp "filter[versionString]" $filter_version_string "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "fields[idfaDeclarations]" $fields_idfa_declarations "csv") (serialize-qp "fields[appStoreVersionLocalizations]" $fields_app_store_version_localizations "csv") (serialize-qp "fields[routingAppCoverages]" $fields_routing_app_coverages "csv") (serialize-qp "fields[appStoreVersionPhasedReleases]" $fields_app_store_version_phased_releases "csv") (serialize-qp "fields[ageRatingDeclarations]" $fields_age_rating_declarations "csv") (serialize-qp "fields[appStoreReviewDetails]" $fields_app_store_review_details "csv") (serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[appStoreVersionSubmissions]" $fields_app_store_version_submissions "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/appStoreVersions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/availableTerritories
#
# operationId: apps-availableTerritories-get_to_many_related
export def "apps-available-territories related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-territories: list # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[territories]" $fields_territories "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/availableTerritories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/betaAppLocalizations
#
# operationId: apps-betaAppLocalizations-get_to_many_related
export def "apps-beta-app-localizations related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-app-localizations: list # the fields to include for returned resources of type betaAppLocalizations
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppLocalizations]" $fields_beta_app_localizations "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/betaAppLocalizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/betaAppReviewDetail
#
# operationId: apps-betaAppReviewDetail-get_to_one_related
export def "apps-beta-app-review-detail related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-app-review-details: list # the fields to include for returned resources of type betaAppReviewDetails
]: nothing -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppReviewDetails]" $fields_beta_app_review_details "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/betaAppReviewDetail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/betaGroups
#
# operationId: apps-betaGroups-get_to_many_related
export def "apps-beta-groups related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-groups: list # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaGroups]" $fields_beta_groups "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/betaGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/betaLicenseAgreement
#
# operationId: apps-betaLicenseAgreement-get_to_one_related
export def "apps-beta-license-agreement related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-license-agreements: list # the fields to include for returned resources of type betaLicenseAgreements
]: nothing -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaLicenseAgreements]" $fields_beta_license_agreements "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/betaLicenseAgreement") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/builds
#
# operationId: apps-builds-get_to_many_related
export def "apps-builds related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/builds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/endUserLicenseAgreement
#
# operationId: apps-endUserLicenseAgreement-get_to_one_related
export def "apps-end-user-license-agreement related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-end-user-license-agreements: list # the fields to include for returned resources of type endUserLicenseAgreements
]: nothing -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[endUserLicenseAgreements]" $fields_end_user_license_agreements "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/endUserLicenseAgreement") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/gameCenterEnabledVersions
#
# operationId: apps-gameCenterEnabledVersions-get_to_many_related
export def "apps-game-center-enabled-versions related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-platform: list # filter by attribute 'platform'
  --filter-version-string: list # filter by attribute 'versionString'
  --filter-id: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-game-center-enabled-versions: list # the fields to include for returned resources of type gameCenterEnabledVersions
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[platform]" $filter_platform "csv") (serialize-qp "filter[versionString]" $filter_version_string "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[gameCenterEnabledVersions]" $fields_game_center_enabled_versions "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/gameCenterEnabledVersions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/inAppPurchases
#
# operationId: apps-inAppPurchases-get_to_many_related
export def "apps-in-app-purchases related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-in-app-purchase-type: list # filter by attribute 'inAppPurchaseType'
  --filter-can-be-submitted: list # filter by canBeSubmitted
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-in-app-purchases: list # the fields to include for returned resources of type inAppPurchases
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[inAppPurchaseType]" $filter_in_app_purchase_type "csv") (serialize-qp "filter[canBeSubmitted]" $filter_can_be_submitted "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[inAppPurchases]" $fields_in_app_purchases "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/inAppPurchases") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/perfPowerMetrics
#
# operationId: apps-perfPowerMetrics-get_to_many_related
export def "apps-perf-power-metrics related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-device-type: list # filter by attribute 'deviceType'
  --filter-metric-type: list # filter by attribute 'metricType'
  --filter-platform: list # filter by attribute 'platform'
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[deviceType]" $filter_device_type "csv") (serialize-qp "filter[metricType]" $filter_metric_type "csv") (serialize-qp "filter[platform]" $filter_platform "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/perfPowerMetrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/preOrder
#
# operationId: apps-preOrder-get_to_one_related
export def "apps-pre-order related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-pre-orders: list # the fields to include for returned resources of type appPreOrders
]: nothing -> record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreOrders]" $fields_app_pre_orders "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/preOrder") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/preReleaseVersions
#
# operationId: apps-preReleaseVersions-get_to_many_related
export def "apps-pre-release-versions related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-pre-release-versions: list # the fields to include for returned resources of type preReleaseVersions
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[preReleaseVersions]" $fields_pre_release_versions "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/preReleaseVersions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/apps/{id}/prices
#
# operationId: apps-prices-get_to_many_related
export def "apps-prices related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-prices: list # the fields to include for returned resources of type appPrices
  --fields-app-price-tiers: list # the fields to include for returned resources of type appPriceTiers
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPrices]" $fields_app_prices "csv") (serialize-qp "fields[appPriceTiers]" $fields_app_price_tiers "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/prices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/apps/{id}/relationships/betaTesters
#
# operationId: apps-betaTesters-delete_to_many_relationship
# --data item shape: {id: string, type: "betaTesters"}
export def "apps-relationships-beta-testers relationship" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/apps/{id}/relationships/betaTesters"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaAppLocalizations
#
# operationId: betaAppLocalizations-get_collection
export def "beta-app-localizations collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-locale: list # filter by attribute 'locale'
  --filter-app: list # filter by id(s) of related 'app'
  --fields-beta-app-localizations: list # the fields to include for returned resources of type betaAppLocalizations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[locale]" $filter_locale "csv") (serialize-qp "filter[app]" $filter_app "csv") (serialize-qp "fields[betaAppLocalizations]" $fields_beta_app_localizations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/betaAppLocalizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaAppLocalizations
#
# operationId: betaAppLocalizations-create_instance
# --data shape: {attributes: record, relationships: record, type: "betaAppLocalizations"}
export def "beta-app-localizations instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "betaAppLocalizations"}
]: any -> record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/betaAppLocalizations")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/betaAppLocalizations/{id}
#
# operationId: betaAppLocalizations-delete_instance
export def "beta-app-localizations instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppLocalizations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaAppLocalizations/{id}
#
# operationId: betaAppLocalizations-get_instance
export def "beta-app-localizations instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-app-localizations: list # the fields to include for returned resources of type betaAppLocalizations
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppLocalizations]" $fields_beta_app_localizations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppLocalizations/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/betaAppLocalizations/{id}
#
# operationId: betaAppLocalizations-update_instance
# --data shape: {attributes?: record, id: string, type: "betaAppLocalizations"}
export def "beta-app-localizations instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "betaAppLocalizations"}
]: any -> record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppLocalizations/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaAppLocalizations/{id}/app
#
# operationId: betaAppLocalizations-app-get_to_one_related
export def "beta-app-localizations-app related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppLocalizations/{id}/app") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaAppReviewDetails
#
# operationId: betaAppReviewDetails-get_collection
export def "beta-app-review-details collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-app: list # filter by id(s) of related 'app'
  --fields-beta-app-review-details: list # the fields to include for returned resources of type betaAppReviewDetails
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[app]" $filter_app "csv") (serialize-qp "fields[betaAppReviewDetails]" $fields_beta_app_review_details "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/betaAppReviewDetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaAppReviewDetails/{id}
#
# operationId: betaAppReviewDetails-get_instance
export def "beta-app-review-details instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-app-review-details: list # the fields to include for returned resources of type betaAppReviewDetails
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppReviewDetails]" $fields_beta_app_review_details "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppReviewDetails/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/betaAppReviewDetails/{id}
#
# operationId: betaAppReviewDetails-update_instance
# --data shape: {attributes?: record, id: string, type: "betaAppReviewDetails"}
export def "beta-app-review-details instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "betaAppReviewDetails"}
]: any -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppReviewDetails/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaAppReviewDetails/{id}/app
#
# operationId: betaAppReviewDetails-app-get_to_one_related
export def "beta-app-review-details-app related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppReviewDetails/{id}/app") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaAppReviewSubmissions
#
# operationId: betaAppReviewSubmissions-get_collection
export def "beta-app-review-submissions collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-beta-review-state: list # filter by attribute 'betaReviewState'
  --filter-build: list # filter by id(s) of related 'build'
  --fields-beta-app-review-submissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[betaReviewState]" $filter_beta_review_state "csv") (serialize-qp "filter[build]" $filter_build "csv") (serialize-qp "fields[betaAppReviewSubmissions]" $fields_beta_app_review_submissions "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/betaAppReviewSubmissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaAppReviewSubmissions
#
# operationId: betaAppReviewSubmissions-create_instance
# --data shape: {relationships: record, type: "betaAppReviewSubmissions"}
export def "beta-app-review-submissions instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {relationships: record, type: "betaAppReviewSubmissions"}
]: any -> record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/betaAppReviewSubmissions")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaAppReviewSubmissions/{id}
#
# operationId: betaAppReviewSubmissions-get_instance
export def "beta-app-review-submissions instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-app-review-submissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppReviewSubmissions]" $fields_beta_app_review_submissions "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppReviewSubmissions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaAppReviewSubmissions/{id}/build
#
# operationId: betaAppReviewSubmissions-build-get_to_one_related
export def "beta-app-review-submissions-build related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaAppReviewSubmissions/{id}/build") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaBuildLocalizations
#
# operationId: betaBuildLocalizations-get_collection
export def "beta-build-localizations collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-locale: list # filter by attribute 'locale'
  --filter-build: list # filter by id(s) of related 'build'
  --fields-beta-build-localizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[locale]" $filter_locale "csv") (serialize-qp "filter[build]" $filter_build "csv") (serialize-qp "fields[betaBuildLocalizations]" $fields_beta_build_localizations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/betaBuildLocalizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaBuildLocalizations
#
# operationId: betaBuildLocalizations-create_instance
# --data shape: {attributes: record, relationships: record, type: "betaBuildLocalizations"}
export def "beta-build-localizations instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "betaBuildLocalizations"}
]: any -> record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/betaBuildLocalizations")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/betaBuildLocalizations/{id}
#
# operationId: betaBuildLocalizations-delete_instance
export def "beta-build-localizations instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaBuildLocalizations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaBuildLocalizations/{id}
#
# operationId: betaBuildLocalizations-get_instance
export def "beta-build-localizations instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-build-localizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaBuildLocalizations]" $fields_beta_build_localizations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaBuildLocalizations/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/betaBuildLocalizations/{id}
#
# operationId: betaBuildLocalizations-update_instance
# --data shape: {attributes?: record, id: string, type: "betaBuildLocalizations"}
export def "beta-build-localizations instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "betaBuildLocalizations"}
]: any -> record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaBuildLocalizations/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaBuildLocalizations/{id}/build
#
# operationId: betaBuildLocalizations-build-get_to_one_related
export def "beta-build-localizations-build related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaBuildLocalizations/{id}/build") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaGroups
#
# operationId: betaGroups-get_collection
export def "beta-groups collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-is-internal-group: list # filter by attribute 'isInternalGroup'
  --filter-name: list # filter by attribute 'name'
  --filter-public-link: list # filter by attribute 'publicLink'
  --filter-public-link-enabled: list # filter by attribute 'publicLinkEnabled'
  --filter-public-link-limit-enabled: list # filter by attribute 'publicLinkLimitEnabled'
  --filter-app: list # filter by id(s) of related 'app'
  --filter-builds: list # filter by id(s) of related 'builds'
  --filter-id: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-beta-groups: list # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-beta-testers: list # the fields to include for returned resources of type betaTesters
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-beta-testers: int # maximum number of related betaTesters returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[isInternalGroup]" $filter_is_internal_group "csv") (serialize-qp "filter[name]" $filter_name "csv") (serialize-qp "filter[publicLink]" $filter_public_link "csv") (serialize-qp "filter[publicLinkEnabled]" $filter_public_link_enabled "csv") (serialize-qp "filter[publicLinkLimitEnabled]" $filter_public_link_limit_enabled "csv") (serialize-qp "filter[app]" $filter_app "csv") (serialize-qp "filter[builds]" $filter_builds "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[betaGroups]" $fields_beta_groups "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[betaTesters]" $fields_beta_testers "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[betaTesters]" $limit_beta_testers "scalar") (serialize-qp "limit[builds]" $limit_builds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/betaGroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaGroups
#
# operationId: betaGroups-create_instance
# --data shape: {attributes: record, relationships: record, type: "betaGroups"}
export def "beta-groups instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "betaGroups"}
]: any -> record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/betaGroups")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/betaGroups/{id}
#
# operationId: betaGroups-delete_instance
export def "beta-groups instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaGroups/{id}
#
# operationId: betaGroups-get_instance
export def "beta-groups instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-groups: list # the fields to include for returned resources of type betaGroups
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-beta-testers: list # the fields to include for returned resources of type betaTesters
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-beta-testers: int # maximum number of related betaTesters returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaGroups]" $fields_beta_groups "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[betaTesters]" $fields_beta_testers "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[betaTesters]" $limit_beta_testers "scalar") (serialize-qp "limit[builds]" $limit_builds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/betaGroups/{id}
#
# operationId: betaGroups-update_instance
# --data shape: {attributes?: record, id: string, type: "betaGroups"}
export def "beta-groups instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "betaGroups"}
]: any -> record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaGroups/{id}/app
#
# operationId: betaGroups-app-get_to_one_related
export def "beta-groups-app related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/app") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaGroups/{id}/betaTesters
#
# operationId: betaGroups-betaTesters-get_to_many_related
export def "beta-groups-beta-testers related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-testers: list # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaTesters]" $fields_beta_testers "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/betaTesters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaGroups/{id}/builds
#
# operationId: betaGroups-builds-get_to_many_related
export def "beta-groups-builds related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/builds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/betaGroups/{id}/relationships/betaTesters
#
# operationId: betaGroups-betaTesters-delete_to_many_relationship
# --data item shape: {id: string, type: "betaTesters"}
export def "beta-groups-relationships-beta-testers relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/relationships/betaTesters"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaGroups/{id}/relationships/betaTesters
#
# operationId: betaGroups-betaTesters-get_to_many_relationship
export def "beta-groups-relationships-beta-testers relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/relationships/betaTesters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaGroups/{id}/relationships/betaTesters
#
# operationId: betaGroups-betaTesters-create_to_many_relationship
# --data item shape: {id: string, type: "betaTesters"}
export def "beta-groups-relationships-beta-testers relationship-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/relationships/betaTesters"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/betaGroups/{id}/relationships/builds
#
# operationId: betaGroups-builds-delete_to_many_relationship
# --data item shape: {id: string, type: "builds"}
export def "beta-groups-relationships-builds relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/relationships/builds"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaGroups/{id}/relationships/builds
#
# operationId: betaGroups-builds-get_to_many_relationship
export def "beta-groups-relationships-builds relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/relationships/builds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaGroups/{id}/relationships/builds
#
# operationId: betaGroups-builds-create_to_many_relationship
# --data item shape: {id: string, type: "builds"}
export def "beta-groups-relationships-builds relationship-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaGroups/{id}/relationships/builds"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaLicenseAgreements
#
# operationId: betaLicenseAgreements-get_collection
export def "beta-license-agreements collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-app: list # filter by id(s) of related 'app'
  --fields-beta-license-agreements: list # the fields to include for returned resources of type betaLicenseAgreements
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[app]" $filter_app "csv") (serialize-qp "fields[betaLicenseAgreements]" $fields_beta_license_agreements "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/betaLicenseAgreements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaLicenseAgreements/{id}
#
# operationId: betaLicenseAgreements-get_instance
export def "beta-license-agreements instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-license-agreements: list # the fields to include for returned resources of type betaLicenseAgreements
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaLicenseAgreements]" $fields_beta_license_agreements "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaLicenseAgreements/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/betaLicenseAgreements/{id}
#
# operationId: betaLicenseAgreements-update_instance
# --data shape: {attributes?: record, id: string, type: "betaLicenseAgreements"}
export def "beta-license-agreements instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "betaLicenseAgreements"}
]: any -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaLicenseAgreements/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaLicenseAgreements/{id}/app
#
# operationId: betaLicenseAgreements-app-get_to_one_related
export def "beta-license-agreements-app related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaLicenseAgreements/{id}/app") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaTesterInvitations
#
# operationId: betaTesterInvitations-create_instance
# --data shape: {relationships: record, type: "betaTesterInvitations"}
export def "beta-tester-invitations instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {relationships: record, type: "betaTesterInvitations"}
]: any -> record<data: record<id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/betaTesterInvitations")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaTesters
#
# operationId: betaTesters-get_collection
export def "beta-testers collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-email: list # filter by attribute 'email'
  --filter-first-name: list # filter by attribute 'firstName'
  --filter-invite-type: list # filter by attribute 'inviteType'
  --filter-last-name: list # filter by attribute 'lastName'
  --filter-apps: list # filter by id(s) of related 'apps'
  --filter-beta-groups: list # filter by id(s) of related 'betaGroups'
  --filter-builds: list # filter by id(s) of related 'builds'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-beta-testers: list # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-beta-groups: list # the fields to include for returned resources of type betaGroups
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-apps: int # maximum number of related apps returned (when they are included)
  --limit-beta-groups: int # maximum number of related betaGroups returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[email]" $filter_email "csv") (serialize-qp "filter[firstName]" $filter_first_name "csv") (serialize-qp "filter[inviteType]" $filter_invite_type "csv") (serialize-qp "filter[lastName]" $filter_last_name "csv") (serialize-qp "filter[apps]" $filter_apps "csv") (serialize-qp "filter[betaGroups]" $filter_beta_groups "csv") (serialize-qp "filter[builds]" $filter_builds "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[betaTesters]" $fields_beta_testers "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[betaGroups]" $fields_beta_groups "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[apps]" $limit_apps "scalar") (serialize-qp "limit[betaGroups]" $limit_beta_groups "scalar") (serialize-qp "limit[builds]" $limit_builds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/betaTesters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaTesters
#
# operationId: betaTesters-create_instance
# --data shape: {attributes: record, relationships?: record, type: "betaTesters"}
export def "beta-testers instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships?: record, type: "betaTesters"}
]: any -> record<data: record<attributes: record<email: string, firstName: string, inviteType: string, lastName: string>, id: string, links: record<self: string>, relationships: record<apps: record, betaGroups: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/betaTesters")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/betaTesters/{id}
#
# operationId: betaTesters-delete_instance
export def "beta-testers instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaTesters/{id}
#
# operationId: betaTesters-get_instance
export def "beta-testers instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-testers: list # the fields to include for returned resources of type betaTesters
  --include: list # comma-separated list of relationships to include
  --fields-beta-groups: list # the fields to include for returned resources of type betaGroups
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-apps: int # maximum number of related apps returned (when they are included)
  --limit-beta-groups: int # maximum number of related betaGroups returned (when they are included)
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: record<attributes: record<email: string, firstName: string, inviteType: string, lastName: string>, id: string, links: record<self: string>, relationships: record<apps: record, betaGroups: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaTesters]" $fields_beta_testers "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[betaGroups]" $fields_beta_groups "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[apps]" $limit_apps "scalar") (serialize-qp "limit[betaGroups]" $limit_beta_groups "scalar") (serialize-qp "limit[builds]" $limit_builds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaTesters/{id}/apps
#
# operationId: betaTesters-apps-get_to_many_related
export def "beta-testers-apps related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/apps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaTesters/{id}/betaGroups
#
# operationId: betaTesters-betaGroups-get_to_many_related
export def "beta-testers-beta-groups related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-groups: list # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaGroups]" $fields_beta_groups "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/betaGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/betaTesters/{id}/builds
#
# operationId: betaTesters-builds-get_to_many_related
export def "beta-testers-builds related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/builds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/betaTesters/{id}/relationships/apps
#
# operationId: betaTesters-apps-delete_to_many_relationship
# --data item shape: {id: string, type: "apps"}
export def "beta-testers-relationships-apps relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "apps"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/relationships/apps"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaTesters/{id}/relationships/apps
#
# operationId: betaTesters-apps-get_to_many_relationship
export def "beta-testers-relationships-apps relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/relationships/apps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/betaTesters/{id}/relationships/betaGroups
#
# operationId: betaTesters-betaGroups-delete_to_many_relationship
# --data item shape: {id: string, type: "betaGroups"}
export def "beta-testers-relationships-beta-groups relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaGroups"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/relationships/betaGroups"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaTesters/{id}/relationships/betaGroups
#
# operationId: betaTesters-betaGroups-get_to_many_relationship
export def "beta-testers-relationships-beta-groups relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/relationships/betaGroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaTesters/{id}/relationships/betaGroups
#
# operationId: betaTesters-betaGroups-create_to_many_relationship
# --data item shape: {id: string, type: "betaGroups"}
export def "beta-testers-relationships-beta-groups relationship-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaGroups"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/relationships/betaGroups"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/betaTesters/{id}/relationships/builds
#
# operationId: betaTesters-builds-delete_to_many_relationship
# --data item shape: {id: string, type: "builds"}
export def "beta-testers-relationships-builds relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/relationships/builds"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/betaTesters/{id}/relationships/builds
#
# operationId: betaTesters-builds-get_to_many_relationship
export def "beta-testers-relationships-builds relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/relationships/builds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/betaTesters/{id}/relationships/builds
#
# operationId: betaTesters-builds-create_to_many_relationship
# --data item shape: {id: string, type: "builds"}
export def "beta-testers-relationships-builds relationship-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "builds"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/betaTesters/{id}/relationships/builds"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/buildBetaDetails
#
# operationId: buildBetaDetails-get_collection
export def "build-beta-details collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-build: list # filter by id(s) of related 'build'
  --filter-id: list # filter by id(s)
  --fields-build-beta-details: list # the fields to include for returned resources of type buildBetaDetails
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[build]" $filter_build "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "fields[buildBetaDetails]" $fields_build_beta_details "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/buildBetaDetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/buildBetaDetails/{id}
#
# operationId: buildBetaDetails-get_instance
export def "build-beta-details instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-build-beta-details: list # the fields to include for returned resources of type buildBetaDetails
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[buildBetaDetails]" $fields_build_beta_details "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/buildBetaDetails/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/buildBetaDetails/{id}
#
# operationId: buildBetaDetails-update_instance
# --data shape: {attributes?: record, id: string, type: "buildBetaDetails"}
export def "build-beta-details instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "buildBetaDetails"}
]: any -> record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/buildBetaDetails/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/buildBetaDetails/{id}/build
#
# operationId: buildBetaDetails-build-get_to_one_related
export def "build-beta-details-build related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/buildBetaDetails/{id}/build") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/buildBetaNotifications
#
# operationId: buildBetaNotifications-create_instance
# --data shape: {relationships: record, type: "buildBetaNotifications"}
export def "build-beta-notifications instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {relationships: record, type: "buildBetaNotifications"}
]: any -> record<data: record<id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/buildBetaNotifications")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/builds
#
# operationId: builds-get_collection
export def "builds collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-beta-app-review-submission-beta-review-state: list # filter by attribute 'betaAppReviewSubmission.betaReviewState'
  --filter-expired: list # filter by attribute 'expired'
  --filter-pre-release-version-platform: list # filter by attribute 'preReleaseVersion.platform'
  --filter-pre-release-version-version: list # filter by attribute 'preReleaseVersion.version'
  --filter-processing-state: list # filter by attribute 'processingState'
  --filter-uses-non-exempt-encryption: list # filter by attribute 'usesNonExemptEncryption'
  --filter-version: list # filter by attribute 'version'
  --filter-app: list # filter by id(s) of related 'app'
  --filter-app-store-version: list # filter by id(s) of related 'appStoreVersion'
  --filter-beta-groups: list # filter by id(s) of related 'betaGroups'
  --filter-pre-release-version: list # filter by id(s) of related 'preReleaseVersion'
  --filter-id: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-builds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-app-encryption-declarations: list # the fields to include for returned resources of type appEncryptionDeclarations
  --fields-beta-app-review-submissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
  --fields-build-beta-details: list # the fields to include for returned resources of type buildBetaDetails
  --fields-build-icons: list # the fields to include for returned resources of type buildIcons
  --fields-perf-power-metrics: list # the fields to include for returned resources of type perfPowerMetrics
  --fields-pre-release-versions: list # the fields to include for returned resources of type preReleaseVersions
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
  --fields-diagnostic-signatures: list # the fields to include for returned resources of type diagnosticSignatures
  --fields-beta-testers: list # the fields to include for returned resources of type betaTesters
  --fields-beta-build-localizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-beta-build-localizations: int # maximum number of related betaBuildLocalizations returned (when they are included)
  --limit-icons: int # maximum number of related icons returned (when they are included)
  --limit-individual-testers: int # maximum number of related individualTesters returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[betaAppReviewSubmission.betaReviewState]" $filter_beta_app_review_submission_beta_review_state "csv") (serialize-qp "filter[expired]" $filter_expired "csv") (serialize-qp "filter[preReleaseVersion.platform]" $filter_pre_release_version_platform "csv") (serialize-qp "filter[preReleaseVersion.version]" $filter_pre_release_version_version "csv") (serialize-qp "filter[processingState]" $filter_processing_state "csv") (serialize-qp "filter[usesNonExemptEncryption]" $filter_uses_non_exempt_encryption "csv") (serialize-qp "filter[version]" $filter_version "csv") (serialize-qp "filter[app]" $filter_app "csv") (serialize-qp "filter[appStoreVersion]" $filter_app_store_version "csv") (serialize-qp "filter[betaGroups]" $filter_beta_groups "csv") (serialize-qp "filter[preReleaseVersion]" $filter_pre_release_version "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[appEncryptionDeclarations]" $fields_app_encryption_declarations "csv") (serialize-qp "fields[betaAppReviewSubmissions]" $fields_beta_app_review_submissions "csv") (serialize-qp "fields[buildBetaDetails]" $fields_build_beta_details "csv") (serialize-qp "fields[buildIcons]" $fields_build_icons "csv") (serialize-qp "fields[perfPowerMetrics]" $fields_perf_power_metrics "csv") (serialize-qp "fields[preReleaseVersions]" $fields_pre_release_versions "csv") (serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv") (serialize-qp "fields[diagnosticSignatures]" $fields_diagnostic_signatures "csv") (serialize-qp "fields[betaTesters]" $fields_beta_testers "csv") (serialize-qp "fields[betaBuildLocalizations]" $fields_beta_build_localizations "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[betaBuildLocalizations]" $limit_beta_build_localizations "scalar") (serialize-qp "limit[icons]" $limit_icons "scalar") (serialize-qp "limit[individualTesters]" $limit_individual_testers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/builds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}
#
# operationId: builds-get_instance
export def "builds instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
  --include: list # comma-separated list of relationships to include
  --fields-app-encryption-declarations: list # the fields to include for returned resources of type appEncryptionDeclarations
  --fields-beta-app-review-submissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
  --fields-build-beta-details: list # the fields to include for returned resources of type buildBetaDetails
  --fields-build-icons: list # the fields to include for returned resources of type buildIcons
  --fields-perf-power-metrics: list # the fields to include for returned resources of type perfPowerMetrics
  --fields-pre-release-versions: list # the fields to include for returned resources of type preReleaseVersions
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
  --fields-diagnostic-signatures: list # the fields to include for returned resources of type diagnosticSignatures
  --fields-beta-testers: list # the fields to include for returned resources of type betaTesters
  --fields-beta-build-localizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-beta-build-localizations: int # maximum number of related betaBuildLocalizations returned (when they are included)
  --limit-icons: int # maximum number of related icons returned (when they are included)
  --limit-individual-testers: int # maximum number of related individualTesters returned (when they are included)
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appEncryptionDeclarations]" $fields_app_encryption_declarations "csv") (serialize-qp "fields[betaAppReviewSubmissions]" $fields_beta_app_review_submissions "csv") (serialize-qp "fields[buildBetaDetails]" $fields_build_beta_details "csv") (serialize-qp "fields[buildIcons]" $fields_build_icons "csv") (serialize-qp "fields[perfPowerMetrics]" $fields_perf_power_metrics "csv") (serialize-qp "fields[preReleaseVersions]" $fields_pre_release_versions "csv") (serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv") (serialize-qp "fields[diagnosticSignatures]" $fields_diagnostic_signatures "csv") (serialize-qp "fields[betaTesters]" $fields_beta_testers "csv") (serialize-qp "fields[betaBuildLocalizations]" $fields_beta_build_localizations "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[betaBuildLocalizations]" $limit_beta_build_localizations "scalar") (serialize-qp "limit[icons]" $limit_icons "scalar") (serialize-qp "limit[individualTesters]" $limit_individual_testers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/builds/{id}
#
# operationId: builds-update_instance
# --data shape: {attributes?: record, id: string, relationships?: record, type: "builds"}
export def "builds instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "builds"}
]: any -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/builds/{id}/app
#
# operationId: builds-app-get_to_one_related
export def "builds-app related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/app") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/appEncryptionDeclaration
#
# operationId: builds-appEncryptionDeclaration-get_to_one_related
export def "builds-app-encryption-declaration related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-encryption-declarations: list # the fields to include for returned resources of type appEncryptionDeclarations
]: nothing -> record<data: record<attributes: record<appEncryptionDeclarationState: string, availableOnFrenchStore: bool, codeValue: string, containsProprietaryCryptography: bool, containsThirdPartyCryptography: bool, documentName: string, documentType: string, documentUrl: string, exempt: bool, platform: string, uploadedDate: string, usesEncryption: bool>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appEncryptionDeclarations]" $fields_app_encryption_declarations "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/appEncryptionDeclaration") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/appStoreVersion
#
# operationId: builds-appStoreVersion-get_to_one_related
export def "builds-app-store-version related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-app-store-versions: list # the fields to include for returned resources of type appStoreVersions
]: nothing -> record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersions]" $fields_app_store_versions "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/appStoreVersion") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/betaAppReviewSubmission
#
# operationId: builds-betaAppReviewSubmission-get_to_one_related
export def "builds-beta-app-review-submission related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-app-review-submissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
]: nothing -> record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppReviewSubmissions]" $fields_beta_app_review_submissions "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/betaAppReviewSubmission") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/betaBuildLocalizations
#
# operationId: builds-betaBuildLocalizations-get_to_many_related
export def "builds-beta-build-localizations related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-build-localizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaBuildLocalizations]" $fields_beta_build_localizations "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/betaBuildLocalizations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/buildBetaDetail
#
# operationId: builds-buildBetaDetail-get_to_one_related
export def "builds-build-beta-detail related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-build-beta-details: list # the fields to include for returned resources of type buildBetaDetails
]: nothing -> record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[buildBetaDetails]" $fields_build_beta_details "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/buildBetaDetail") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/diagnosticSignatures
#
# operationId: builds-diagnosticSignatures-get_to_many_related
export def "builds-diagnostic-signatures related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-diagnostic-type: list # filter by attribute 'diagnosticType'
  --fields-diagnostic-signatures: list # the fields to include for returned resources of type diagnosticSignatures
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, included: table<id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[diagnosticType]" $filter_diagnostic_type "csv") (serialize-qp "fields[diagnosticSignatures]" $fields_diagnostic_signatures "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/diagnosticSignatures") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/icons
#
# operationId: builds-icons-get_to_many_related
export def "builds-icons related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-build-icons: list # the fields to include for returned resources of type buildIcons
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[buildIcons]" $fields_build_icons "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/icons") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/individualTesters
#
# operationId: builds-individualTesters-get_to_many_related
export def "builds-individual-testers related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-beta-testers: list # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaTesters]" $fields_beta_testers "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/individualTesters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/perfPowerMetrics
#
# operationId: builds-perfPowerMetrics-get_to_many_related
export def "builds-perf-power-metrics related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-device-type: list # filter by attribute 'deviceType'
  --filter-metric-type: list # filter by attribute 'metricType'
  --filter-platform: list # filter by attribute 'platform'
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[deviceType]" $filter_device_type "csv") (serialize-qp "filter[metricType]" $filter_metric_type "csv") (serialize-qp "filter[platform]" $filter_platform "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/perfPowerMetrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/preReleaseVersion
#
# operationId: builds-preReleaseVersion-get_to_one_related
export def "builds-pre-release-version related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-pre-release-versions: list # the fields to include for returned resources of type preReleaseVersions
]: nothing -> record<data: record<attributes: record<platform: string, version: string>, id: string, links: record<self: string>, relationships: record<app: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[preReleaseVersions]" $fields_pre_release_versions "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/preReleaseVersion") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/builds/{id}/relationships/appEncryptionDeclaration
#
# operationId: builds-appEncryptionDeclaration-get_to_one_relationship
export def "builds-relationships-app-encryption-declaration relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<id: string, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/relationships/appEncryptionDeclaration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/builds/{id}/relationships/appEncryptionDeclaration
#
# operationId: builds-appEncryptionDeclaration-update_to_one_relationship
# --data shape: {id: string, type: "appEncryptionDeclarations"}
export def "builds-relationships-app-encryption-declaration relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {id: string, type: "appEncryptionDeclarations"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/relationships/appEncryptionDeclaration"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/builds/{id}/relationships/betaGroups
#
# operationId: builds-betaGroups-delete_to_many_relationship
# --data item shape: {id: string, type: "betaGroups"}
export def "builds-relationships-beta-groups relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaGroups"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/relationships/betaGroups"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/builds/{id}/relationships/betaGroups
#
# operationId: builds-betaGroups-create_to_many_relationship
# --data item shape: {id: string, type: "betaGroups"}
export def "builds-relationships-beta-groups relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaGroups"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/relationships/betaGroups"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/builds/{id}/relationships/individualTesters
#
# operationId: builds-individualTesters-delete_to_many_relationship
# --data item shape: {id: string, type: "betaTesters"}
export def "builds-relationships-individual-testers relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/relationships/individualTesters"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/builds/{id}/relationships/individualTesters
#
# operationId: builds-individualTesters-get_to_many_relationship
export def "builds-relationships-individual-testers relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/relationships/individualTesters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/builds/{id}/relationships/individualTesters
#
# operationId: builds-individualTesters-create_to_many_relationship
# --data item shape: {id: string, type: "betaTesters"}
export def "builds-relationships-individual-testers relationship-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "betaTesters"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/builds/{id}/relationships/individualTesters"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/bundleIdCapabilities
#
# operationId: bundleIdCapabilities-create_instance
# --data shape: {attributes: record, relationships: record, type: "bundleIdCapabilities"}
export def "bundle-id-capabilities instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "bundleIdCapabilities"}
]: any -> record<data: record<attributes: record<capabilityType: string, settings: list>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bundleIdCapabilities")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/bundleIdCapabilities/{id}
#
# operationId: bundleIdCapabilities-delete_instance
export def "bundle-id-capabilities instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/bundleIdCapabilities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/bundleIdCapabilities/{id}
#
# operationId: bundleIdCapabilities-update_instance
# --data shape: {attributes?: record, id: string, type: "bundleIdCapabilities"}
export def "bundle-id-capabilities instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "bundleIdCapabilities"}
]: any -> record<data: record<attributes: record<capabilityType: string, settings: list>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/bundleIdCapabilities/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/bundleIds
#
# operationId: bundleIds-get_collection
export def "bundle-ids collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-identifier: list # filter by attribute 'identifier'
  --filter-name: list # filter by attribute 'name'
  --filter-platform: list # filter by attribute 'platform'
  --filter-seed-id: list # filter by attribute 'seedId'
  --filter-id: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-bundle-ids: list # the fields to include for returned resources of type bundleIds
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-bundle-id-capabilities: list # the fields to include for returned resources of type bundleIdCapabilities
  --fields-profiles: list # the fields to include for returned resources of type profiles
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-bundle-id-capabilities: int # maximum number of related bundleIdCapabilities returned (when they are included)
  --limit-profiles: int # maximum number of related profiles returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[identifier]" $filter_identifier "csv") (serialize-qp "filter[name]" $filter_name "csv") (serialize-qp "filter[platform]" $filter_platform "csv") (serialize-qp "filter[seedId]" $filter_seed_id "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[bundleIds]" $fields_bundle_ids "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[bundleIdCapabilities]" $fields_bundle_id_capabilities "csv") (serialize-qp "fields[profiles]" $fields_profiles "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[bundleIdCapabilities]" $limit_bundle_id_capabilities "scalar") (serialize-qp "limit[profiles]" $limit_profiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/bundleIds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/bundleIds
#
# operationId: bundleIds-create_instance
# --data shape: {attributes: record, type: "bundleIds"}
export def "bundle-ids instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, type: "bundleIds"}
]: any -> record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/bundleIds")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/bundleIds/{id}
#
# operationId: bundleIds-delete_instance
export def "bundle-ids instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/bundleIds/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/bundleIds/{id}
#
# operationId: bundleIds-get_instance
export def "bundle-ids instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-bundle-ids: list # the fields to include for returned resources of type bundleIds
  --include: list # comma-separated list of relationships to include
  --fields-bundle-id-capabilities: list # the fields to include for returned resources of type bundleIdCapabilities
  --fields-profiles: list # the fields to include for returned resources of type profiles
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-bundle-id-capabilities: int # maximum number of related bundleIdCapabilities returned (when they are included)
  --limit-profiles: int # maximum number of related profiles returned (when they are included)
]: nothing -> record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[bundleIds]" $fields_bundle_ids "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[bundleIdCapabilities]" $fields_bundle_id_capabilities "csv") (serialize-qp "fields[profiles]" $fields_profiles "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[bundleIdCapabilities]" $limit_bundle_id_capabilities "scalar") (serialize-qp "limit[profiles]" $limit_profiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/bundleIds/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/bundleIds/{id}
#
# operationId: bundleIds-update_instance
# --data shape: {attributes?: record, id: string, type: "bundleIds"}
export def "bundle-ids instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "bundleIds"}
]: any -> record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/bundleIds/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/bundleIds/{id}/app
#
# operationId: bundleIds-app-get_to_one_related
export def "bundle-ids-app related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/bundleIds/{id}/app") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/bundleIds/{id}/bundleIdCapabilities
#
# operationId: bundleIds-bundleIdCapabilities-get_to_many_related
export def "bundle-ids-bundle-id-capabilities related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-bundle-id-capabilities: list # the fields to include for returned resources of type bundleIdCapabilities
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[bundleIdCapabilities]" $fields_bundle_id_capabilities "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/bundleIds/{id}/bundleIdCapabilities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/bundleIds/{id}/profiles
#
# operationId: bundleIds-profiles-get_to_many_related
export def "bundle-ids-profiles related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-profiles: list # the fields to include for returned resources of type profiles
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profiles]" $fields_profiles "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/bundleIds/{id}/profiles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/certificates
#
# operationId: certificates-get_collection
export def "certificates collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-certificate-type: list # filter by attribute 'certificateType'
  --filter-display-name: list # filter by attribute 'displayName'
  --filter-serial-number: list # filter by attribute 'serialNumber'
  --filter-id: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-certificates: list # the fields to include for returned resources of type certificates
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[certificateType]" $filter_certificate_type "csv") (serialize-qp "filter[displayName]" $filter_display_name "csv") (serialize-qp "filter[serialNumber]" $filter_serial_number "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[certificates]" $fields_certificates "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/certificates
#
# operationId: certificates-create_instance
# --data shape: {attributes: record, type: "certificates"}
export def "certificates instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, type: "certificates"}
]: any -> record<data: record<attributes: record<certificateContent: string, certificateType: string, displayName: string, expirationDate: string, name: string, platform: string, serialNumber: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/certificates")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/certificates/{id}
#
# operationId: certificates-delete_instance
export def "certificates instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/certificates/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/certificates/{id}
#
# operationId: certificates-get_instance
export def "certificates instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-certificates: list # the fields to include for returned resources of type certificates
]: nothing -> record<data: record<attributes: record<certificateContent: string, certificateType: string, displayName: string, expirationDate: string, name: string, platform: string, serialNumber: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[certificates]" $fields_certificates "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/certificates/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/devices
#
# operationId: devices-get_collection
export def "devices collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: list # filter by attribute 'name'
  --filter-platform: list # filter by attribute 'platform'
  --filter-status: list # filter by attribute 'status'
  --filter-udid: list # filter by attribute 'udid'
  --filter-id: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-devices: list # the fields to include for returned resources of type devices
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filter_name "csv") (serialize-qp "filter[platform]" $filter_platform "csv") (serialize-qp "filter[status]" $filter_status "csv") (serialize-qp "filter[udid]" $filter_udid "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[devices]" $fields_devices "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/devices
#
# operationId: devices-create_instance
# --data shape: {attributes: record, type: "devices"}
export def "devices instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, type: "devices"}
]: any -> record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/devices")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/devices/{id}
#
# operationId: devices-get_instance
export def "devices instance-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-devices: list # the fields to include for returned resources of type devices
]: nothing -> record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[devices]" $fields_devices "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/devices/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/devices/{id}
#
# operationId: devices-update_instance
# --data shape: {attributes?: record, id: string, type: "devices"}
export def "devices instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "devices"}
]: any -> record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/devices/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/diagnosticSignatures/{id}/logs
#
# operationId: diagnosticSignatures-logs-get_to_many_related
export def "diagnostic-signatures-logs related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/diagnosticSignatures/{id}/logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/endUserLicenseAgreements
#
# operationId: endUserLicenseAgreements-create_instance
# --data shape: {attributes: record, relationships: record, type: "endUserLicenseAgreements"}
export def "end-user-license-agreements instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "endUserLicenseAgreements"}
]: any -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/endUserLicenseAgreements")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/endUserLicenseAgreements/{id}
#
# operationId: endUserLicenseAgreements-delete_instance
export def "end-user-license-agreements instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/endUserLicenseAgreements/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/endUserLicenseAgreements/{id}
#
# operationId: endUserLicenseAgreements-get_instance
export def "end-user-license-agreements instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-end-user-license-agreements: list # the fields to include for returned resources of type endUserLicenseAgreements
  --include: list # comma-separated list of relationships to include
  --fields-territories: list # the fields to include for returned resources of type territories
  --limit-territories: int # maximum number of related territories returned (when they are included)
]: nothing -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[endUserLicenseAgreements]" $fields_end_user_license_agreements "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[territories]" $fields_territories "csv") (serialize-qp "limit[territories]" $limit_territories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/endUserLicenseAgreements/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/endUserLicenseAgreements/{id}
#
# operationId: endUserLicenseAgreements-update_instance
# --data shape: {attributes?: record, id: string, relationships?: record, type: "endUserLicenseAgreements"}
export def "end-user-license-agreements instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "endUserLicenseAgreements"}
]: any -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/endUserLicenseAgreements/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/endUserLicenseAgreements/{id}/territories
#
# operationId: endUserLicenseAgreements-territories-get_to_many_related
export def "end-user-license-agreements-territories related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-territories: list # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[territories]" $fields_territories "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/endUserLicenseAgreements/{id}/territories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/financeReports
#
# operationId: financeReports-get_collection
export def "finance-reports collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-region-code: list # filter by attribute 'regionCode'
  --filter-report-date: list # filter by attribute 'reportDate'
  --filter-report-type: list # filter by attribute 'reportType'
  --filter-vendor-number: list # filter by attribute 'vendorNumber'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[regionCode]" $filter_region_code "csv") (serialize-qp "filter[reportDate]" $filter_report_date "csv") (serialize-qp "filter[reportType]" $filter_report_type "csv") (serialize-qp "filter[vendorNumber]" $filter_vendor_number "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/financeReports" $qp)
  let accept_val = "gzip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/gameCenterEnabledVersions/{id}/compatibleVersions
#
# operationId: gameCenterEnabledVersions-compatibleVersions-get_to_many_related
export def "game-center-enabled-versions-compatible-versions related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-platform: list # filter by attribute 'platform'
  --filter-version-string: list # filter by attribute 'versionString'
  --filter-app: list # filter by id(s) of related 'app'
  --filter-id: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-game-center-enabled-versions: list # the fields to include for returned resources of type gameCenterEnabledVersions
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[platform]" $filter_platform "csv") (serialize-qp "filter[versionString]" $filter_version_string "csv") (serialize-qp "filter[app]" $filter_app "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[gameCenterEnabledVersions]" $fields_game_center_enabled_versions "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/gameCenterEnabledVersions/{id}/compatibleVersions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions
#
# operationId: gameCenterEnabledVersions-compatibleVersions-delete_to_many_relationship
# --data item shape: {id: string, type: "gameCenterEnabledVersions"}
export def "game-center-enabled-versions-relationships-compatible-versions relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "gameCenterEnabledVersions"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions
#
# operationId: gameCenterEnabledVersions-compatibleVersions-get_to_many_relationship
export def "game-center-enabled-versions-relationships-compatible-versions relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions
#
# operationId: gameCenterEnabledVersions-compatibleVersions-replace_to_many_relationship
# --data item shape: {id: string, type: "gameCenterEnabledVersions"}
export def "game-center-enabled-versions-relationships-compatible-versions relationship-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "gameCenterEnabledVersions"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions
#
# operationId: gameCenterEnabledVersions-compatibleVersions-create_to_many_relationship
# --data item shape: {id: string, type: "gameCenterEnabledVersions"}
export def "game-center-enabled-versions-relationships-compatible-versions relationship-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "gameCenterEnabledVersions"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/gameCenterEnabledVersions/{id}/relationships/compatibleVersions"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/idfaDeclarations
#
# operationId: idfaDeclarations-create_instance
# --data shape: {attributes: record, relationships: record, type: "idfaDeclarations"}
export def "idfa-declarations instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "idfaDeclarations"}
]: any -> record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/idfaDeclarations")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/idfaDeclarations/{id}
#
# operationId: idfaDeclarations-delete_instance
export def "idfa-declarations instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/idfaDeclarations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/idfaDeclarations/{id}
#
# operationId: idfaDeclarations-update_instance
# --data shape: {attributes?: record, id: string, type: "idfaDeclarations"}
export def "idfa-declarations instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "idfaDeclarations"}
]: any -> record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/idfaDeclarations/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/inAppPurchases/{id}
#
# operationId: inAppPurchases-get_instance
export def "in-app-purchases instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-in-app-purchases: list # the fields to include for returned resources of type inAppPurchases
  --include: list # comma-separated list of relationships to include
  --limit-apps: int # maximum number of related apps returned (when they are included)
]: nothing -> record<data: record<attributes: record<inAppPurchaseType: string, productId: string, referenceName: string, state: string>, id: string, links: record<self: string>, relationships: record<apps: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[inAppPurchases]" $fields_in_app_purchases "csv") (serialize-qp "include" $include "csv") (serialize-qp "limit[apps]" $limit_apps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/inAppPurchases/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/preReleaseVersions
#
# operationId: preReleaseVersions-get_collection
export def "pre-release-versions collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-builds-expired: list # filter by attribute 'builds.expired'
  --filter-builds-processing-state: list # filter by attribute 'builds.processingState'
  --filter-platform: list # filter by attribute 'platform'
  --filter-version: list # filter by attribute 'version'
  --filter-app: list # filter by id(s) of related 'app'
  --filter-builds: list # filter by id(s) of related 'builds'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-pre-release-versions: list # the fields to include for returned resources of type preReleaseVersions
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[builds.expired]" $filter_builds_expired "csv") (serialize-qp "filter[builds.processingState]" $filter_builds_processing_state "csv") (serialize-qp "filter[platform]" $filter_platform "csv") (serialize-qp "filter[version]" $filter_version "csv") (serialize-qp "filter[app]" $filter_app "csv") (serialize-qp "filter[builds]" $filter_builds "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[preReleaseVersions]" $fields_pre_release_versions "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[builds]" $limit_builds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/preReleaseVersions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/preReleaseVersions/{id}
#
# operationId: preReleaseVersions-get_instance
export def "pre-release-versions instance" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-pre-release-versions: list # the fields to include for returned resources of type preReleaseVersions
  --include: list # comma-separated list of relationships to include
  --fields-builds: list # the fields to include for returned resources of type builds
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-builds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: record<attributes: record<platform: string, version: string>, id: string, links: record<self: string>, relationships: record<app: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[preReleaseVersions]" $fields_pre_release_versions "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[builds]" $limit_builds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/preReleaseVersions/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/preReleaseVersions/{id}/app
#
# operationId: preReleaseVersions-app-get_to_one_related
export def "pre-release-versions-app related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/preReleaseVersions/{id}/app") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/preReleaseVersions/{id}/builds
#
# operationId: preReleaseVersions-builds-get_to_many_related
export def "pre-release-versions-builds related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-builds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fields_builds "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/preReleaseVersions/{id}/builds") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/profiles
#
# operationId: profiles-get_collection
export def "profiles collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: list # filter by attribute 'name'
  --filter-profile-state: list # filter by attribute 'profileState'
  --filter-profile-type: list # filter by attribute 'profileType'
  --filter-id: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-profiles: list # the fields to include for returned resources of type profiles
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-certificates: list # the fields to include for returned resources of type certificates
  --fields-devices: list # the fields to include for returned resources of type devices
  --fields-bundle-ids: list # the fields to include for returned resources of type bundleIds
  --limit-certificates: int # maximum number of related certificates returned (when they are included)
  --limit-devices: int # maximum number of related devices returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filter_name "csv") (serialize-qp "filter[profileState]" $filter_profile_state "csv") (serialize-qp "filter[profileType]" $filter_profile_type "csv") (serialize-qp "filter[id]" $filter_id "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[profiles]" $fields_profiles "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[certificates]" $fields_certificates "csv") (serialize-qp "fields[devices]" $fields_devices "csv") (serialize-qp "fields[bundleIds]" $fields_bundle_ids "csv") (serialize-qp "limit[certificates]" $limit_certificates "scalar") (serialize-qp "limit[devices]" $limit_devices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/profiles
#
# operationId: profiles-create_instance
# --data shape: {attributes: record, relationships: record, type: "profiles"}
export def "profiles instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "profiles"}
]: any -> record<data: record<attributes: record<createdDate: string, expirationDate: string, name: string, platform: string, profileContent: string, profileState: string, profileType: string, uuid: string>, id: string, links: record<self: string>, relationships: record<bundleId: record, certificates: record, devices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/profiles")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/profiles/{id}
#
# operationId: profiles-delete_instance
export def "profiles instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/profiles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/profiles/{id}
#
# operationId: profiles-get_instance
export def "profiles instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-profiles: list # the fields to include for returned resources of type profiles
  --include: list # comma-separated list of relationships to include
  --fields-certificates: list # the fields to include for returned resources of type certificates
  --fields-devices: list # the fields to include for returned resources of type devices
  --fields-bundle-ids: list # the fields to include for returned resources of type bundleIds
  --limit-certificates: int # maximum number of related certificates returned (when they are included)
  --limit-devices: int # maximum number of related devices returned (when they are included)
]: nothing -> record<data: record<attributes: record<createdDate: string, expirationDate: string, name: string, platform: string, profileContent: string, profileState: string, profileType: string, uuid: string>, id: string, links: record<self: string>, relationships: record<bundleId: record, certificates: record, devices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profiles]" $fields_profiles "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[certificates]" $fields_certificates "csv") (serialize-qp "fields[devices]" $fields_devices "csv") (serialize-qp "fields[bundleIds]" $fields_bundle_ids "csv") (serialize-qp "limit[certificates]" $limit_certificates "scalar") (serialize-qp "limit[devices]" $limit_devices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/profiles/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/profiles/{id}/bundleId
#
# operationId: profiles-bundleId-get_to_one_related
export def "profiles-bundle-id related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-bundle-ids: list # the fields to include for returned resources of type bundleIds
]: nothing -> record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[bundleIds]" $fields_bundle_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/profiles/{id}/bundleId") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/profiles/{id}/certificates
#
# operationId: profiles-certificates-get_to_many_related
export def "profiles-certificates related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-certificates: list # the fields to include for returned resources of type certificates
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[certificates]" $fields_certificates "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/profiles/{id}/certificates") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/profiles/{id}/devices
#
# operationId: profiles-devices-get_to_many_related
export def "profiles-devices related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-devices: list # the fields to include for returned resources of type devices
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[devices]" $fields_devices "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/profiles/{id}/devices") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/routingAppCoverages
#
# operationId: routingAppCoverages-create_instance
# --data shape: {attributes: record, relationships: record, type: "routingAppCoverages"}
export def "routing-app-coverages instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships: record, type: "routingAppCoverages"}
]: any -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/routingAppCoverages")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/routingAppCoverages/{id}
#
# operationId: routingAppCoverages-delete_instance
export def "routing-app-coverages instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/routingAppCoverages/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/routingAppCoverages/{id}
#
# operationId: routingAppCoverages-get_instance
export def "routing-app-coverages instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-routing-app-coverages: list # the fields to include for returned resources of type routingAppCoverages
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[routingAppCoverages]" $fields_routing_app_coverages "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/routingAppCoverages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/routingAppCoverages/{id}
#
# operationId: routingAppCoverages-update_instance
# --data shape: {attributes?: record, id: string, type: "routingAppCoverages"}
export def "routing-app-coverages instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, type: "routingAppCoverages"}
]: any -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/routingAppCoverages/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/salesReports
#
# operationId: salesReports-get_collection
export def "sales-reports collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-frequency: list # filter by attribute 'frequency'
  --filter-report-date: list # filter by attribute 'reportDate'
  --filter-report-sub-type: list # filter by attribute 'reportSubType'
  --filter-report-type: list # filter by attribute 'reportType'
  --filter-vendor-number: list # filter by attribute 'vendorNumber'
  --filter-version: list # filter by attribute 'version'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[frequency]" $filter_frequency "csv") (serialize-qp "filter[reportDate]" $filter_report_date "csv") (serialize-qp "filter[reportSubType]" $filter_report_sub_type "csv") (serialize-qp "filter[reportType]" $filter_report_type "csv") (serialize-qp "filter[vendorNumber]" $filter_vendor_number "csv") (serialize-qp "filter[version]" $filter_version "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/salesReports" $qp)
  let accept_val = "gzip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/territories
#
# operationId: territories-get_collection
export def "territories collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-territories: list # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[territories]" $fields_territories "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/territories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/userInvitations
#
# operationId: userInvitations-get_collection
export def "user-invitations collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-email: list # filter by attribute 'email'
  --filter-roles: list # filter by attribute 'roles'
  --filter-visible-apps: list # filter by id(s) of related 'visibleApps'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-user-invitations: list # the fields to include for returned resources of type userInvitations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-visible-apps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[email]" $filter_email "csv") (serialize-qp "filter[roles]" $filter_roles "csv") (serialize-qp "filter[visibleApps]" $filter_visible_apps "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[userInvitations]" $fields_user_invitations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[visibleApps]" $limit_visible_apps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/userInvitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/userInvitations
#
# operationId: userInvitations-create_instance
# --data shape: {attributes: record, relationships?: record, type: "userInvitations"}
export def "user-invitations instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes: record, relationships?: record, type: "userInvitations"}
]: any -> record<data: record<attributes: record<allAppsVisible: bool, email: string, expirationDate: string, firstName: string, lastName: string, provisioningAllowed: bool, roles: list>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/userInvitations")
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/userInvitations/{id}
#
# operationId: userInvitations-delete_instance
export def "user-invitations instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/userInvitations/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/userInvitations/{id}
#
# operationId: userInvitations-get_instance
export def "user-invitations instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-user-invitations: list # the fields to include for returned resources of type userInvitations
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-visible-apps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> record<data: record<attributes: record<allAppsVisible: bool, email: string, expirationDate: string, firstName: string, lastName: string, provisioningAllowed: bool, roles: list>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[userInvitations]" $fields_user_invitations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[visibleApps]" $limit_visible_apps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/userInvitations/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/userInvitations/{id}/visibleApps
#
# operationId: userInvitations-visibleApps-get_to_many_related
export def "user-invitations-visible-apps related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/userInvitations/{id}/visibleApps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/users
#
# operationId: users-get_collection
export def "users collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-roles: list # filter by attribute 'roles'
  --filter-username: list # filter by attribute 'username'
  --filter-visible-apps: list # filter by id(s) of related 'visibleApps'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fields-users: list # the fields to include for returned resources of type users
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-visible-apps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[roles]" $filter_roles "csv") (serialize-qp "filter[username]" $filter_username "csv") (serialize-qp "filter[visibleApps]" $filter_visible_apps "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[users]" $fields_users "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[visibleApps]" $limit_visible_apps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/users/{id}
#
# operationId: users-delete_instance
export def "users instance-by-id" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/users/{id}
#
# operationId: users-get_instance
export def "users instance-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-users: list # the fields to include for returned resources of type users
  --include: list # comma-separated list of relationships to include
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit-visible-apps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> record<data: record<attributes: record<allAppsVisible: bool, firstName: string, lastName: string, provisioningAllowed: bool, roles: list, username: string>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[users]" $fields_users "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit[visibleApps]" $limit_visible_apps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/users/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/users/{id}
#
# operationId: users-update_instance
# --data shape: {attributes?: record, id: string, relationships?: record, type: "users"}
export def "users instance-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # shape: {attributes?: record, id: string, relationships?: record, type: "users"}
]: any -> record<data: record<attributes: record<allAppsVisible: bool, firstName: string, lastName: string, provisioningAllowed: bool, roles: list, username: string>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/users/{id}"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DELETE /v1/users/{id}/relationships/visibleApps
#
# operationId: users-visibleApps-delete_to_many_relationship
# --data item shape: {id: string, type: "apps"}
export def "users-relationships-visible-apps relationship-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "apps"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/users/{id}/relationships/visibleApps"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/users/{id}/relationships/visibleApps
#
# operationId: users-visibleApps-get_to_many_relationship
export def "users-relationships-visible-apps relationship-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # maximum resources per page
]: nothing -> record<data: table<id: string, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/users/{id}/relationships/visibleApps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PATCH /v1/users/{id}/relationships/visibleApps
#
# operationId: users-visibleApps-replace_to_many_relationship
# --data item shape: {id: string, type: "apps"}
export def "users-relationships-visible-apps relationship-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "apps"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/users/{id}/relationships/visibleApps"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /v1/users/{id}/relationships/visibleApps
#
# operationId: users-visibleApps-create_to_many_relationship
# --data item shape: {id: string, type: "apps"}
export def "users-relationships-visible-apps relationship-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: list # item shape: {id: string, type: "apps"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/users/{id}/relationships/visibleApps"))
  let body = {"data": $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /v1/users/{id}/visibleApps
#
# operationId: users-visibleApps-get_to_many_related
export def "users-visible-apps related" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields-apps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fields_apps "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v1/users/{id}/visibleApps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
