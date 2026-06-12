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
  let full_url = (build-url $base $"/v1/ageRatingDeclarations/($id)")
  let body = {data: $data} | compact
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
  --filterplatforms: list # filter by attribute 'platforms'
  --existsparent: list # filter by existence or non-existence of related 'parent'
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --limitsubcategories: int # maximum number of related subcategories returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[platforms]" $filterplatforms "csv") (serialize-qp "exists[parent]" $existsparent "csv") (serialize-qp "fields[appCategories]" $fieldsappCategories "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "limit[subcategories]" $limitsubcategories "scalar")] | flatten | str join "&"
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
  --include: list # comma-separated list of relationships to include
  --limitsubcategories: int # maximum number of related subcategories returned (when they are included)
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv") (serialize-qp "include" $include "csv") (serialize-qp "limit[subcategories]" $limitsubcategories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appCategories/($id)" $qp)
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appCategories/($id)/parent" $qp)
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appCategories/($id)/subcategories" $qp)
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
  --filterplatform: list # filter by attribute 'platform'
  --filterapp: list # filter by id(s) of related 'app'
  --filterbuilds: list # filter by id(s) of related 'builds'
  --fieldsappEncryptionDeclarations: list # the fields to include for returned resources of type appEncryptionDeclarations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[platform]" $filterplatform "csv") (serialize-qp "filter[app]" $filterapp "csv") (serialize-qp "filter[builds]" $filterbuilds "csv") (serialize-qp "fields[appEncryptionDeclarations]" $fieldsappEncryptionDeclarations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
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
  --fieldsappEncryptionDeclarations: list # the fields to include for returned resources of type appEncryptionDeclarations
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<appEncryptionDeclarationState: string, availableOnFrenchStore: bool, codeValue: string, containsProprietaryCryptography: bool, containsThirdPartyCryptography: bool, documentName: string, documentType: string, documentUrl: string, exempt: bool, platform: string, uploadedDate: string, usesEncryption: bool>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appEncryptionDeclarations]" $fieldsappEncryptionDeclarations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appEncryptionDeclarations/($id)" $qp)
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
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appEncryptionDeclarations/($id)/app" $qp)
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
  let full_url = (build-url $base $"/v1/appEncryptionDeclarations/($id)/relationships/builds")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appInfoLocalizations/($id)")
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
  --fieldsappInfoLocalizations: list # the fields to include for returned resources of type appInfoLocalizations
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<locale: string, name: string, privacyPolicyText: string, privacyPolicyUrl: string, subtitle: string>, id: string, links: record<self: string>, relationships: record<appInfo: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appInfoLocalizations]" $fieldsappInfoLocalizations "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfoLocalizations/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appInfoLocalizations/($id)")
  let body = {data: $data} | compact
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
  --fieldsappInfos: list # the fields to include for returned resources of type appInfos
  --include: list # comma-separated list of relationships to include
  --fieldsageRatingDeclarations: list # the fields to include for returned resources of type ageRatingDeclarations
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
  --fieldsappInfoLocalizations: list # the fields to include for returned resources of type appInfoLocalizations
  --limitappInfoLocalizations: int # maximum number of related appInfoLocalizations returned (when they are included)
]: nothing -> record<data: record<attributes: record<appStoreAgeRating: string, appStoreState: string, brazilAgeRating: string, kidsAgeBand: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appInfoLocalizations: record, primaryCategory: record, primarySubcategoryOne: record, primarySubcategoryTwo: record, secondaryCategory: record, secondarySubcategoryOne: record, secondarySubcategoryTwo: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appInfos]" $fieldsappInfos "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[ageRatingDeclarations]" $fieldsageRatingDeclarations "csv") (serialize-qp "fields[appCategories]" $fieldsappCategories "csv") (serialize-qp "fields[appInfoLocalizations]" $fieldsappInfoLocalizations "csv") (serialize-qp "limit[appInfoLocalizations]" $limitappInfoLocalizations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appInfos/($id)")
  let body = {data: $data} | compact
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
  --fieldsageRatingDeclarations: list # the fields to include for returned resources of type ageRatingDeclarations
]: nothing -> record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[ageRatingDeclarations]" $fieldsageRatingDeclarations "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)/ageRatingDeclaration" $qp)
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
  --filterlocale: list # filter by attribute 'locale'
  --fieldsappInfos: list # the fields to include for returned resources of type appInfos
  --fieldsappInfoLocalizations: list # the fields to include for returned resources of type appInfoLocalizations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[locale]" $filterlocale "csv") (serialize-qp "fields[appInfos]" $fieldsappInfos "csv") (serialize-qp "fields[appInfoLocalizations]" $fieldsappInfoLocalizations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)/appInfoLocalizations" $qp)
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)/primaryCategory" $qp)
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)/primarySubcategoryOne" $qp)
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)/primarySubcategoryTwo" $qp)
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)/secondaryCategory" $qp)
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)/secondarySubcategoryOne" $qp)
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
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
]: nothing -> record<data: record<attributes: record<platforms: list>, id: string, links: record<self: string>, relationships: record<parent: record, subcategories: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appCategories]" $fieldsappCategories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appInfos/($id)/secondarySubcategoryTwo" $qp)
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appPreOrders/($id)")
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
  --fieldsappPreOrders: list # the fields to include for returned resources of type appPreOrders
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreOrders]" $fieldsappPreOrders "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPreOrders/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appPreOrders/($id)")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appPreviewSets/($id)")
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
  --fieldsappPreviewSets: list # the fields to include for returned resources of type appPreviewSets
  --include: list # comma-separated list of relationships to include
  --fieldsappPreviews: list # the fields to include for returned resources of type appPreviews
  --limitappPreviews: int # maximum number of related appPreviews returned (when they are included)
]: nothing -> record<data: record<attributes: record<previewType: string>, id: string, links: record<self: string>, relationships: record<appPreviews: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreviewSets]" $fieldsappPreviewSets "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appPreviews]" $fieldsappPreviews "csv") (serialize-qp "limit[appPreviews]" $limitappPreviews "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPreviewSets/($id)" $qp)
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
  --fieldsappPreviews: list # the fields to include for returned resources of type appPreviews
  --fieldsappPreviewSets: list # the fields to include for returned resources of type appPreviewSets
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreviews]" $fieldsappPreviews "csv") (serialize-qp "fields[appPreviewSets]" $fieldsappPreviewSets "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPreviewSets/($id)/appPreviews" $qp)
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
  let full_url = (build-url $base $"/v1/appPreviewSets/($id)/relationships/appPreviews" $qp)
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
  let full_url = (build-url $base $"/v1/appPreviewSets/($id)/relationships/appPreviews")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appPreviews/($id)")
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
  --fieldsappPreviews: list # the fields to include for returned resources of type appPreviews
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, mimeType: string, previewFrameTimeCode: string, previewImage: record, sourceFileChecksum: string, uploadOperations: list, videoUrl: string>, id: string, links: record<self: string>, relationships: record<appPreviewSet: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreviews]" $fieldsappPreviews "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPreviews/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appPreviews/($id)")
  let body = {data: $data} | compact
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
  --filterpriceTier: list # filter by id(s) of related 'priceTier'
  --filterterritory: list # filter by id(s) of related 'territory'
  --fieldsappPricePoints: list # the fields to include for returned resources of type appPricePoints
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsterritories: list # the fields to include for returned resources of type territories
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[priceTier]" $filterpriceTier "csv") (serialize-qp "filter[territory]" $filterterritory "csv") (serialize-qp "fields[appPricePoints]" $fieldsappPricePoints "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[territories]" $fieldsterritories "csv")] | flatten | str join "&"
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
  --fieldsappPricePoints: list # the fields to include for returned resources of type appPricePoints
  --include: list # comma-separated list of relationships to include
  --fieldsterritories: list # the fields to include for returned resources of type territories
]: nothing -> record<data: record<attributes: record<customerPrice: string, proceeds: string>, id: string, links: record<self: string>, relationships: record<priceTier: record, territory: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPricePoints]" $fieldsappPricePoints "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[territories]" $fieldsterritories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPricePoints/($id)" $qp)
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
  --fieldsterritories: list # the fields to include for returned resources of type territories
]: nothing -> record<data: record<attributes: record<currency: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[territories]" $fieldsterritories "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPricePoints/($id)/territory" $qp)
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
  --filterid: list # filter by id(s)
  --fieldsappPriceTiers: list # the fields to include for returned resources of type appPriceTiers
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsappPricePoints: list # the fields to include for returned resources of type appPricePoints
  --limitpricePoints: int # maximum number of related pricePoints returned (when they are included)
]: nothing -> record<data: table<id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[id]" $filterid "csv") (serialize-qp "fields[appPriceTiers]" $fieldsappPriceTiers "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[appPricePoints]" $fieldsappPricePoints "csv") (serialize-qp "limit[pricePoints]" $limitpricePoints "scalar")] | flatten | str join "&"
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
  --fieldsappPriceTiers: list # the fields to include for returned resources of type appPriceTiers
  --include: list # comma-separated list of relationships to include
  --fieldsappPricePoints: list # the fields to include for returned resources of type appPricePoints
  --limitpricePoints: int # maximum number of related pricePoints returned (when they are included)
]: nothing -> record<data: record<id: string, links: record<self: string>, relationships: record<pricePoints: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPriceTiers]" $fieldsappPriceTiers "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appPricePoints]" $fieldsappPricePoints "csv") (serialize-qp "limit[pricePoints]" $limitpricePoints "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPriceTiers/($id)" $qp)
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
  --fieldsappPricePoints: list # the fields to include for returned resources of type appPricePoints
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPricePoints]" $fieldsappPricePoints "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPriceTiers/($id)/pricePoints" $qp)
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
  --fieldsappPrices: list # the fields to include for returned resources of type appPrices
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<id: string, links: record<self: string>, relationships: record<app: record, priceTier: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPrices]" $fieldsappPrices "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appPrices/($id)" $qp)
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appScreenshotSets/($id)")
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
  --fieldsappScreenshotSets: list # the fields to include for returned resources of type appScreenshotSets
  --include: list # comma-separated list of relationships to include
  --fieldsappScreenshots: list # the fields to include for returned resources of type appScreenshots
  --limitappScreenshots: int # maximum number of related appScreenshots returned (when they are included)
]: nothing -> record<data: record<attributes: record<screenshotDisplayType: string>, id: string, links: record<self: string>, relationships: record<appScreenshots: record, appStoreVersionLocalization: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appScreenshotSets]" $fieldsappScreenshotSets "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appScreenshots]" $fieldsappScreenshots "csv") (serialize-qp "limit[appScreenshots]" $limitappScreenshots "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appScreenshotSets/($id)" $qp)
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
  --fieldsappScreenshotSets: list # the fields to include for returned resources of type appScreenshotSets
  --fieldsappScreenshots: list # the fields to include for returned resources of type appScreenshots
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appScreenshotSets]" $fieldsappScreenshotSets "csv") (serialize-qp "fields[appScreenshots]" $fieldsappScreenshots "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appScreenshotSets/($id)/appScreenshots" $qp)
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
  let full_url = (build-url $base $"/v1/appScreenshotSets/($id)/relationships/appScreenshots" $qp)
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
  let full_url = (build-url $base $"/v1/appScreenshotSets/($id)/relationships/appScreenshots")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appScreenshots/($id)")
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
  --fieldsappScreenshots: list # the fields to include for returned resources of type appScreenshots
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, assetToken: string, assetType: string, fileName: string, fileSize: int, imageAsset: record, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appScreenshotSet: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appScreenshots]" $fieldsappScreenshots "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appScreenshots/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appScreenshots/($id)")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appStoreReviewAttachments/($id)")
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
  --fieldsappStoreReviewAttachments: list # the fields to include for returned resources of type appStoreReviewAttachments
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreReviewDetail: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreReviewAttachments]" $fieldsappStoreReviewAttachments "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreReviewAttachments/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appStoreReviewAttachments/($id)")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  --fieldsappStoreReviewDetails: list # the fields to include for returned resources of type appStoreReviewDetails
  --include: list # comma-separated list of relationships to include
  --fieldsappStoreReviewAttachments: list # the fields to include for returned resources of type appStoreReviewAttachments
  --limitappStoreReviewAttachments: int # maximum number of related appStoreReviewAttachments returned (when they are included)
]: nothing -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreReviewDetails]" $fieldsappStoreReviewDetails "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appStoreReviewAttachments]" $fieldsappStoreReviewAttachments "csv") (serialize-qp "limit[appStoreReviewAttachments]" $limitappStoreReviewAttachments "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreReviewDetails/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appStoreReviewDetails/($id)")
  let body = {data: $data} | compact
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
  --fieldsappStoreReviewDetails: list # the fields to include for returned resources of type appStoreReviewDetails
  --fieldsappStoreReviewAttachments: list # the fields to include for returned resources of type appStoreReviewAttachments
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreReviewDetails]" $fieldsappStoreReviewDetails "csv") (serialize-qp "fields[appStoreReviewAttachments]" $fieldsappStoreReviewAttachments "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreReviewDetails/($id)/appStoreReviewAttachments" $qp)
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appStoreVersionLocalizations/($id)")
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
  --fieldsappStoreVersionLocalizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --include: list # comma-separated list of relationships to include
  --fieldsappScreenshotSets: list # the fields to include for returned resources of type appScreenshotSets
  --fieldsappPreviewSets: list # the fields to include for returned resources of type appPreviewSets
  --limitappPreviewSets: int # maximum number of related appPreviewSets returned (when they are included)
  --limitappScreenshotSets: int # maximum number of related appScreenshotSets returned (when they are included)
]: nothing -> record<data: record<attributes: record<description: string, keywords: string, locale: string, marketingUrl: string, promotionalText: string, supportUrl: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<appPreviewSets: record, appScreenshotSets: record, appStoreVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersionLocalizations]" $fieldsappStoreVersionLocalizations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appScreenshotSets]" $fieldsappScreenshotSets "csv") (serialize-qp "fields[appPreviewSets]" $fieldsappPreviewSets "csv") (serialize-qp "limit[appPreviewSets]" $limitappPreviewSets "scalar") (serialize-qp "limit[appScreenshotSets]" $limitappScreenshotSets "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersionLocalizations/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appStoreVersionLocalizations/($id)")
  let body = {data: $data} | compact
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
  --filterpreviewType: list # filter by attribute 'previewType'
  --fieldsappStoreVersionLocalizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --fieldsappPreviews: list # the fields to include for returned resources of type appPreviews
  --fieldsappPreviewSets: list # the fields to include for returned resources of type appPreviewSets
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[previewType]" $filterpreviewType "csv") (serialize-qp "fields[appStoreVersionLocalizations]" $fieldsappStoreVersionLocalizations "csv") (serialize-qp "fields[appPreviews]" $fieldsappPreviews "csv") (serialize-qp "fields[appPreviewSets]" $fieldsappPreviewSets "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersionLocalizations/($id)/appPreviewSets" $qp)
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
  --filterscreenshotDisplayType: list # filter by attribute 'screenshotDisplayType'
  --fieldsappStoreVersionLocalizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --fieldsappScreenshotSets: list # the fields to include for returned resources of type appScreenshotSets
  --fieldsappScreenshots: list # the fields to include for returned resources of type appScreenshots
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[screenshotDisplayType]" $filterscreenshotDisplayType "csv") (serialize-qp "fields[appStoreVersionLocalizations]" $fieldsappStoreVersionLocalizations "csv") (serialize-qp "fields[appScreenshotSets]" $fieldsappScreenshotSets "csv") (serialize-qp "fields[appScreenshots]" $fieldsappScreenshots "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersionLocalizations/($id)/appScreenshotSets" $qp)
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appStoreVersionPhasedReleases/($id)")
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
  let full_url = (build-url $base $"/v1/appStoreVersionPhasedReleases/($id)")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appStoreVersionSubmissions/($id)")
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/appStoreVersions/{id}
#
# operationId: appStoreVersions-get_instance
@deprecated --flag fieldsageRatingDeclarations
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
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
  --include: list # comma-separated list of relationships to include
  --fieldsappStoreVersionLocalizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --fieldsidfaDeclarations: list # the fields to include for returned resources of type idfaDeclarations
  --fieldsroutingAppCoverages: list # the fields to include for returned resources of type routingAppCoverages
  --fieldsappStoreVersionPhasedReleases: list # the fields to include for returned resources of type appStoreVersionPhasedReleases
  --fieldsageRatingDeclarations: list # the fields to include for returned resources of type ageRatingDeclarations (DEPRECATED)
  --fieldsappStoreReviewDetails: list # the fields to include for returned resources of type appStoreReviewDetails
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsappStoreVersionSubmissions: list # the fields to include for returned resources of type appStoreVersionSubmissions
  --limitappStoreVersionLocalizations: int # maximum number of related appStoreVersionLocalizations returned (when they are included)
]: nothing -> record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appStoreVersionLocalizations]" $fieldsappStoreVersionLocalizations "csv") (serialize-qp "fields[idfaDeclarations]" $fieldsidfaDeclarations "csv") (serialize-qp "fields[routingAppCoverages]" $fieldsroutingAppCoverages "csv") (serialize-qp "fields[appStoreVersionPhasedReleases]" $fieldsappStoreVersionPhasedReleases "csv") (serialize-qp "fields[ageRatingDeclarations]" $fieldsageRatingDeclarations "csv") (serialize-qp "fields[appStoreReviewDetails]" $fieldsappStoreReviewDetails "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[appStoreVersionSubmissions]" $fieldsappStoreVersionSubmissions "csv") (serialize-qp "limit[appStoreVersionLocalizations]" $limitappStoreVersionLocalizations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)")
  let body = {data: $data} | compact
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
@deprecated --flag fieldsageRatingDeclarations
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
  --fieldsageRatingDeclarations: list # the fields to include for returned resources of type ageRatingDeclarations (DEPRECATED)
]: nothing -> record<data: record<attributes: record<alcoholTobaccoOrDrugUseOrReferences: string, contests: string, gambling: bool, gamblingAndContests: bool, gamblingSimulated: string, horrorOrFearThemes: string, kidsAgeBand: string, matureOrSuggestiveThemes: string, medicalOrTreatmentInformation: string, profanityOrCrudeHumor: string, seventeenPlus: bool, sexualContentGraphicAndNudity: string, sexualContentOrNudity: string, unrestrictedWebAccess: bool, violenceCartoonOrFantasy: string, violenceRealistic: string, violenceRealisticProlongedGraphicOrSadistic: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[ageRatingDeclarations]" $fieldsageRatingDeclarations "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/ageRatingDeclaration" $qp)
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
  --fieldsappStoreReviewDetails: list # the fields to include for returned resources of type appStoreReviewDetails
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
  --fieldsappStoreReviewAttachments: list # the fields to include for returned resources of type appStoreReviewAttachments
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<appStoreReviewAttachments: record, appStoreVersion: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreReviewDetails]" $fieldsappStoreReviewDetails "csv") (serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv") (serialize-qp "fields[appStoreReviewAttachments]" $fieldsappStoreReviewAttachments "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/appStoreReviewDetail" $qp)
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
  --fieldsappStoreVersionLocalizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersionLocalizations]" $fieldsappStoreVersionLocalizations "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/appStoreVersionLocalizations" $qp)
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
  --fieldsappStoreVersionPhasedReleases: list # the fields to include for returned resources of type appStoreVersionPhasedReleases
]: nothing -> record<data: record<attributes: record<currentDayNumber: int, phasedReleaseState: string, startDate: string, totalPauseDuration: int>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersionPhasedReleases]" $fieldsappStoreVersionPhasedReleases "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/appStoreVersionPhasedRelease" $qp)
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
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
  --fieldsappStoreVersionSubmissions: list # the fields to include for returned resources of type appStoreVersionSubmissions
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv") (serialize-qp "fields[appStoreVersionSubmissions]" $fieldsappStoreVersionSubmissions "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/appStoreVersionSubmission" $qp)
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/build" $qp)
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
  --fieldsidfaDeclarations: list # the fields to include for returned resources of type idfaDeclarations
]: nothing -> record<data: record<attributes: record<attributesActionWithPreviousAd: bool, attributesAppInstallationToPreviousAd: bool, honorsLimitedAdTracking: bool, servesAds: bool>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[idfaDeclarations]" $fieldsidfaDeclarations "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/idfaDeclaration" $qp)
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
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/relationships/build")
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
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/relationships/build")
  let body = {data: $data} | compact
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
  --fieldsroutingAppCoverages: list # the fields to include for returned resources of type routingAppCoverages
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[routingAppCoverages]" $fieldsroutingAppCoverages "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/appStoreVersions/($id)/routingAppCoverage" $qp)
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
  --filterappStoreVersionsappStoreState: list # filter by attribute 'appStoreVersions.appStoreState'
  --filterappStoreVersionsplatform: list # filter by attribute 'appStoreVersions.platform'
  --filterbundleId: list # filter by attribute 'bundleId'
  --filtername: list # filter by attribute 'name'
  --filtersku: list # filter by attribute 'sku'
  --filterappStoreVersions: list # filter by id(s) of related 'appStoreVersions'
  --filterid: list # filter by id(s)
  --existsgameCenterEnabledVersions: list # filter by existence or non-existence of related 'gameCenterEnabledVersions'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsbetaGroups: list # the fields to include for returned resources of type betaGroups
  --fieldsperfPowerMetrics: list # the fields to include for returned resources of type perfPowerMetrics
  --fieldsappInfos: list # the fields to include for returned resources of type appInfos
  --fieldsappPreOrders: list # the fields to include for returned resources of type appPreOrders
  --fieldspreReleaseVersions: list # the fields to include for returned resources of type preReleaseVersions
  --fieldsappPrices: list # the fields to include for returned resources of type appPrices
  --fieldsinAppPurchases: list # the fields to include for returned resources of type inAppPurchases
  --fieldsbetaAppReviewDetails: list # the fields to include for returned resources of type betaAppReviewDetails
  --fieldsterritories: list # the fields to include for returned resources of type territories
  --fieldsgameCenterEnabledVersions: list # the fields to include for returned resources of type gameCenterEnabledVersions
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsbetaAppLocalizations: list # the fields to include for returned resources of type betaAppLocalizations
  --fieldsbetaLicenseAgreements: list # the fields to include for returned resources of type betaLicenseAgreements
  --fieldsendUserLicenseAgreements: list # the fields to include for returned resources of type endUserLicenseAgreements
  --limitappInfos: int # maximum number of related appInfos returned (when they are included)
  --limitappStoreVersions: int # maximum number of related appStoreVersions returned (when they are included)
  --limitavailableTerritories: int # maximum number of related availableTerritories returned (when they are included)
  --limitbetaAppLocalizations: int # maximum number of related betaAppLocalizations returned (when they are included)
  --limitbetaGroups: int # maximum number of related betaGroups returned (when they are included)
  --limitbuilds: int # maximum number of related builds returned (when they are included)
  --limitgameCenterEnabledVersions: int # maximum number of related gameCenterEnabledVersions returned (when they are included)
  --limitinAppPurchases: int # maximum number of related inAppPurchases returned (when they are included)
  --limitpreReleaseVersions: int # maximum number of related preReleaseVersions returned (when they are included)
  --limitprices: int # maximum number of related prices returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[appStoreVersions.appStoreState]" $filterappStoreVersionsappStoreState "csv") (serialize-qp "filter[appStoreVersions.platform]" $filterappStoreVersionsplatform "csv") (serialize-qp "filter[bundleId]" $filterbundleId "csv") (serialize-qp "filter[name]" $filtername "csv") (serialize-qp "filter[sku]" $filtersku "csv") (serialize-qp "filter[appStoreVersions]" $filterappStoreVersions "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "exists[gameCenterEnabledVersions]" $existsgameCenterEnabledVersions "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[betaGroups]" $fieldsbetaGroups "csv") (serialize-qp "fields[perfPowerMetrics]" $fieldsperfPowerMetrics "csv") (serialize-qp "fields[appInfos]" $fieldsappInfos "csv") (serialize-qp "fields[appPreOrders]" $fieldsappPreOrders "csv") (serialize-qp "fields[preReleaseVersions]" $fieldspreReleaseVersions "csv") (serialize-qp "fields[appPrices]" $fieldsappPrices "csv") (serialize-qp "fields[inAppPurchases]" $fieldsinAppPurchases "csv") (serialize-qp "fields[betaAppReviewDetails]" $fieldsbetaAppReviewDetails "csv") (serialize-qp "fields[territories]" $fieldsterritories "csv") (serialize-qp "fields[gameCenterEnabledVersions]" $fieldsgameCenterEnabledVersions "csv") (serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[betaAppLocalizations]" $fieldsbetaAppLocalizations "csv") (serialize-qp "fields[betaLicenseAgreements]" $fieldsbetaLicenseAgreements "csv") (serialize-qp "fields[endUserLicenseAgreements]" $fieldsendUserLicenseAgreements "csv") (serialize-qp "limit[appInfos]" $limitappInfos "scalar") (serialize-qp "limit[appStoreVersions]" $limitappStoreVersions "scalar") (serialize-qp "limit[availableTerritories]" $limitavailableTerritories "scalar") (serialize-qp "limit[betaAppLocalizations]" $limitbetaAppLocalizations "scalar") (serialize-qp "limit[betaGroups]" $limitbetaGroups "scalar") (serialize-qp "limit[builds]" $limitbuilds "scalar") (serialize-qp "limit[gameCenterEnabledVersions]" $limitgameCenterEnabledVersions "scalar") (serialize-qp "limit[inAppPurchases]" $limitinAppPurchases "scalar") (serialize-qp "limit[preReleaseVersions]" $limitpreReleaseVersions "scalar") (serialize-qp "limit[prices]" $limitprices "scalar")] | flatten | str join "&"
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
  --fieldsapps: list # the fields to include for returned resources of type apps
  --include: list # comma-separated list of relationships to include
  --fieldsbetaGroups: list # the fields to include for returned resources of type betaGroups
  --fieldsperfPowerMetrics: list # the fields to include for returned resources of type perfPowerMetrics
  --fieldsappInfos: list # the fields to include for returned resources of type appInfos
  --fieldsappPreOrders: list # the fields to include for returned resources of type appPreOrders
  --fieldspreReleaseVersions: list # the fields to include for returned resources of type preReleaseVersions
  --fieldsappPrices: list # the fields to include for returned resources of type appPrices
  --fieldsinAppPurchases: list # the fields to include for returned resources of type inAppPurchases
  --fieldsbetaAppReviewDetails: list # the fields to include for returned resources of type betaAppReviewDetails
  --fieldsterritories: list # the fields to include for returned resources of type territories
  --fieldsgameCenterEnabledVersions: list # the fields to include for returned resources of type gameCenterEnabledVersions
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsbetaAppLocalizations: list # the fields to include for returned resources of type betaAppLocalizations
  --fieldsbetaLicenseAgreements: list # the fields to include for returned resources of type betaLicenseAgreements
  --fieldsendUserLicenseAgreements: list # the fields to include for returned resources of type endUserLicenseAgreements
  --limitappInfos: int # maximum number of related appInfos returned (when they are included)
  --limitappStoreVersions: int # maximum number of related appStoreVersions returned (when they are included)
  --limitavailableTerritories: int # maximum number of related availableTerritories returned (when they are included)
  --limitbetaAppLocalizations: int # maximum number of related betaAppLocalizations returned (when they are included)
  --limitbetaGroups: int # maximum number of related betaGroups returned (when they are included)
  --limitbuilds: int # maximum number of related builds returned (when they are included)
  --limitgameCenterEnabledVersions: int # maximum number of related gameCenterEnabledVersions returned (when they are included)
  --limitinAppPurchases: int # maximum number of related inAppPurchases returned (when they are included)
  --limitpreReleaseVersions: int # maximum number of related preReleaseVersions returned (when they are included)
  --limitprices: int # maximum number of related prices returned (when they are included)
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[betaGroups]" $fieldsbetaGroups "csv") (serialize-qp "fields[perfPowerMetrics]" $fieldsperfPowerMetrics "csv") (serialize-qp "fields[appInfos]" $fieldsappInfos "csv") (serialize-qp "fields[appPreOrders]" $fieldsappPreOrders "csv") (serialize-qp "fields[preReleaseVersions]" $fieldspreReleaseVersions "csv") (serialize-qp "fields[appPrices]" $fieldsappPrices "csv") (serialize-qp "fields[inAppPurchases]" $fieldsinAppPurchases "csv") (serialize-qp "fields[betaAppReviewDetails]" $fieldsbetaAppReviewDetails "csv") (serialize-qp "fields[territories]" $fieldsterritories "csv") (serialize-qp "fields[gameCenterEnabledVersions]" $fieldsgameCenterEnabledVersions "csv") (serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[betaAppLocalizations]" $fieldsbetaAppLocalizations "csv") (serialize-qp "fields[betaLicenseAgreements]" $fieldsbetaLicenseAgreements "csv") (serialize-qp "fields[endUserLicenseAgreements]" $fieldsendUserLicenseAgreements "csv") (serialize-qp "limit[appInfos]" $limitappInfos "scalar") (serialize-qp "limit[appStoreVersions]" $limitappStoreVersions "scalar") (serialize-qp "limit[availableTerritories]" $limitavailableTerritories "scalar") (serialize-qp "limit[betaAppLocalizations]" $limitbetaAppLocalizations "scalar") (serialize-qp "limit[betaGroups]" $limitbetaGroups "scalar") (serialize-qp "limit[builds]" $limitbuilds "scalar") (serialize-qp "limit[gameCenterEnabledVersions]" $limitgameCenterEnabledVersions "scalar") (serialize-qp "limit[inAppPurchases]" $limitinAppPurchases "scalar") (serialize-qp "limit[preReleaseVersions]" $limitpreReleaseVersions "scalar") (serialize-qp "limit[prices]" $limitprices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/apps/($id)")
  let body = {data: $data} | compact
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
  --fieldsageRatingDeclarations: list # the fields to include for returned resources of type ageRatingDeclarations
  --fieldsappInfos: list # the fields to include for returned resources of type appInfos
  --fieldsappCategories: list # the fields to include for returned resources of type appCategories
  --fieldsappInfoLocalizations: list # the fields to include for returned resources of type appInfoLocalizations
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[ageRatingDeclarations]" $fieldsageRatingDeclarations "csv") (serialize-qp "fields[appInfos]" $fieldsappInfos "csv") (serialize-qp "fields[appCategories]" $fieldsappCategories "csv") (serialize-qp "fields[appInfoLocalizations]" $fieldsappInfoLocalizations "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/appInfos" $qp)
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
  --filterappStoreState: list # filter by attribute 'appStoreState'
  --filterplatform: list # filter by attribute 'platform'
  --filterversionString: list # filter by attribute 'versionString'
  --filterid: list # filter by id(s)
  --fieldsidfaDeclarations: list # the fields to include for returned resources of type idfaDeclarations
  --fieldsappStoreVersionLocalizations: list # the fields to include for returned resources of type appStoreVersionLocalizations
  --fieldsroutingAppCoverages: list # the fields to include for returned resources of type routingAppCoverages
  --fieldsappStoreVersionPhasedReleases: list # the fields to include for returned resources of type appStoreVersionPhasedReleases
  --fieldsageRatingDeclarations: list # the fields to include for returned resources of type ageRatingDeclarations
  --fieldsappStoreReviewDetails: list # the fields to include for returned resources of type appStoreReviewDetails
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsappStoreVersionSubmissions: list # the fields to include for returned resources of type appStoreVersionSubmissions
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[appStoreState]" $filterappStoreState "csv") (serialize-qp "filter[platform]" $filterplatform "csv") (serialize-qp "filter[versionString]" $filterversionString "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "fields[idfaDeclarations]" $fieldsidfaDeclarations "csv") (serialize-qp "fields[appStoreVersionLocalizations]" $fieldsappStoreVersionLocalizations "csv") (serialize-qp "fields[routingAppCoverages]" $fieldsroutingAppCoverages "csv") (serialize-qp "fields[appStoreVersionPhasedReleases]" $fieldsappStoreVersionPhasedReleases "csv") (serialize-qp "fields[ageRatingDeclarations]" $fieldsageRatingDeclarations "csv") (serialize-qp "fields[appStoreReviewDetails]" $fieldsappStoreReviewDetails "csv") (serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[appStoreVersionSubmissions]" $fieldsappStoreVersionSubmissions "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/appStoreVersions" $qp)
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
  --fieldsterritories: list # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[territories]" $fieldsterritories "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/availableTerritories" $qp)
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
  --fieldsbetaAppLocalizations: list # the fields to include for returned resources of type betaAppLocalizations
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppLocalizations]" $fieldsbetaAppLocalizations "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/betaAppLocalizations" $qp)
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
  --fieldsbetaAppReviewDetails: list # the fields to include for returned resources of type betaAppReviewDetails
]: nothing -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppReviewDetails]" $fieldsbetaAppReviewDetails "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/betaAppReviewDetail" $qp)
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
  --fieldsbetaGroups: list # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaGroups]" $fieldsbetaGroups "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/betaGroups" $qp)
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
  --fieldsbetaLicenseAgreements: list # the fields to include for returned resources of type betaLicenseAgreements
]: nothing -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaLicenseAgreements]" $fieldsbetaLicenseAgreements "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/betaLicenseAgreement" $qp)
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/builds" $qp)
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
  --fieldsendUserLicenseAgreements: list # the fields to include for returned resources of type endUserLicenseAgreements
]: nothing -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[endUserLicenseAgreements]" $fieldsendUserLicenseAgreements "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/endUserLicenseAgreement" $qp)
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
  --filterplatform: list # filter by attribute 'platform'
  --filterversionString: list # filter by attribute 'versionString'
  --filterid: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsgameCenterEnabledVersions: list # the fields to include for returned resources of type gameCenterEnabledVersions
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[platform]" $filterplatform "csv") (serialize-qp "filter[versionString]" $filterversionString "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[gameCenterEnabledVersions]" $fieldsgameCenterEnabledVersions "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/gameCenterEnabledVersions" $qp)
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
  --filterinAppPurchaseType: list # filter by attribute 'inAppPurchaseType'
  --filtercanBeSubmitted: list # filter by canBeSubmitted
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsinAppPurchases: list # the fields to include for returned resources of type inAppPurchases
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[inAppPurchaseType]" $filterinAppPurchaseType "csv") (serialize-qp "filter[canBeSubmitted]" $filtercanBeSubmitted "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[inAppPurchases]" $fieldsinAppPurchases "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/inAppPurchases" $qp)
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
  --filterdeviceType: list # filter by attribute 'deviceType'
  --filtermetricType: list # filter by attribute 'metricType'
  --filterplatform: list # filter by attribute 'platform'
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[deviceType]" $filterdeviceType "csv") (serialize-qp "filter[metricType]" $filtermetricType "csv") (serialize-qp "filter[platform]" $filterplatform "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/perfPowerMetrics" $qp)
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
  --fieldsappPreOrders: list # the fields to include for returned resources of type appPreOrders
]: nothing -> record<data: record<attributes: record<appReleaseDate: string, preOrderAvailableDate: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPreOrders]" $fieldsappPreOrders "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/preOrder" $qp)
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
  --fieldspreReleaseVersions: list # the fields to include for returned resources of type preReleaseVersions
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[preReleaseVersions]" $fieldspreReleaseVersions "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/preReleaseVersions" $qp)
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
  --fieldsappPrices: list # the fields to include for returned resources of type appPrices
  --fieldsappPriceTiers: list # the fields to include for returned resources of type appPriceTiers
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appPrices]" $fieldsappPrices "csv") (serialize-qp "fields[appPriceTiers]" $fieldsappPriceTiers "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/apps/($id)/prices" $qp)
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
  let full_url = (build-url $base $"/v1/apps/($id)/relationships/betaTesters")
  let body = {data: $data} | compact
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
  --filterlocale: list # filter by attribute 'locale'
  --filterapp: list # filter by id(s) of related 'app'
  --fieldsbetaAppLocalizations: list # the fields to include for returned resources of type betaAppLocalizations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[locale]" $filterlocale "csv") (serialize-qp "filter[app]" $filterapp "csv") (serialize-qp "fields[betaAppLocalizations]" $fieldsbetaAppLocalizations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaAppLocalizations/($id)")
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
  --fieldsbetaAppLocalizations: list # the fields to include for returned resources of type betaAppLocalizations
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<description: string, feedbackEmail: string, locale: string, marketingUrl: string, privacyPolicyUrl: string, tvOsPrivacyPolicy: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppLocalizations]" $fieldsbetaAppLocalizations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaAppLocalizations/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/betaAppLocalizations/($id)")
  let body = {data: $data} | compact
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
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaAppLocalizations/($id)/app" $qp)
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
  --filterapp: list # filter by id(s) of related 'app'
  --fieldsbetaAppReviewDetails: list # the fields to include for returned resources of type betaAppReviewDetails
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[app]" $filterapp "csv") (serialize-qp "fields[betaAppReviewDetails]" $fieldsbetaAppReviewDetails "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
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
  --fieldsbetaAppReviewDetails: list # the fields to include for returned resources of type betaAppReviewDetails
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<contactEmail: string, contactFirstName: string, contactLastName: string, contactPhone: string, demoAccountName: string, demoAccountPassword: string, demoAccountRequired: bool, notes: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppReviewDetails]" $fieldsbetaAppReviewDetails "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaAppReviewDetails/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/betaAppReviewDetails/($id)")
  let body = {data: $data} | compact
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
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaAppReviewDetails/($id)/app" $qp)
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
  --filterbetaReviewState: list # filter by attribute 'betaReviewState'
  --filterbuild: list # filter by id(s) of related 'build'
  --fieldsbetaAppReviewSubmissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[betaReviewState]" $filterbetaReviewState "csv") (serialize-qp "filter[build]" $filterbuild "csv") (serialize-qp "fields[betaAppReviewSubmissions]" $fieldsbetaAppReviewSubmissions "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  --fieldsbetaAppReviewSubmissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppReviewSubmissions]" $fieldsbetaAppReviewSubmissions "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaAppReviewSubmissions/($id)" $qp)
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaAppReviewSubmissions/($id)/build" $qp)
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
  --filterlocale: list # filter by attribute 'locale'
  --filterbuild: list # filter by id(s) of related 'build'
  --fieldsbetaBuildLocalizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[locale]" $filterlocale "csv") (serialize-qp "filter[build]" $filterbuild "csv") (serialize-qp "fields[betaBuildLocalizations]" $fieldsbetaBuildLocalizations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaBuildLocalizations/($id)")
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
  --fieldsbetaBuildLocalizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<locale: string, whatsNew: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaBuildLocalizations]" $fieldsbetaBuildLocalizations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaBuildLocalizations/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/betaBuildLocalizations/($id)")
  let body = {data: $data} | compact
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaBuildLocalizations/($id)/build" $qp)
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
  --filterisInternalGroup: list # filter by attribute 'isInternalGroup'
  --filtername: list # filter by attribute 'name'
  --filterpublicLink: list # filter by attribute 'publicLink'
  --filterpublicLinkEnabled: list # filter by attribute 'publicLinkEnabled'
  --filterpublicLinkLimitEnabled: list # filter by attribute 'publicLinkLimitEnabled'
  --filterapp: list # filter by id(s) of related 'app'
  --filterbuilds: list # filter by id(s) of related 'builds'
  --filterid: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsbetaGroups: list # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsbetaTesters: list # the fields to include for returned resources of type betaTesters
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitbetaTesters: int # maximum number of related betaTesters returned (when they are included)
  --limitbuilds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[isInternalGroup]" $filterisInternalGroup "csv") (serialize-qp "filter[name]" $filtername "csv") (serialize-qp "filter[publicLink]" $filterpublicLink "csv") (serialize-qp "filter[publicLinkEnabled]" $filterpublicLinkEnabled "csv") (serialize-qp "filter[publicLinkLimitEnabled]" $filterpublicLinkLimitEnabled "csv") (serialize-qp "filter[app]" $filterapp "csv") (serialize-qp "filter[builds]" $filterbuilds "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[betaGroups]" $fieldsbetaGroups "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[betaTesters]" $fieldsbetaTesters "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[betaTesters]" $limitbetaTesters "scalar") (serialize-qp "limit[builds]" $limitbuilds "scalar")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaGroups/($id)")
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
  --fieldsbetaGroups: list # the fields to include for returned resources of type betaGroups
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsbetaTesters: list # the fields to include for returned resources of type betaTesters
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitbetaTesters: int # maximum number of related betaTesters returned (when they are included)
  --limitbuilds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: record<attributes: record<createdDate: string, feedbackEnabled: bool, isInternalGroup: bool, name: string, publicLink: string, publicLinkEnabled: bool, publicLinkId: string, publicLinkLimit: int, publicLinkLimitEnabled: bool>, id: string, links: record<self: string>, relationships: record<app: record, betaTesters: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaGroups]" $fieldsbetaGroups "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[betaTesters]" $fieldsbetaTesters "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[betaTesters]" $limitbetaTesters "scalar") (serialize-qp "limit[builds]" $limitbuilds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaGroups/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/betaGroups/($id)")
  let body = {data: $data} | compact
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
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaGroups/($id)/app" $qp)
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
  --fieldsbetaTesters: list # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaTesters]" $fieldsbetaTesters "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaGroups/($id)/betaTesters" $qp)
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaGroups/($id)/builds" $qp)
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
  let full_url = (build-url $base $"/v1/betaGroups/($id)/relationships/betaTesters")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaGroups/($id)/relationships/betaTesters" $qp)
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
  let full_url = (build-url $base $"/v1/betaGroups/($id)/relationships/betaTesters")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaGroups/($id)/relationships/builds")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaGroups/($id)/relationships/builds" $qp)
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
  let full_url = (build-url $base $"/v1/betaGroups/($id)/relationships/builds")
  let body = {data: $data} | compact
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
  --filterapp: list # filter by id(s) of related 'app'
  --fieldsbetaLicenseAgreements: list # the fields to include for returned resources of type betaLicenseAgreements
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[app]" $filterapp "csv") (serialize-qp "fields[betaLicenseAgreements]" $fieldsbetaLicenseAgreements "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
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
  --fieldsbetaLicenseAgreements: list # the fields to include for returned resources of type betaLicenseAgreements
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaLicenseAgreements]" $fieldsbetaLicenseAgreements "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaLicenseAgreements/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/betaLicenseAgreements/($id)")
  let body = {data: $data} | compact
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
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaLicenseAgreements/($id)/app" $qp)
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
  let body = {data: $data} | compact
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
  --filteremail: list # filter by attribute 'email'
  --filterfirstName: list # filter by attribute 'firstName'
  --filterinviteType: list # filter by attribute 'inviteType'
  --filterlastName: list # filter by attribute 'lastName'
  --filterapps: list # filter by id(s) of related 'apps'
  --filterbetaGroups: list # filter by id(s) of related 'betaGroups'
  --filterbuilds: list # filter by id(s) of related 'builds'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsbetaTesters: list # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsbetaGroups: list # the fields to include for returned resources of type betaGroups
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitapps: int # maximum number of related apps returned (when they are included)
  --limitbetaGroups: int # maximum number of related betaGroups returned (when they are included)
  --limitbuilds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[email]" $filteremail "csv") (serialize-qp "filter[firstName]" $filterfirstName "csv") (serialize-qp "filter[inviteType]" $filterinviteType "csv") (serialize-qp "filter[lastName]" $filterlastName "csv") (serialize-qp "filter[apps]" $filterapps "csv") (serialize-qp "filter[betaGroups]" $filterbetaGroups "csv") (serialize-qp "filter[builds]" $filterbuilds "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[betaTesters]" $fieldsbetaTesters "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[betaGroups]" $fieldsbetaGroups "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[apps]" $limitapps "scalar") (serialize-qp "limit[betaGroups]" $limitbetaGroups "scalar") (serialize-qp "limit[builds]" $limitbuilds "scalar")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)")
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
  --fieldsbetaTesters: list # the fields to include for returned resources of type betaTesters
  --include: list # comma-separated list of relationships to include
  --fieldsbetaGroups: list # the fields to include for returned resources of type betaGroups
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitapps: int # maximum number of related apps returned (when they are included)
  --limitbetaGroups: int # maximum number of related betaGroups returned (when they are included)
  --limitbuilds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: record<attributes: record<email: string, firstName: string, inviteType: string, lastName: string>, id: string, links: record<self: string>, relationships: record<apps: record, betaGroups: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaTesters]" $fieldsbetaTesters "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[betaGroups]" $fieldsbetaGroups "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[apps]" $limitapps "scalar") (serialize-qp "limit[betaGroups]" $limitbetaGroups "scalar") (serialize-qp "limit[builds]" $limitbuilds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaTesters/($id)" $qp)
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
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaTesters/($id)/apps" $qp)
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
  --fieldsbetaGroups: list # the fields to include for returned resources of type betaGroups
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaGroups]" $fieldsbetaGroups "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaTesters/($id)/betaGroups" $qp)
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/betaTesters/($id)/builds" $qp)
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)/relationships/apps")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)/relationships/apps" $qp)
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)/relationships/betaGroups")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)/relationships/betaGroups" $qp)
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)/relationships/betaGroups")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)/relationships/builds")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)/relationships/builds" $qp)
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
  let full_url = (build-url $base $"/v1/betaTesters/($id)/relationships/builds")
  let body = {data: $data} | compact
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
  --filterbuild: list # filter by id(s) of related 'build'
  --filterid: list # filter by id(s)
  --fieldsbuildBetaDetails: list # the fields to include for returned resources of type buildBetaDetails
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[build]" $filterbuild "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "fields[buildBetaDetails]" $fieldsbuildBetaDetails "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
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
  --fieldsbuildBetaDetails: list # the fields to include for returned resources of type buildBetaDetails
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[buildBetaDetails]" $fieldsbuildBetaDetails "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/buildBetaDetails/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/buildBetaDetails/($id)")
  let body = {data: $data} | compact
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/buildBetaDetails/($id)/build" $qp)
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
  let body = {data: $data} | compact
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
  --filterbetaAppReviewSubmissionbetaReviewState: list # filter by attribute 'betaAppReviewSubmission.betaReviewState'
  --filterexpired: list # filter by attribute 'expired'
  --filterpreReleaseVersionplatform: list # filter by attribute 'preReleaseVersion.platform'
  --filterpreReleaseVersionversion: list # filter by attribute 'preReleaseVersion.version'
  --filterprocessingState: list # filter by attribute 'processingState'
  --filterusesNonExemptEncryption: list # filter by attribute 'usesNonExemptEncryption'
  --filterversion: list # filter by attribute 'version'
  --filterapp: list # filter by id(s) of related 'app'
  --filterappStoreVersion: list # filter by id(s) of related 'appStoreVersion'
  --filterbetaGroups: list # filter by id(s) of related 'betaGroups'
  --filterpreReleaseVersion: list # filter by id(s) of related 'preReleaseVersion'
  --filterid: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsappEncryptionDeclarations: list # the fields to include for returned resources of type appEncryptionDeclarations
  --fieldsbetaAppReviewSubmissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
  --fieldsbuildBetaDetails: list # the fields to include for returned resources of type buildBetaDetails
  --fieldsbuildIcons: list # the fields to include for returned resources of type buildIcons
  --fieldsperfPowerMetrics: list # the fields to include for returned resources of type perfPowerMetrics
  --fieldspreReleaseVersions: list # the fields to include for returned resources of type preReleaseVersions
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
  --fieldsdiagnosticSignatures: list # the fields to include for returned resources of type diagnosticSignatures
  --fieldsbetaTesters: list # the fields to include for returned resources of type betaTesters
  --fieldsbetaBuildLocalizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitbetaBuildLocalizations: int # maximum number of related betaBuildLocalizations returned (when they are included)
  --limiticons: int # maximum number of related icons returned (when they are included)
  --limitindividualTesters: int # maximum number of related individualTesters returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[betaAppReviewSubmission.betaReviewState]" $filterbetaAppReviewSubmissionbetaReviewState "csv") (serialize-qp "filter[expired]" $filterexpired "csv") (serialize-qp "filter[preReleaseVersion.platform]" $filterpreReleaseVersionplatform "csv") (serialize-qp "filter[preReleaseVersion.version]" $filterpreReleaseVersionversion "csv") (serialize-qp "filter[processingState]" $filterprocessingState "csv") (serialize-qp "filter[usesNonExemptEncryption]" $filterusesNonExemptEncryption "csv") (serialize-qp "filter[version]" $filterversion "csv") (serialize-qp "filter[app]" $filterapp "csv") (serialize-qp "filter[appStoreVersion]" $filterappStoreVersion "csv") (serialize-qp "filter[betaGroups]" $filterbetaGroups "csv") (serialize-qp "filter[preReleaseVersion]" $filterpreReleaseVersion "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[appEncryptionDeclarations]" $fieldsappEncryptionDeclarations "csv") (serialize-qp "fields[betaAppReviewSubmissions]" $fieldsbetaAppReviewSubmissions "csv") (serialize-qp "fields[buildBetaDetails]" $fieldsbuildBetaDetails "csv") (serialize-qp "fields[buildIcons]" $fieldsbuildIcons "csv") (serialize-qp "fields[perfPowerMetrics]" $fieldsperfPowerMetrics "csv") (serialize-qp "fields[preReleaseVersions]" $fieldspreReleaseVersions "csv") (serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv") (serialize-qp "fields[diagnosticSignatures]" $fieldsdiagnosticSignatures "csv") (serialize-qp "fields[betaTesters]" $fieldsbetaTesters "csv") (serialize-qp "fields[betaBuildLocalizations]" $fieldsbetaBuildLocalizations "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[betaBuildLocalizations]" $limitbetaBuildLocalizations "scalar") (serialize-qp "limit[icons]" $limiticons "scalar") (serialize-qp "limit[individualTesters]" $limitindividualTesters "scalar")] | flatten | str join "&"
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --include: list # comma-separated list of relationships to include
  --fieldsappEncryptionDeclarations: list # the fields to include for returned resources of type appEncryptionDeclarations
  --fieldsbetaAppReviewSubmissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
  --fieldsbuildBetaDetails: list # the fields to include for returned resources of type buildBetaDetails
  --fieldsbuildIcons: list # the fields to include for returned resources of type buildIcons
  --fieldsperfPowerMetrics: list # the fields to include for returned resources of type perfPowerMetrics
  --fieldspreReleaseVersions: list # the fields to include for returned resources of type preReleaseVersions
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
  --fieldsdiagnosticSignatures: list # the fields to include for returned resources of type diagnosticSignatures
  --fieldsbetaTesters: list # the fields to include for returned resources of type betaTesters
  --fieldsbetaBuildLocalizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitbetaBuildLocalizations: int # maximum number of related betaBuildLocalizations returned (when they are included)
  --limiticons: int # maximum number of related icons returned (when they are included)
  --limitindividualTesters: int # maximum number of related individualTesters returned (when they are included)
]: nothing -> record<data: record<attributes: record<expirationDate: string, expired: bool, iconAssetToken: record, minOsVersion: string, processingState: string, uploadedDate: string, usesNonExemptEncryption: bool, version: string>, id: string, links: record<self: string>, relationships: record<app: record, appEncryptionDeclaration: record, appStoreVersion: record, betaAppReviewSubmission: record, betaBuildLocalizations: record, buildBetaDetail: record, icons: record, individualTesters: record, preReleaseVersion: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[appEncryptionDeclarations]" $fieldsappEncryptionDeclarations "csv") (serialize-qp "fields[betaAppReviewSubmissions]" $fieldsbetaAppReviewSubmissions "csv") (serialize-qp "fields[buildBetaDetails]" $fieldsbuildBetaDetails "csv") (serialize-qp "fields[buildIcons]" $fieldsbuildIcons "csv") (serialize-qp "fields[perfPowerMetrics]" $fieldsperfPowerMetrics "csv") (serialize-qp "fields[preReleaseVersions]" $fieldspreReleaseVersions "csv") (serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv") (serialize-qp "fields[diagnosticSignatures]" $fieldsdiagnosticSignatures "csv") (serialize-qp "fields[betaTesters]" $fieldsbetaTesters "csv") (serialize-qp "fields[betaBuildLocalizations]" $fieldsbetaBuildLocalizations "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[betaBuildLocalizations]" $limitbetaBuildLocalizations "scalar") (serialize-qp "limit[icons]" $limiticons "scalar") (serialize-qp "limit[individualTesters]" $limitindividualTesters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/builds/($id)")
  let body = {data: $data} | compact
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
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/app" $qp)
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
  --fieldsappEncryptionDeclarations: list # the fields to include for returned resources of type appEncryptionDeclarations
]: nothing -> record<data: record<attributes: record<appEncryptionDeclarationState: string, availableOnFrenchStore: bool, codeValue: string, containsProprietaryCryptography: bool, containsThirdPartyCryptography: bool, documentName: string, documentType: string, documentUrl: string, exempt: bool, platform: string, uploadedDate: string, usesEncryption: bool>, id: string, links: record<self: string>, relationships: record<app: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appEncryptionDeclarations]" $fieldsappEncryptionDeclarations "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/appEncryptionDeclaration" $qp)
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
  --fieldsappStoreVersions: list # the fields to include for returned resources of type appStoreVersions
]: nothing -> record<data: record<attributes: record<appStoreState: string, copyright: string, createdDate: string, downloadable: bool, earliestReleaseDate: string, platform: string, releaseType: string, usesIdfa: bool, versionString: string>, id: string, links: record<self: string>, relationships: record<ageRatingDeclaration: record, app: record, appStoreReviewDetail: record, appStoreVersionLocalizations: record, appStoreVersionPhasedRelease: record, appStoreVersionSubmission: record, build: record, idfaDeclaration: record, routingAppCoverage: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[appStoreVersions]" $fieldsappStoreVersions "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/appStoreVersion" $qp)
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
  --fieldsbetaAppReviewSubmissions: list # the fields to include for returned resources of type betaAppReviewSubmissions
]: nothing -> record<data: record<attributes: record<betaReviewState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaAppReviewSubmissions]" $fieldsbetaAppReviewSubmissions "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/betaAppReviewSubmission" $qp)
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
  --fieldsbetaBuildLocalizations: list # the fields to include for returned resources of type betaBuildLocalizations
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaBuildLocalizations]" $fieldsbetaBuildLocalizations "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/betaBuildLocalizations" $qp)
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
  --fieldsbuildBetaDetails: list # the fields to include for returned resources of type buildBetaDetails
]: nothing -> record<data: record<attributes: record<autoNotifyEnabled: bool, externalBuildState: string, internalBuildState: string>, id: string, links: record<self: string>, relationships: record<build: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[buildBetaDetails]" $fieldsbuildBetaDetails "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/buildBetaDetail" $qp)
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
  --filterdiagnosticType: list # filter by attribute 'diagnosticType'
  --fieldsdiagnosticSignatures: list # the fields to include for returned resources of type diagnosticSignatures
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, included: table<id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[diagnosticType]" $filterdiagnosticType "csv") (serialize-qp "fields[diagnosticSignatures]" $fieldsdiagnosticSignatures "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/diagnosticSignatures" $qp)
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
  --fieldsbuildIcons: list # the fields to include for returned resources of type buildIcons
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[buildIcons]" $fieldsbuildIcons "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/icons" $qp)
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
  --fieldsbetaTesters: list # the fields to include for returned resources of type betaTesters
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[betaTesters]" $fieldsbetaTesters "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/individualTesters" $qp)
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
  --filterdeviceType: list # filter by attribute 'deviceType'
  --filtermetricType: list # filter by attribute 'metricType'
  --filterplatform: list # filter by attribute 'platform'
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[deviceType]" $filterdeviceType "csv") (serialize-qp "filter[metricType]" $filtermetricType "csv") (serialize-qp "filter[platform]" $filterplatform "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/perfPowerMetrics" $qp)
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
  --fieldspreReleaseVersions: list # the fields to include for returned resources of type preReleaseVersions
]: nothing -> record<data: record<attributes: record<platform: string, version: string>, id: string, links: record<self: string>, relationships: record<app: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[preReleaseVersions]" $fieldspreReleaseVersions "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/builds/($id)/preReleaseVersion" $qp)
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
  let full_url = (build-url $base $"/v1/builds/($id)/relationships/appEncryptionDeclaration")
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
  let full_url = (build-url $base $"/v1/builds/($id)/relationships/appEncryptionDeclaration")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/builds/($id)/relationships/betaGroups")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/builds/($id)/relationships/betaGroups")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/builds/($id)/relationships/individualTesters")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/builds/($id)/relationships/individualTesters" $qp)
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
  let full_url = (build-url $base $"/v1/builds/($id)/relationships/individualTesters")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/bundleIdCapabilities/($id)")
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
  let full_url = (build-url $base $"/v1/bundleIdCapabilities/($id)")
  let body = {data: $data} | compact
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
  --filteridentifier: list # filter by attribute 'identifier'
  --filtername: list # filter by attribute 'name'
  --filterplatform: list # filter by attribute 'platform'
  --filterseedId: list # filter by attribute 'seedId'
  --filterid: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsbundleIds: list # the fields to include for returned resources of type bundleIds
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsbundleIdCapabilities: list # the fields to include for returned resources of type bundleIdCapabilities
  --fieldsprofiles: list # the fields to include for returned resources of type profiles
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitbundleIdCapabilities: int # maximum number of related bundleIdCapabilities returned (when they are included)
  --limitprofiles: int # maximum number of related profiles returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[identifier]" $filteridentifier "csv") (serialize-qp "filter[name]" $filtername "csv") (serialize-qp "filter[platform]" $filterplatform "csv") (serialize-qp "filter[seedId]" $filterseedId "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[bundleIds]" $fieldsbundleIds "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[bundleIdCapabilities]" $fieldsbundleIdCapabilities "csv") (serialize-qp "fields[profiles]" $fieldsprofiles "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[bundleIdCapabilities]" $limitbundleIdCapabilities "scalar") (serialize-qp "limit[profiles]" $limitprofiles "scalar")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/bundleIds/($id)")
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
  --fieldsbundleIds: list # the fields to include for returned resources of type bundleIds
  --include: list # comma-separated list of relationships to include
  --fieldsbundleIdCapabilities: list # the fields to include for returned resources of type bundleIdCapabilities
  --fieldsprofiles: list # the fields to include for returned resources of type profiles
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitbundleIdCapabilities: int # maximum number of related bundleIdCapabilities returned (when they are included)
  --limitprofiles: int # maximum number of related profiles returned (when they are included)
]: nothing -> record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[bundleIds]" $fieldsbundleIds "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[bundleIdCapabilities]" $fieldsbundleIdCapabilities "csv") (serialize-qp "fields[profiles]" $fieldsprofiles "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[bundleIdCapabilities]" $limitbundleIdCapabilities "scalar") (serialize-qp "limit[profiles]" $limitprofiles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bundleIds/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/bundleIds/($id)")
  let body = {data: $data} | compact
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
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bundleIds/($id)/app" $qp)
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
  --fieldsbundleIdCapabilities: list # the fields to include for returned resources of type bundleIdCapabilities
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[bundleIdCapabilities]" $fieldsbundleIdCapabilities "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bundleIds/($id)/bundleIdCapabilities" $qp)
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
  --fieldsprofiles: list # the fields to include for returned resources of type profiles
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profiles]" $fieldsprofiles "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/bundleIds/($id)/profiles" $qp)
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
  --filtercertificateType: list # filter by attribute 'certificateType'
  --filterdisplayName: list # filter by attribute 'displayName'
  --filterserialNumber: list # filter by attribute 'serialNumber'
  --filterid: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldscertificates: list # the fields to include for returned resources of type certificates
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[certificateType]" $filtercertificateType "csv") (serialize-qp "filter[displayName]" $filterdisplayName "csv") (serialize-qp "filter[serialNumber]" $filterserialNumber "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[certificates]" $fieldscertificates "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/certificates/($id)")
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
  --fieldscertificates: list # the fields to include for returned resources of type certificates
]: nothing -> record<data: record<attributes: record<certificateContent: string, certificateType: string, displayName: string, expirationDate: string, name: string, platform: string, serialNumber: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[certificates]" $fieldscertificates "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/certificates/($id)" $qp)
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
  --filtername: list # filter by attribute 'name'
  --filterplatform: list # filter by attribute 'platform'
  --filterstatus: list # filter by attribute 'status'
  --filterudid: list # filter by attribute 'udid'
  --filterid: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsdevices: list # the fields to include for returned resources of type devices
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filtername "csv") (serialize-qp "filter[platform]" $filterplatform "csv") (serialize-qp "filter[status]" $filterstatus "csv") (serialize-qp "filter[udid]" $filterudid "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[devices]" $fieldsdevices "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  --fieldsdevices: list # the fields to include for returned resources of type devices
]: nothing -> record<data: record<attributes: record<addedDate: string, deviceClass: string, model: string, name: string, platform: string, status: string, udid: string>, id: string, links: record<self: string>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[devices]" $fieldsdevices "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/devices/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/devices/($id)")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/diagnosticSignatures/($id)/logs" $qp)
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/endUserLicenseAgreements/($id)")
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
  --fieldsendUserLicenseAgreements: list # the fields to include for returned resources of type endUserLicenseAgreements
  --include: list # comma-separated list of relationships to include
  --fieldsterritories: list # the fields to include for returned resources of type territories
  --limitterritories: int # maximum number of related territories returned (when they are included)
]: nothing -> record<data: record<attributes: record<agreementText: string>, id: string, links: record<self: string>, relationships: record<app: record, territories: record>, type: string>, included: table<attributes: record, id: string, links: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[endUserLicenseAgreements]" $fieldsendUserLicenseAgreements "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[territories]" $fieldsterritories "csv") (serialize-qp "limit[territories]" $limitterritories "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/endUserLicenseAgreements/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/endUserLicenseAgreements/($id)")
  let body = {data: $data} | compact
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
  --fieldsterritories: list # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[territories]" $fieldsterritories "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/endUserLicenseAgreements/($id)/territories" $qp)
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
  --filterregionCode: list # filter by attribute 'regionCode'
  --filterreportDate: list # filter by attribute 'reportDate'
  --filterreportType: list # filter by attribute 'reportType'
  --filtervendorNumber: list # filter by attribute 'vendorNumber'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[regionCode]" $filterregionCode "csv") (serialize-qp "filter[reportDate]" $filterreportDate "csv") (serialize-qp "filter[reportType]" $filterreportType "csv") (serialize-qp "filter[vendorNumber]" $filtervendorNumber "csv")] | flatten | str join "&"
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
  --filterplatform: list # filter by attribute 'platform'
  --filterversionString: list # filter by attribute 'versionString'
  --filterapp: list # filter by id(s) of related 'app'
  --filterid: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsgameCenterEnabledVersions: list # the fields to include for returned resources of type gameCenterEnabledVersions
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[platform]" $filterplatform "csv") (serialize-qp "filter[versionString]" $filterversionString "csv") (serialize-qp "filter[app]" $filterapp "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[gameCenterEnabledVersions]" $fieldsgameCenterEnabledVersions "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/gameCenterEnabledVersions/($id)/compatibleVersions" $qp)
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
  let full_url = (build-url $base $"/v1/gameCenterEnabledVersions/($id)/relationships/compatibleVersions")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/gameCenterEnabledVersions/($id)/relationships/compatibleVersions" $qp)
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
  let full_url = (build-url $base $"/v1/gameCenterEnabledVersions/($id)/relationships/compatibleVersions")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/gameCenterEnabledVersions/($id)/relationships/compatibleVersions")
  let body = {data: $data} | compact
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/idfaDeclarations/($id)")
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
  let full_url = (build-url $base $"/v1/idfaDeclarations/($id)")
  let body = {data: $data} | compact
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
  --fieldsinAppPurchases: list # the fields to include for returned resources of type inAppPurchases
  --include: list # comma-separated list of relationships to include
  --limitapps: int # maximum number of related apps returned (when they are included)
]: nothing -> record<data: record<attributes: record<inAppPurchaseType: string, productId: string, referenceName: string, state: string>, id: string, links: record<self: string>, relationships: record<apps: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[inAppPurchases]" $fieldsinAppPurchases "csv") (serialize-qp "include" $include "csv") (serialize-qp "limit[apps]" $limitapps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/inAppPurchases/($id)" $qp)
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
  --filterbuildsexpired: list # filter by attribute 'builds.expired'
  --filterbuildsprocessingState: list # filter by attribute 'builds.processingState'
  --filterplatform: list # filter by attribute 'platform'
  --filterversion: list # filter by attribute 'version'
  --filterapp: list # filter by id(s) of related 'app'
  --filterbuilds: list # filter by id(s) of related 'builds'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldspreReleaseVersions: list # the fields to include for returned resources of type preReleaseVersions
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitbuilds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[builds.expired]" $filterbuildsexpired "csv") (serialize-qp "filter[builds.processingState]" $filterbuildsprocessingState "csv") (serialize-qp "filter[platform]" $filterplatform "csv") (serialize-qp "filter[version]" $filterversion "csv") (serialize-qp "filter[app]" $filterapp "csv") (serialize-qp "filter[builds]" $filterbuilds "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[preReleaseVersions]" $fieldspreReleaseVersions "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[builds]" $limitbuilds "scalar")] | flatten | str join "&"
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
  --fieldspreReleaseVersions: list # the fields to include for returned resources of type preReleaseVersions
  --include: list # comma-separated list of relationships to include
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitbuilds: int # maximum number of related builds returned (when they are included)
]: nothing -> record<data: record<attributes: record<platform: string, version: string>, id: string, links: record<self: string>, relationships: record<app: record, builds: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[preReleaseVersions]" $fieldspreReleaseVersions "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[builds]" $limitbuilds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/preReleaseVersions/($id)" $qp)
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
  --fieldsapps: list # the fields to include for returned resources of type apps
]: nothing -> record<data: record<attributes: record<availableInNewTerritories: bool, bundleId: string, contentRightsDeclaration: string, isOrEverWasMadeForKids: bool, name: string, primaryLocale: string, sku: string>, id: string, links: record<self: string>, relationships: record<appInfos: record, appStoreVersions: record, availableTerritories: record, betaAppLocalizations: record, betaAppReviewDetail: record, betaGroups: record, betaLicenseAgreement: record, builds: record, endUserLicenseAgreement: record, gameCenterEnabledVersions: record, inAppPurchases: record, preOrder: record, preReleaseVersions: record, prices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/preReleaseVersions/($id)/app" $qp)
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
  --fieldsbuilds: list # the fields to include for returned resources of type builds
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[builds]" $fieldsbuilds "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/preReleaseVersions/($id)/builds" $qp)
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
  --filtername: list # filter by attribute 'name'
  --filterprofileState: list # filter by attribute 'profileState'
  --filterprofileType: list # filter by attribute 'profileType'
  --filterid: list # filter by id(s)
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsprofiles: list # the fields to include for returned resources of type profiles
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldscertificates: list # the fields to include for returned resources of type certificates
  --fieldsdevices: list # the fields to include for returned resources of type devices
  --fieldsbundleIds: list # the fields to include for returned resources of type bundleIds
  --limitcertificates: int # maximum number of related certificates returned (when they are included)
  --limitdevices: int # maximum number of related devices returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filtername "csv") (serialize-qp "filter[profileState]" $filterprofileState "csv") (serialize-qp "filter[profileType]" $filterprofileType "csv") (serialize-qp "filter[id]" $filterid "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[profiles]" $fieldsprofiles "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[certificates]" $fieldscertificates "csv") (serialize-qp "fields[devices]" $fieldsdevices "csv") (serialize-qp "fields[bundleIds]" $fieldsbundleIds "csv") (serialize-qp "limit[certificates]" $limitcertificates "scalar") (serialize-qp "limit[devices]" $limitdevices "scalar")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/profiles/($id)")
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
  --fieldsprofiles: list # the fields to include for returned resources of type profiles
  --include: list # comma-separated list of relationships to include
  --fieldscertificates: list # the fields to include for returned resources of type certificates
  --fieldsdevices: list # the fields to include for returned resources of type devices
  --fieldsbundleIds: list # the fields to include for returned resources of type bundleIds
  --limitcertificates: int # maximum number of related certificates returned (when they are included)
  --limitdevices: int # maximum number of related devices returned (when they are included)
]: nothing -> record<data: record<attributes: record<createdDate: string, expirationDate: string, name: string, platform: string, profileContent: string, profileState: string, profileType: string, uuid: string>, id: string, links: record<self: string>, relationships: record<bundleId: record, certificates: record, devices: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profiles]" $fieldsprofiles "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[certificates]" $fieldscertificates "csv") (serialize-qp "fields[devices]" $fieldsdevices "csv") (serialize-qp "fields[bundleIds]" $fieldsbundleIds "csv") (serialize-qp "limit[certificates]" $limitcertificates "scalar") (serialize-qp "limit[devices]" $limitdevices "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/profiles/($id)" $qp)
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
  --fieldsbundleIds: list # the fields to include for returned resources of type bundleIds
]: nothing -> record<data: record<attributes: record<identifier: string, name: string, platform: string, seedId: string>, id: string, links: record<self: string>, relationships: record<app: record, bundleIdCapabilities: record, profiles: record>, type: string>, included: list<any>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[bundleIds]" $fieldsbundleIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/profiles/($id)/bundleId" $qp)
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
  --fieldscertificates: list # the fields to include for returned resources of type certificates
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[certificates]" $fieldscertificates "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/profiles/($id)/certificates" $qp)
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
  --fieldsdevices: list # the fields to include for returned resources of type devices
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[devices]" $fieldsdevices "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/profiles/($id)/devices" $qp)
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/routingAppCoverages/($id)")
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
  --fieldsroutingAppCoverages: list # the fields to include for returned resources of type routingAppCoverages
  --include: list # comma-separated list of relationships to include
]: nothing -> record<data: record<attributes: record<assetDeliveryState: record, fileName: string, fileSize: int, sourceFileChecksum: string, uploadOperations: list>, id: string, links: record<self: string>, relationships: record<appStoreVersion: record>, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[routingAppCoverages]" $fieldsroutingAppCoverages "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/routingAppCoverages/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/routingAppCoverages/($id)")
  let body = {data: $data} | compact
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
  --filterfrequency: list # filter by attribute 'frequency'
  --filterreportDate: list # filter by attribute 'reportDate'
  --filterreportSubType: list # filter by attribute 'reportSubType'
  --filterreportType: list # filter by attribute 'reportType'
  --filtervendorNumber: list # filter by attribute 'vendorNumber'
  --filterversion: list # filter by attribute 'version'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[frequency]" $filterfrequency "csv") (serialize-qp "filter[reportDate]" $filterreportDate "csv") (serialize-qp "filter[reportSubType]" $filterreportSubType "csv") (serialize-qp "filter[reportType]" $filterreportType "csv") (serialize-qp "filter[vendorNumber]" $filtervendorNumber "csv") (serialize-qp "filter[version]" $filterversion "csv")] | flatten | str join "&"
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
  --fieldsterritories: list # the fields to include for returned resources of type territories
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[territories]" $fieldsterritories "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
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
  --filteremail: list # filter by attribute 'email'
  --filterroles: list # filter by attribute 'roles'
  --filtervisibleApps: list # filter by id(s) of related 'visibleApps'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsuserInvitations: list # the fields to include for returned resources of type userInvitations
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitvisibleApps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[email]" $filteremail "csv") (serialize-qp "filter[roles]" $filterroles "csv") (serialize-qp "filter[visibleApps]" $filtervisibleApps "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[userInvitations]" $fieldsuserInvitations "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[visibleApps]" $limitvisibleApps "scalar")] | flatten | str join "&"
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
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/userInvitations/($id)")
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
  --fieldsuserInvitations: list # the fields to include for returned resources of type userInvitations
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitvisibleApps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> record<data: record<attributes: record<allAppsVisible: bool, email: string, expirationDate: string, firstName: string, lastName: string, provisioningAllowed: bool, roles: list>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[userInvitations]" $fieldsuserInvitations "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[visibleApps]" $limitvisibleApps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/userInvitations/($id)" $qp)
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
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/userInvitations/($id)/visibleApps" $qp)
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
  --filterroles: list # filter by attribute 'roles'
  --filterusername: list # filter by attribute 'username'
  --filtervisibleApps: list # filter by id(s) of related 'visibleApps'
  --qp-sort: list # comma-separated list of sort expressions; resources will be sorted as specified
  --fieldsusers: list # the fields to include for returned resources of type users
  --limit: int # maximum resources per page
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitvisibleApps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[roles]" $filterroles "csv") (serialize-qp "filter[username]" $filterusername "csv") (serialize-qp "filter[visibleApps]" $filtervisibleApps "csv") (serialize-qp "sort" $qp_sort "csv") (serialize-qp "fields[users]" $fieldsusers "csv") (serialize-qp "limit" $limit "scalar") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[visibleApps]" $limitvisibleApps "scalar")] | flatten | str join "&"
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
  let full_url = (build-url $base $"/v1/users/($id)")
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
  --fieldsusers: list # the fields to include for returned resources of type users
  --include: list # comma-separated list of relationships to include
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limitvisibleApps: int # maximum number of related visibleApps returned (when they are included)
]: nothing -> record<data: record<attributes: record<allAppsVisible: bool, firstName: string, lastName: string, provisioningAllowed: bool, roles: list, username: string>, id: string, links: record<self: string>, relationships: record<visibleApps: record>, type: string>, included: table<attributes: record, id: string, links: record, relationships: record, type: string>, links: record<self: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[users]" $fieldsusers "csv") (serialize-qp "include" $include "csv") (serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit[visibleApps]" $limitvisibleApps "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($id)" $qp)
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
  let full_url = (build-url $base $"/v1/users/($id)")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/users/($id)/relationships/visibleApps")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/users/($id)/relationships/visibleApps" $qp)
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
  let full_url = (build-url $base $"/v1/users/($id)/relationships/visibleApps")
  let body = {data: $data} | compact
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
  let full_url = (build-url $base $"/v1/users/($id)/relationships/visibleApps")
  let body = {data: $data} | compact
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
  --fieldsapps: list # the fields to include for returned resources of type apps
  --limit: int # maximum resources per page
]: nothing -> record<data: table<attributes: record, id: string, links: record, relationships: record, type: string>, included: list<any>, links: record<first: string, next: string, self: string>, meta: record<paging: record<limit: int, total: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[apps]" $fieldsapps "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($id)/visibleApps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
