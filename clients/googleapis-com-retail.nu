# Auto-generated client for Retail API vv2alpha
# Source: https://api.apis.guru/v2/specs/googleapis.com/retail/v2alpha/openapi.json
# Auth: --token flag or $env.RETAIL_API_TOKEN

const BASE_URL = "https://retail.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RETAIL_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://retail.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def diversity-type-completer [] { ["DATA_DRIVEN_DIVERSITY" "DIVERSITY_TYPE_UNSPECIFIED" "RULE_BASED_DIVERSITY"] }
def filtering-option-completer [] { ["RECOMMENDATIONS_FILTERING_DISABLED" "RECOMMENDATIONS_FILTERING_ENABLED" "RECOMMENDATIONS_FILTERING_OPTION_UNSPECIFIED"] }
def periodic-tuning-state-completer [] { ["ALL_TUNING_DISABLED" "PERIODIC_TUNING_DISABLED" "PERIODIC_TUNING_ENABLED" "PERIODIC_TUNING_STATE_UNSPECIFIED"] }
def training-state-completer [] { ["PAUSED" "TRAINING" "TRAINING_STATE_UNSPECIFIED"] }
def availability-completer [] { ["AVAILABILITY_UNSPECIFIED" "BACKORDER" "IN_STOCK" "OUT_OF_STOCK" "PREORDER"] }
def type-completer [] { ["COLLECTION" "PRIMARY" "TYPE_UNSPECIFIED" "VARIANT"] }
def reconciliation-mode-completer [] { ["FULL" "INCREMENTAL" "RECONCILIATION_MODE_UNSPECIFIED"] }
def user-event-rejoin-scope-completer [] { ["JOINED_EVENTS" "UNJOINED_EVENTS" "USER_EVENT_REJOIN_SCOPE_UNSPECIFIED"] }
def relevance-threshold-completer [] { ["HIGH" "LOW" "LOWEST" "MEDIUM" "RELEVANCE_THRESHOLD_UNSPECIFIED"] }
def search-mode-completer [] { ["FACETED_SEARCH_ONLY" "PRODUCT_SEARCH_ONLY" "SEARCH_MODE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v2alpha create-catalog-attribute" } } | get name | first)
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

# Adds the specified CatalogAttribute to the AttributesConfig. If the CatalogAttribute to add already exists, an ALREADY_EXISTS error is returned.
#
# POST /v2alpha/{attributesConfig}:addCatalogAttribute
# operationId: retail.projects.locations.catalogs.attributesConfig.addCatalogAttribute
# --catalogAttribute shape: {dynamicFacetableOption?: "DYNAMIC_FACETABLE_OPTION_UNSPECIFIED"|"DYNAMIC_FACETABLE_ENABLED"|"DYNAMIC_FACETABLE_DISABLED", exactSearchableOption?: "EXACT_SEARCHABLE_OPTION_UNSPECIFIED"|"EXACT_SEARCHABLE_ENABLED"|"EXACT_SEARCHABLE_DISABLED", indexableOption?: "INDEXABLE_OPTION_UNSPECIFIED"|"INDEXABLE_ENABLED"|"INDEXABLE_DISABLED", key?: string, recommendationsFilteringOption?: "RECOMMENDATIONS_FILTERING_OPTION_UNSPECIFIED"|"RECOMMENDATIONS_FILTERING_DISABLED"|"RECOMMENDATIONS_FILTERING_ENABLED", ... (2 more fields)}
export def "v2alpha create-catalog-attribute" [
  attributes_config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --catalog-attribute: record # Catalog level attribute config for an attribute. For example, if customers want to enable/disable facet for a specific attribute. — shape: {dynamicFacetableOption?: "DYNAMIC_FACETABLE_OPTION_UNSPECIFIED"|"DYNAMIC_FACETABLE_ENABLED"|"DYNAMIC_FACETABLE_DISABLED", exactSearchableOption?: "EXACT_SEARCHABLE_OPTION_UNSPECIFIED"|"EXACT_SEARCHABLE_ENABLED"|"EXACT_SEARCHABLE_DISABLED", indexableOption?: "INDEXABLE_OPTION_UNSPECIFIED"|"INDEXABLE_ENABLED"|"INDEXABLE_DISABLED", key?: string, recommendationsFilteringOption?: "RECOMMENDATIONS_FILTERING_OPTION_UNSPECIFIED"|"RECOMMENDATIONS_FILTERING_DISABLED"|"RECOMMENDATIONS_FILTERING_ENABLED", ... (2 more fields)}
]: any -> record<attributeConfigLevel: string, catalogAttributes: record, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attributes_config: (encode-path-segment $attributes_config)} | format pattern "/v2alpha/{attributes_config}:addCatalogAttribute") $qp)
  let req_body = {"catalogAttribute": $catalog_attribute} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes all specified CatalogAttributes from the AttributesConfig.
#
# POST /v2alpha/{attributesConfig}:batchRemoveCatalogAttributes
# operationId: retail.projects.locations.catalogs.attributesConfig.batchRemoveCatalogAttributes
export def "v2alpha delete-batch-catalog-attributes" [
  attributes_config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --attribute-keys: list<string> # Required. The attribute name keys of the CatalogAttributes to delete. A maximum of 1000 catalog attributes can be deleted in a batch.
]: any -> record<deletedCatalogAttributes: list<string>, resetCatalogAttributes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attributes_config: (encode-path-segment $attributes_config)} | format pattern "/v2alpha/{attributes_config}:batchRemoveCatalogAttributes") $qp)
  let req_body = {"attributeKeys": $attribute_keys} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Removes the specified CatalogAttribute from the AttributesConfig. If the CatalogAttribute to remove does not exist, a NOT_FOUND error is returned.
#
# POST /v2alpha/{attributesConfig}:removeCatalogAttribute
# operationId: retail.projects.locations.catalogs.attributesConfig.removeCatalogAttribute
export def "v2alpha delete-catalog-attribute" [
  attributes_config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --key: string # Required. The attribute name key of the CatalogAttribute to remove.
]: any -> record<attributeConfigLevel: string, catalogAttributes: record, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attributes_config: (encode-path-segment $attributes_config)} | format pattern "/v2alpha/{attributes_config}:removeCatalogAttribute") $qp)
  let req_body = {"key": $key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Replaces the specified CatalogAttribute in the AttributesConfig by updating the catalog attribute with the same CatalogAttribute.key. If the CatalogAttribute to replace does not exist, a NOT_FOUND error is returned.
#
# POST /v2alpha/{attributesConfig}:replaceCatalogAttribute
# operationId: retail.projects.locations.catalogs.attributesConfig.replaceCatalogAttribute
# --catalogAttribute shape: {dynamicFacetableOption?: "DYNAMIC_FACETABLE_OPTION_UNSPECIFIED"|"DYNAMIC_FACETABLE_ENABLED"|"DYNAMIC_FACETABLE_DISABLED", exactSearchableOption?: "EXACT_SEARCHABLE_OPTION_UNSPECIFIED"|"EXACT_SEARCHABLE_ENABLED"|"EXACT_SEARCHABLE_DISABLED", indexableOption?: "INDEXABLE_OPTION_UNSPECIFIED"|"INDEXABLE_ENABLED"|"INDEXABLE_DISABLED", key?: string, recommendationsFilteringOption?: "RECOMMENDATIONS_FILTERING_OPTION_UNSPECIFIED"|"RECOMMENDATIONS_FILTERING_DISABLED"|"RECOMMENDATIONS_FILTERING_ENABLED", ... (2 more fields)}
export def "v2alpha update-catalog-attribute" [
  attributes_config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --catalog-attribute: record # Catalog level attribute config for an attribute. For example, if customers want to enable/disable facet for a specific attribute. — shape: {dynamicFacetableOption?: "DYNAMIC_FACETABLE_OPTION_UNSPECIFIED"|"DYNAMIC_FACETABLE_ENABLED"|"DYNAMIC_FACETABLE_DISABLED", exactSearchableOption?: "EXACT_SEARCHABLE_OPTION_UNSPECIFIED"|"EXACT_SEARCHABLE_ENABLED"|"EXACT_SEARCHABLE_DISABLED", indexableOption?: "INDEXABLE_OPTION_UNSPECIFIED"|"INDEXABLE_ENABLED"|"INDEXABLE_DISABLED", key?: string, recommendationsFilteringOption?: "RECOMMENDATIONS_FILTERING_OPTION_UNSPECIFIED"|"RECOMMENDATIONS_FILTERING_DISABLED"|"RECOMMENDATIONS_FILTERING_ENABLED", ... (2 more fields)}
  --update-mask: string # Indicates which fields in the provided CatalogAttribute to update. The following are NOT supported: * CatalogAttribute.key If not set, all supported fields are updated. (format: google-fieldmask)
]: any -> record<attributeConfigLevel: string, catalogAttributes: record, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attributes_config: (encode-path-segment $attributes_config)} | format pattern "/v2alpha/{attributes_config}:replaceCatalogAttribute") $qp)
  let req_body = {"catalogAttribute": $catalog_attribute, "updateMask": $update_mask} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Completes the specified prefix with keyword suggestions. This feature is only available for users who have Retail Search enabled. Enable Retail Search on Cloud Console before using this feature.
#
# GET /v2alpha/{catalog}:completeQuery
# operationId: retail.projects.locations.catalogs.completeQuery
export def "v2alpha complete-list" [
  catalog: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --dataset: string # Determines which dataset to use for fetching completion. "user-data" will use the imported dataset through CompletionService.ImportCompletionData. "cloud-retail" will use the dataset generated by cloud retail based on user events. If leave empty, it will use the "user-data". Current supported values: * user-data * cloud-retail: This option requires enabling auto-learning function first. See [guidelines](https://cloud.google.com/retail/docs/completion-overview#generated-completion-dataset).
  --device-type: string # The device type context for completion suggestions. We recommend that you leave this field empty. It can apply different suggestions on different device types, e.g. `DESKTOP`, `MOBILE`. If it is empty, the suggestions are across all device types. Supported formats: * `UNKNOWN_DEVICE_TYPE` * `DESKTOP` * `MOBILE` * A customized string starts with `OTHER_`, e.g. `OTHER_IPHONE`.
  --enable-attribute-suggestions: oneof<nothing, bool> # If true, attribute suggestions are enabled and provided in response. This field is only available for "cloud-retail" dataset.
  --entity: string # The entity for customers that may run multiple different entities, domains, sites or regions, for example, `Google US`, `Google Ads`, `Waymo`, `google.com`, `youtube.com`, etc. If this is set, it should be exactly matched with UserEvent.entity to get per-entity autocomplete results.
  --language-codes: list<string> # Note that this field applies for `user-data` dataset only. For requests with `cloud-retail` dataset, setting this field has no effect. The language filters applied to the output suggestions. If set, it should contain the language of the query. If not set, suggestions are returned without considering language restrictions. This is the BCP-47 language code, such as "en-US" or "sr-Latn". For more information, see [Tags for Identifying Languages](https://tools.ietf.org/html/bcp47). The maximum number of language codes is 3.
  --max-suggestions: int # Completion max suggestions. If left unset or set to 0, then will fallback to the configured value CompletionConfig.max_suggestions. The maximum allowed max suggestions is 20. If it is set higher, it will be capped by 20.
  --query: string # Required. The query used to generate suggestions. The maximum number of allowed characters is 255.
  --visitor-id: string # Required field. A unique identifier for tracking visitors. For example, this could be implemented with an HTTP cookie, which should be able to uniquely identify a visitor on a single device. This unique identifier should not change if the visitor logs in or out of the website. The field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned.
]: nothing -> record<attributeResults: record, attributionToken: string, completionResults: table<attributes: record, facets: list, suggestion: string, totalProductCount: int>, recentSearchResults: table<recentSearch: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dataset" $dataset "scalar") (serialize-qp "deviceType" $device_type "scalar") (serialize-qp "enableAttributeSuggestions" $enable_attribute_suggestions "scalar") (serialize-qp "entity" $entity "scalar") (serialize-qp "languageCodes" $language_codes "multi") (serialize-qp "maxSuggestions" $max_suggestions "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "visitorId" $visitor_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({catalog: (encode-path-segment $catalog)} | format pattern "/v2alpha/{catalog}:completeQuery") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get which branch is currently default branch set by CatalogService.SetDefaultBranch method under a specified parent catalog.
#
# GET /v2alpha/{catalog}:getDefaultBranch
# operationId: retail.projects.locations.catalogs.getDefaultBranch
export def "v2alpha get-default-branch" [
  catalog: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<branch: string, note: string, setTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({catalog: (encode-path-segment $catalog)} | format pattern "/v2alpha/{catalog}:getDefaultBranch") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set a specified branch id as default branch. API methods such as SearchService.Search, ProductService.GetProduct, ProductService.ListProducts will treat requests using "default_branch" to the actual branch id set as default. For example, if `projects/*/locations/*/catalogs/*/branches/1` is set as default, setting SearchRequest.branch to `projects/*/locations/*/catalogs/*/branches/default_branch` is equivalent to setting SearchRequest.branch to `projects/*/locations/*/catalogs/*/branches/1`. Using multiple branches can be useful when developers would like to have a staging branch to test and verify for future usage. When it becomes ready, developers switch on the staging branch using this API while keeping using `projects/*/locations/*/catalogs/*/branches/default_branch` as SearchRequest.branch to route the traffic to this staging branch. CAUTION: If you have live predict/search traffic, switching the default branch could potentially cause outages if the ID space of the new branch is very different from the old one. More specifically: * PredictionService will only return product IDs from branch {newBranch}. * SearchService will only return product IDs from branch {newBranch} (if branch is not explicitly set). * UserEventService will only join events with products from branch {newBranch}.
#
# POST /v2alpha/{catalog}:setDefaultBranch
# operationId: retail.projects.locations.catalogs.setDefaultBranch
export def "v2alpha update-default-branch" [
  catalog: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --branch-id: string # The final component of the resource name of a branch. This field must be one of "0", "1" or "2". Otherwise, an INVALID_ARGUMENT error is returned. If there are no sufficient active products in the targeted branch and force is not set, a FAILED_PRECONDITION error is returned.
  --force: oneof<nothing, bool> # If set to true, it permits switching to a branch with branch_id even if it has no sufficient active products.
  --note: string # Some note on this request, this can be retrieved by CatalogService.GetDefaultBranch before next valid default branch set occurs. This field must be a UTF-8 encoded string with a length limit of 1,000 characters. Otherwise, an INVALID_ARGUMENT error is returned.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({catalog: (encode-path-segment $catalog)} | format pattern "/v2alpha/{catalog}:setDefaultBranch") $qp)
  let req_body = {"branchId": $branch_id, "force": $force, "note": $note} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes a ServingConfig. Returns a NotFound error if the ServingConfig does not exist.
#
# DELETE /v2alpha/{name}
# operationId: retail.projects.locations.catalogs.servingConfigs.delete
export def "v2alpha delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --force: oneof<nothing, bool> # This value only applies to the case when the target product is of type PRIMARY. When deleting a product of VARIANT/COLLECTION type, this value will be ignored. When set to true, the subsequent variant products will be deleted. When set to false, if the primary product has active variant products, an error will be returned.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "force" $force "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the latest state of a long-running operation. Clients can use this method to poll the operation result at intervals as recommended by the API service.
#
# GET /v2alpha/{name}
# operationId: retail.projects.operations.get
export def "v2alpha get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a ServingConfig.
#
# PATCH /v2alpha/{name}
# operationId: retail.projects.locations.catalogs.servingConfigs.patch
# --dynamicFacetSpec shape: {mode?: "MODE_UNSPECIFIED"|"DISABLED"|"ENABLED"}
# --personalizationSpec shape: {mode?: "MODE_UNSPECIFIED"|"AUTO"|"DISABLED"}
export def "v2alpha update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --update-mask: string # Indicates which fields in the provided ServingConfig to update. The following are NOT supported: * ServingConfig.name If not set, all supported fields are updated.
  --boost-control-ids: list<string> # Condition boost specifications. If a product matches multiple conditions in the specifications, boost scores from these specifications are all applied and combined in a non-linear way. Maximum number of specifications is 100. Notice that if both ServingConfig.boost_control_ids and SearchRequest.boost_spec are set, the boost conditions from both places are evaluated. If a search request matches multiple boost conditions, the final boost score is equal to the sum of the boost scores from all matched boost conditions. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --display-name: string # Required. The human readable serving config display name. Used in Retail UI. This field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned.
  --diversity-level: string # How much diversity to use in recommendation model results e.g. `medium-diversity` or `high-diversity`. Currently supported values: * `no-diversity` * `low-diversity` * `medium-diversity` * `high-diversity` * `auto-diversity` If not specified, we choose default based on recommendation model type. Default value: `no-diversity`. Can only be set if solution_types is SOLUTION_TYPE_RECOMMENDATION.
  --diversity-type: string@diversity-type-completer # What kind of diversity to use - data driven or rule based. If unset, the server behavior defaults to RULE_BASED_DIVERSITY.
  --do-not-associate-control-ids: list<string> # Condition do not associate specifications. If multiple do not associate conditions match, all matching do not associate controls in the list will execute. - Order does not matter. - Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --dynamic-facet-spec: record # The specifications of dynamically generated facets. — shape: {mode?: "MODE_UNSPECIFIED"|"DISABLED"|"ENABLED"}
  --enable-category-filter-level: string # Whether to add additional category filters on the `similar-items` model. If not specified, we enable it by default. Allowed values are: * `no-category-match`: No additional filtering of original results from the model and the customer's filters. * `relaxed-category-match`: Only keep results with categories that match at least one item categories in the PredictRequests's context item. * If customer also sends filters in the PredictRequest, then the results will satisfy both conditions (user given and category match). Can only be set if solution_types is SOLUTION_TYPE_RECOMMENDATION.
  --facet-control-ids: list<string> # Facet specifications for faceted search. If empty, no facets are returned. The ids refer to the ids of Control resources with only the Facet control set. These controls are assumed to be in the same Catalog as the ServingConfig. A maximum of 100 values are allowed. Otherwise, an INVALID_ARGUMENT error is returned. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --filter-control-ids: list<string> # Condition filter specifications. If a product matches multiple conditions in the specifications, filters from these specifications are all applied and combined via the AND operator. Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --ignore-control-ids: list<string> # Condition ignore specifications. If multiple ignore conditions match, all matching ignore controls in the list will execute. - Order does not matter. - Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --model-id: string # The id of the model in the same Catalog to use at serving time. Currently only RecommendationModels are supported: https://cloud.google.com/retail/recommendations-ai/docs/create-models Can be changed but only to a compatible model (e.g. others-you-may-like CTR to others-you-may-like CVR). Required when solution_types is SOLUTION_TYPE_RECOMMENDATION.
  --body-name: string # Immutable. Fully qualified name `projects/*/locations/global/catalogs/*/servingConfig/*`
  --oneway-synonyms-control-ids: list<string> # Condition oneway synonyms specifications. If multiple oneway synonyms conditions match, all matching oneway synonyms controls in the list will execute. Order of controls in the list will not matter. Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --personalization-spec: record # The specification for personalization. — shape: {mode?: "MODE_UNSPECIFIED"|"AUTO"|"DISABLED"}
  --price-reranking-level: string # How much price ranking we want in serving results. Price reranking causes product items with a similar recommendation probability to be ordered by price, with the highest-priced items first. This setting could result in a decrease in click-through and conversion rates. Allowed values are: * `no-price-reranking` * `low-price-reranking` * `medium-price-reranking` * `high-price-reranking` If not specified, we choose default based on model type. Default value: `no-price-reranking`. Can only be set if solution_types is SOLUTION_TYPE_RECOMMENDATION.
  --redirect-control-ids: list<string> # Condition redirect specifications. Only the first triggered redirect action is applied, even if multiple apply. Maximum number of specifications is 1000. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --replacement-control-ids: list<string> # Condition replacement specifications. - Applied according to the order in the list. - A previously replaced term can not be re-replaced. - Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --solution-types: list<string> # Required. Immutable. Specifies the solution types that a serving config can be associated with. Currently we support setting only one type of solution.
  --twoway-synonyms-control-ids: list<string> # Condition synonyms specifications. If multiple syonyms conditions match, all matching synonyms control in the list will execute. Order of controls in the list will not matter. Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
]: any -> record<boostControlIds: list<string>, displayName: string, diversityLevel: string, diversityType: string, doNotAssociateControlIds: list<string>, dynamicFacetSpec: record<mode: string>, enableCategoryFilterLevel: string, facetControlIds: list<string>, filterControlIds: list<string>, ignoreControlIds: list<string>, modelId: string, name: string, onewaySynonymsControlIds: list<string>, personalizationSpec: record<mode: string>, priceRerankingLevel: string, redirectControlIds: list<string>, replacementControlIds: list<string>, solutionTypes: list<string>, twowaySynonymsControlIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}") $qp)
  let req_body = {"boostControlIds": $boost_control_ids, "displayName": $display_name, "diversityLevel": $diversity_level, "diversityType": $diversity_type, "doNotAssociateControlIds": $do_not_associate_control_ids, "dynamicFacetSpec": $dynamic_facet_spec, "enableCategoryFilterLevel": $enable_category_filter_level, "facetControlIds": $facet_control_ids, "filterControlIds": $filter_control_ids, "ignoreControlIds": $ignore_control_ids, "modelId": $model_id, "name": $body_name, "onewaySynonymsControlIds": $oneway_synonyms_control_ids, "personalizationSpec": $personalization_spec, "priceRerankingLevel": $price_reranking_level, "redirectControlIds": $redirect_control_ids, "replacementControlIds": $replacement_control_ids, "solutionTypes": $solution_types, "twowaySynonymsControlIds": $twoway_synonyms_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Creates a MerchantCenterAccountLink. MerchantCenterAccountLink cannot be set to a different oneof field, if so an INVALID_ARGUMENT is returned.
#
# POST /v2alpha/{name}
# operationId: retail.projects.locations.catalogs.merchantCenterAccountLinks.createMerchantCenterAccountLink
# --feedFilters item shape: {primaryFeedId?: string, primaryFeedName?: string}
export def "v2alpha create-merchant-center-account-link" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --parent: string # Required. The branch resource where this MerchantCenterAccountLink will be created. Format: projects/{PROJECT_NUMBER}/locations/global/catalogs/{CATALOG_ID}}
  --branch-id: string # Required. The branch id (e.g. 0/1/2) within the catalog that products from merchant_center_account_id are streamed to. When updating this field, an empty value will use the currently configured default branch. However, changing the default branch later on won't change the linked branch here. A single branch id can only have one linked merchant center account id.
  --feed-filters: list # Criteria for the Merchant Center feeds to be ingested via the link. All offers will be ingested if the list is empty. Otherwise the offers will be ingested from selected feeds. — item shape: {primaryFeedId?: string, primaryFeedName?: string}
  --feed-label: string # The FeedLabel used to perform filtering. Note: this replaces [region_id](https://developers.google.com/shopping-content/reference/rest/v2.1/products#Product.FIELDS.feed_label). Example value: `US`. Example value: `FeedLabel1`.
  --language-code: string # Language of the title/description and other string attributes. Use language tags defined by [BCP 47](https://www.rfc-editor.org/rfc/bcp/bcp47.txt). ISO 639-1. This specifies the language of offers in Merchant Center that will be accepted. If empty, no language filtering will be performed. Example value: `en`.
  --merchant-center-account-id: string # Required. The linked [Merchant center account id](https://developers.google.com/shopping-content/guides/accountstatuses). The account must be a standalone account or a sub-account of a MCA. (format: int64)
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "parent" $parent "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}") $qp)
  let req_body = {"branchId": $branch_id, "feedFilters": $feed_filters, "feedLabel": $feed_label, "languageCode": $language_code, "merchantCenterAccountId": $merchant_center_account_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.
#
# GET /v2alpha/{name}/operations
# operationId: retail.projects.operations.list
export def "v2alpha-operations list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The standard list filter.
  --page-size: int # The standard list page size.
  --page-token: string # The standard list page token.
]: nothing -> record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pauses the training of an existing model.
#
# POST /v2alpha/{name}:pause
# operationId: retail.projects.locations.catalogs.models.pause
export def "v2alpha pause" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<createTime: string, dataState: string, displayName: string, filteringOption: string, lastTuneTime: string, name: string, optimizationObjective: string, pageOptimizationConfig: record<pageOptimizationEventType: string, panels: list<record>, restriction: string>, periodicTuningState: string, servingConfigLists: table<servingConfigIds: list>, servingState: string, trainingState: string, tuningOperation: string, type: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}:pause") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resumes the training of an existing model.
#
# POST /v2alpha/{name}:resume
# operationId: retail.projects.locations.catalogs.models.resume
export def "v2alpha create-resume" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<createTime: string, dataState: string, displayName: string, filteringOption: string, lastTuneTime: string, name: string, optimizationObjective: string, pageOptimizationConfig: record<pageOptimizationEventType: string, panels: list<record>, restriction: string>, periodicTuningState: string, servingConfigLists: table<servingConfigIds: list>, servingState: string, trainingState: string, tuningOperation: string, type: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}:resume") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates inventory information for a Product while respecting the last update timestamps of each inventory field. This process is asynchronous and does not require the Product to exist before updating fulfillment information. If the request is valid, the update is enqueued and processed downstream. As a consequence, when a response is returned, updates are not immediately manifested in the Product queried by ProductService.GetProduct or ProductService.ListProducts. When inventory is updated with ProductService.CreateProduct and ProductService.UpdateProduct, the specified inventory field value(s) overwrite any existing value(s) while ignoring the last update time for this field. Furthermore, the last update times for the specified inventory fields are overwritten by the times of the ProductService.CreateProduct or ProductService.UpdateProduct request. If no inventory fields are set in CreateProductRequest.product, then any pre-existing inventory information for this product is used. If no inventory fields are set in SetInventoryRequest.set_mask, then any existing inventory information is preserved. Pre-existing inventory information can only be updated with ProductService.SetInventory, ProductService.AddFulfillmentPlaces, and ProductService.RemoveFulfillmentPlaces. The returned Operations is obsolete after one day, and the GetOperation API returns `NOT_FOUND` afterwards. If conflicting updates are issued, the Operations associated with the stale updates are not marked as done until they are obsolete.
#
# POST /v2alpha/{name}:setInventory
# operationId: retail.projects.locations.catalogs.branches.products.setInventory
# --inventory shape: {attributes?: record, audience?: record, availability?: "AVAILABILITY_UNSPECIFIED"|"IN_STOCK"|"OUT_OF_STOCK"|"PREORDER"|"BACKORDER", availableQuantity?: int, availableTime?: string, brands?: list<string>, categories?: list<string>, collectionMemberIds?: list<string>, colorInfo?: record, conditions?: list<string>, description?: string, expireTime?: string, fulfillmentInfo?: list, gtin?: string, id?: string, images?: list, languageCode?: string, materials?: list<string>, name?: string, ... (13 more fields)}
export def "v2alpha update-inventory" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-missing: oneof<nothing, bool> # If set to true, and the Product with name Product.name is not found, the inventory update will still be processed and retained for at most 1 day until the Product is created. If set to false, a NOT_FOUND error is returned if the Product is not found.
  --inventory: record # Product captures all metadata information of items to be recommended or searched. — shape: {attributes?: record, audience?: record, availability?: "AVAILABILITY_UNSPECIFIED"|"IN_STOCK"|"OUT_OF_STOCK"|"PREORDER"|"BACKORDER", availableQuantity?: int, availableTime?: string, brands?: list<string>, categories?: list<string>, collectionMemberIds?: list<string>, colorInfo?: record, conditions?: list<string>, description?: string, expireTime?: string, fulfillmentInfo?: list, gtin?: string, id?: string, images?: list, languageCode?: string, materials?: list<string>, name?: string, ... (13 more fields)}
  --set-mask: string # Indicates which inventory fields in the provided Product to update. At least one field must be provided. If an unsupported or unknown field is provided, an INVALID_ARGUMENT error is returned and the entire update will be ignored. (format: google-fieldmask)
  --set-time: string # The time when the request is issued, used to prevent out-of-order updates on inventory fields with the last update time recorded. If not provided, the internal system time will be used. (format: google-datetime)
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}:setInventory") $qp)
  let req_body = {"allowMissing": $allow_missing, "inventory": $inventory, "setMask": $set_mask, "setTime": $set_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Tunes an existing model.
#
# POST /v2alpha/{name}:tune
# operationId: retail.projects.locations.catalogs.models.tune
export def "v2alpha create-tune" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v2alpha/{name}:tune") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all the Catalogs associated with the project.
#
# GET /v2alpha/{parent}/catalogs
# operationId: retail.projects.locations.catalogs.list
export def "v2alpha-catalogs list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of Catalogs to return. If unspecified, defaults to 50. The maximum allowed value is 1000. Values above 1000 will be coerced to 1000. If this field is negative, an INVALID_ARGUMENT is returned.
  --page-token: string # A page token ListCatalogsResponse.next_page_token, received from a previous CatalogService.ListCatalogs call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to CatalogService.ListCatalogs must match the call that provided the page token. Otherwise, an INVALID_ARGUMENT error is returned.
]: nothing -> record<catalogs: table<displayName: string, merchantCenterLinkingConfig: record, name: string, productLevelConfig: record>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/catalogs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk import of processed completion dataset. Request processing is asynchronous. Partial updating is not supported. The operation is successfully finished only after the imported suggestions are indexed successfully and ready for serving. The process takes hours. This feature is only available for users who have Retail Search enabled. Enable Retail Search on Cloud Console before using this feature.
#
# POST /v2alpha/{parent}/completionData:import
# operationId: retail.projects.locations.catalogs.completionData.import
# --inputConfig shape: {bigQuerySource?: record}
export def "v2alpha-completion-data-import import" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --input-config: record # The input config source for completion data. — shape: {bigQuerySource?: record}
  --notification-pubsub-topic: string # Pub/Sub topic for receiving notification. If this field is set, when the import is finished, a notification is sent to specified Pub/Sub topic. The message data is JSON string of a Operation. Format of the Pub/Sub topic is `projects/{project}/topics/{topic}`.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/completionData:import") $qp)
  let req_body = {"inputConfig": $input_config, "notificationPubsubTopic": $notification_pubsub_topic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all Controls by their parent Catalog.
#
# GET /v2alpha/{parent}/controls
# operationId: retail.projects.locations.catalogs.controls.list
export def "v2alpha-controls list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. A filter to apply on the list results. Supported features: * List all the products under the parent branch if filter is unset. * List controls that are used in a single ServingConfig: 'serving_config = "boosted_home_page_cvr"'
  --page-size: int # Optional. Maximum number of results to return. If unspecified, defaults to 50. Max allowed value is 1000.
  --page-token: string # Optional. A page token, received from a previous `ListControls` call. Provide this to retrieve the subsequent page.
]: nothing -> record<controls: table<associatedServingConfigIds: list, displayName: string, facetSpec: record, name: string, rule: record, searchSolutionUseCase: list, solutionTypes: list>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/controls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Control. If the Control to create already exists, an ALREADY_EXISTS error is returned.
#
# POST /v2alpha/{parent}/controls
# operationId: retail.projects.locations.catalogs.controls.create
# --facetSpec shape: {enableDynamicPosition?: bool, excludedFilterKeys?: list<string>, facetKey?: record, limit?: int}
# --rule shape: {boostAction?: record, condition?: record, doNotAssociateAction?: record, filterAction?: record, ignoreAction?: record, onewaySynonymsAction?: record, redirectAction?: record, replacementAction?: record, twowaySynonymsAction?: record}
export def "v2alpha-controls create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --control-id: string # Required. The ID to use for the Control, which will become the final component of the Control's resource name. This value should be 4-63 characters, and valid characters are /a-z-_/.
  --display-name: string # Required. The human readable control display name. Used in Retail UI. This field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is thrown.
  --facet-spec: record # A facet specification to perform faceted search. — shape: {enableDynamicPosition?: bool, excludedFilterKeys?: list<string>, facetKey?: record, limit?: int}
  --name: string # Immutable. Fully qualified name `projects/*/locations/global/catalogs/*/controls/*`
  --rule: record # A rule is a condition-action pair * A condition defines when a rule is to be triggered. * An action specifies what occurs on that trigger. Currently rules only work for controls with SOLUTION_TYPE_SEARCH. — shape: {boostAction?: record, condition?: record, doNotAssociateAction?: record, filterAction?: record, ignoreAction?: record, onewaySynonymsAction?: record, redirectAction?: record, replacementAction?: record, twowaySynonymsAction?: record}
  --search-solution-use-case: list<string> # Specifies the use case for the control. Affects what condition fields can be set. Only settable by search controls. Will default to SEARCH_SOLUTION_USE_CASE_SEARCH if not specified. Currently only allow one search_solution_use_case per control.
  --solution-types: list<string> # Required. Immutable. The solution types that the control is used for. Currently we support setting only one type of solution at creation time. Only `SOLUTION_TYPE_SEARCH` value is supported at the moment. If no solution type is provided at creation time, will default to SOLUTION_TYPE_SEARCH.
]: any -> record<associatedServingConfigIds: list<string>, displayName: string, facetSpec: record<enableDynamicPosition: bool, excludedFilterKeys: list<string>, facetKey: record<caseInsensitive: bool, contains: list, intervals: list, key: string, orderBy: string, prefixes: list, query: string, restrictedValues: list, returnMinMax: bool>, limit: int>, name: string, rule: record<boostAction: record<boost: float, productsFilter: string>, condition: record<activeTimeRange: list, queryTerms: list>, doNotAssociateAction: record<doNotAssociateTerms: list, queryTerms: list, terms: list>, filterAction: record<filter: string>, ignoreAction: record<ignoreTerms: list>, onewaySynonymsAction: record<onewayTerms: list, queryTerms: list, synonyms: list>, redirectAction: record<redirectUri: string>, replacementAction: record<queryTerms: list, replacementTerm: string, term: string>, twowaySynonymsAction: record<synonyms: list>>, searchSolutionUseCase: list<string>, solutionTypes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "controlId" $control_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/controls") $qp)
  let req_body = {"displayName": $display_name, "facetSpec": $facet_spec, "name": $name, "rule": $rule, "searchSolutionUseCase": $search_solution_use_case, "solutionTypes": $solution_types} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all MerchantCenterAccountLinks under the specified parent Catalog.
#
# GET /v2alpha/{parent}/merchantCenterAccountLinks
# operationId: retail.projects.locations.catalogs.merchantCenterAccountLinks.list
export def "v2alpha-merchant-center-account-links list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<merchantCenterAccountLinks: table<branchId: string, feedFilters: list, feedLabel: string, id: string, languageCode: string, merchantCenterAccountId: string, name: string, projectId: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/merchantCenterAccountLinks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the models linked to this event store.
#
# GET /v2alpha/{parent}/models
# operationId: retail.projects.locations.catalogs.models.list
export def "v2alpha-models list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Optional. Maximum number of results to return. If unspecified, defaults to 50. Max allowed value is 1000.
  --page-token: string # Optional. A page token, received from a previous `ListModels` call. Provide this to retrieve the subsequent page.
]: nothing -> record<models: table<createTime: string, dataState: string, displayName: string, filteringOption: string, lastTuneTime: string, name: string, optimizationObjective: string, pageOptimizationConfig: record, periodicTuningState: string, servingConfigLists: list, servingState: string, trainingState: string, tuningOperation: string, type: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/models") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new model.
#
# POST /v2alpha/{parent}/models
# operationId: retail.projects.locations.catalogs.models.create
# --pageOptimizationConfig shape: {pageOptimizationEventType?: string, panels?: list, restriction?: "RESTRICTION_UNSPECIFIED"|"NO_RESTRICTION"|"UNIQUE_SERVING_CONFIG_RESTRICTION"|"UNIQUE_MODEL_RESTRICTION"|"UNIQUE_MODEL_TYPE_RESTRICTION"}
# --servingConfigLists item shape: {servingConfigIds?: list<string>}
export def "v2alpha-models create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --qp-dry-run: oneof<nothing, bool> # Optional. Whether to run a dry run to validate the request (without actually creating the model).
  --display-name: string # Required. The display name of the model. Should be human readable, used to display Recommendation Models in the Retail Cloud Console Dashboard. UTF-8 encoded string with limit of 1024 characters.
  --filtering-option: string@filtering-option-completer # Optional. If `RECOMMENDATIONS_FILTERING_ENABLED`, recommendation filtering by attributes is enabled for the model.
  --name: string # Required. The fully qualified resource name of the model. Format: `projects/{project_number}/locations/{location_id}/catalogs/{catalog_id}/models/{model_id}` catalog_id has char limit of 50. recommendation_model_id has char limit of 40.
  --optimization-objective: string # Optional. The optimization objective e.g. `cvr`. Currently supported values: `ctr`, `cvr`, `revenue-per-order`. If not specified, we choose default based on model type. Default depends on type of recommendation: `recommended-for-you` => `ctr` `others-you-may-like` => `ctr` `frequently-bought-together` => `revenue_per_order` This field together with optimization_objective describe model metadata to use to control model training and serving. See https://cloud.google.com/retail/docs/models for more details on what the model metadata control and which combination of parameters are valid. For invalid combinations of parameters (e.g. type = `frequently-bought-together` and optimization_objective = `ctr`), you receive an error 400 if you try to create/update a recommendation with this set of knobs.
  --page-optimization-config: record # The PageOptimizationConfig for model training. This determines how many panels to optimize for, and which serving configs to consider for each panel. The purpose of this model is to optimize which ServingConfig to show on which panels in way that optimizes the visitors shopping journey. — shape: {pageOptimizationEventType?: string, panels?: list, restriction?: "RESTRICTION_UNSPECIFIED"|"NO_RESTRICTION"|"UNIQUE_SERVING_CONFIG_RESTRICTION"|"UNIQUE_MODEL_RESTRICTION"|"UNIQUE_MODEL_TYPE_RESTRICTION"}
  --periodic-tuning-state: string@periodic-tuning-state-completer # Optional. The state of periodic tuning. The period we use is 3 months - to do a one-off tune earlier use the `TuneModel` method. Default value is `PERIODIC_TUNING_ENABLED`.
  --training-state: string@training-state-completer # Optional. The training state that the model is in (e.g. `TRAINING` or `PAUSED`). Since part of the cost of running the service is frequency of training - this can be used to determine when to train model in order to control cost. If not specified: the default value for `CreateModel` method is `TRAINING`. The default value for `UpdateModel` method is to keep the state the same as before.
  --type: string # Required. The type of model e.g. `home-page`. Currently supported values: `recommended-for-you`, `others-you-may-like`, `frequently-bought-together`, `page-optimization`, `similar-items`, `buy-it-again`, `on-sale-items`, and `recently-viewed`(readonly value). This field together with optimization_objective describe model metadata to use to control model training and serving. See https://cloud.google.com/retail/docs/models for more details on what the model metadata control and which combination of parameters are valid. For invalid combinations of parameters (e.g. type = `frequently-bought-together` and optimization_objective = `ctr`), you receive an error 400 if you try to create/update a recommendation with this set of knobs.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "dryRun" $qp_dry_run "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/models") $qp)
  let req_body = {"displayName": $display_name, "filteringOption": $filtering_option, "name": $name, "optimizationObjective": $optimization_objective, "pageOptimizationConfig": $page_optimization_config, "periodicTuningState": $periodic_tuning_state, "trainingState": $training_state, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets a list of Products.
#
# GET /v2alpha/{parent}/products
# operationId: retail.projects.locations.catalogs.branches.products.list
export def "v2alpha-products list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A filter to apply on the list results. Supported features: * List all the products under the parent branch if filter is unset. * List Product.Type.VARIANT Products sharing the same Product.Type.PRIMARY Product. For example: `primary_product_id = "some_product_id"` * List Products bundled in a Product.Type.COLLECTION Product. For example: `collection_product_id = "some_product_id"` * List Products with a partibular type. For example: `type = "PRIMARY"` `type = "VARIANT"` `type = "COLLECTION"` If the field is unrecognizable, an INVALID_ARGUMENT error is returned. If the specified Product.Type.PRIMARY Product or Product.Type.COLLECTION Product does not exist, a NOT_FOUND error is returned.
  --page-size: int # Maximum number of Products to return. If unspecified, defaults to 100. The maximum allowed value is 1000. Values above 1000 will be coerced to 1000. If this field is negative, an INVALID_ARGUMENT error is returned.
  --page-token: string # A page token ListProductsResponse.next_page_token, received from a previous ProductService.ListProducts call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to ProductService.ListProducts must match the call that provided the page token. Otherwise, an INVALID_ARGUMENT error is returned.
  --read-mask: string # The fields of Product to return in the responses. If not set or empty, the following fields are returned: * Product.name * Product.id * Product.title * Product.uri * Product.images * Product.price_info * Product.brands If "*" is provided, all fields are returned. Product.name is always returned no matter what mask is set. If an unsupported or unknown field is provided, an INVALID_ARGUMENT error is returned.
  --require-total-size: oneof<nothing, bool> # If true and page_token is empty, ListProductsResponse.total_size is set to the total count of matched items irrespective of pagination. Notice that setting this field to true affects the performance.
]: nothing -> record<nextPageToken: string, products: table<attributes: record, audience: record, availability: string, availableQuantity: int, availableTime: string, brands: list, categories: list, collectionMemberIds: list, colorInfo: record, conditions: list, description: string, expireTime: string, fulfillmentInfo: list, gtin: string, id: string, images: list, languageCode: string, localInventories: list, materials: list, name: string, patterns: list, priceInfo: record, primaryProductId: string, promotions: list, publishTime: string, rating: record, retrievableFields: string, sizes: list, tags: list, title: string, ttl: string, type: string, uri: string, variants: list>, totalSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "readMask" $read_mask "scalar") (serialize-qp "requireTotalSize" $require_total_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Product.
#
# POST /v2alpha/{parent}/products
# operationId: retail.projects.locations.catalogs.branches.products.create
# --audience shape: {ageGroups?: list<string>, genders?: list<string>}
# --colorInfo shape: {colorFamilies?: list<string>, colors?: list<string>}
# --fulfillmentInfo item shape: {placeIds?: list<string>, type?: string}
# --images item shape: {height?: int, uri?: string, width?: int}
# --localInventories item shape: {attributes?: record, fulfillmentTypes?: list<string>, placeId?: string, priceInfo?: record}
# --priceInfo shape: {cost?: float, currencyCode?: string, originalPrice?: float, price?: float, priceEffectiveTime?: string, priceExpireTime?: string, priceRange?: record}
# --promotions item shape: {promotionId?: string}
# --rating shape: {averageRating?: float, ratingCount?: int, ratingHistogram?: list<int>}
# --variants item shape: {attributes?: record, audience?: record, availability?: "AVAILABILITY_UNSPECIFIED"|"IN_STOCK"|"OUT_OF_STOCK"|"PREORDER"|"BACKORDER", availableQuantity?: int, availableTime?: string, brands?: list<string>, categories?: list<string>, collectionMemberIds?: list<string>, colorInfo?: record, conditions?: list<string>, description?: string, expireTime?: string, fulfillmentInfo?: list, gtin?: string, id?: string, images?: list, languageCode?: string, materials?: list<string>, name?: string, ... (13 more fields)}
export def "v2alpha-products create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --product-id: string # Required. The ID to use for the Product, which will become the final component of the Product.name. If the caller does not have permission to create the Product, regardless of whether or not it exists, a PERMISSION_DENIED error is returned. This field must be unique among all Products with the same parent. Otherwise, an ALREADY_EXISTS error is returned. This field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned.
  --attributes: record # Highly encouraged. Extra product attributes to be included. For example, for products, this could include the store name, vendor, style, color, etc. These are very strong signals for recommendation model, thus we highly recommend providing the attributes here. Features that can take on one of a limited number of possible values. Two types of features can be set are: Textual features. some examples would be the brand/maker of a product, or country of a customer. Numerical features. Some examples would be the height/weight of a product, or age of a customer. For example: `{ "vendor": {"text": ["vendor123", "vendor456"]}, "lengths_cm": {"numbers":[2.3, 15.4]}, "heights_cm": {"numbers":[8.1, 6.4]} }`. This field needs to pass all below criteria, otherwise an INVALID_ARGUMENT error is returned: * Max entries count: 200. * The key must be a UTF-8 encoded string with a length limit of 128 characters. * For indexable attribute, the key must match the pattern: `a-zA-Z0-9*`. For example, `key0LikeThis` or `KEY_1_LIKE_THIS`. * For text attributes, at most 400 values are allowed. Empty values are not allowed. Each value must be a non-empty UTF-8 encoded string with a length limit of 256 characters. * For number attributes, at most 400 values are allowed.
  --audience: record # An intended audience of the Product for whom it's sold. — shape: {ageGroups?: list<string>, genders?: list<string>}
  --availability: string@availability-completer # The online availability of the Product. Default to Availability.IN_STOCK. Corresponding properties: Google Merchant Center property [availability](https://support.google.com/merchants/answer/6324448). Schema.org property [Offer.availability](https://schema.org/availability).
  --available-quantity: int # The available quantity of the item. (format: int32)
  --available-time: string # The timestamp when this Product becomes available for SearchService.Search. Note that this is only applicable to Type.PRIMARY and Type.COLLECTION, and ignored for Type.VARIANT. (format: google-datetime)
  --brands: list<string> # The brands of the product. A maximum of 30 brands are allowed. Each brand must be a UTF-8 encoded string with a length limit of 1,000 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [brand](https://support.google.com/merchants/answer/6324351). Schema.org property [Product.brand](https://schema.org/brand).
  --categories: list<string> # Product categories. This field is repeated for supporting one product belonging to several parallel categories. Strongly recommended using the full path for better search / recommendation quality. To represent full path of category, use '>' sign to separate different hierarchies. If '>' is part of the category name, replace it with other character(s). For example, if a shoes product belongs to both ["Shoes & Accessories" -> "Shoes"] and ["Sports & Fitness" -> "Athletic Clothing" -> "Shoes"], it could be represented as: "categories": [ "Shoes & Accessories > Shoes", "Sports & Fitness > Athletic Clothing > Shoes" ] Must be set for Type.PRIMARY Product otherwise an INVALID_ARGUMENT error is returned. At most 250 values are allowed per Product. Empty values are not allowed. Each value must be a UTF-8 encoded string with a length limit of 5,000 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property google_product_category. Schema.org property [Product.category] (https://schema.org/category). [mc_google_product_category]: https://support.google.com/merchants/answer/6324436
  --collection-member-ids: list<string> # The id of the collection members when type is Type.COLLECTION. Non-existent product ids are allowed. The type of the members must be either Type.PRIMARY or Type.VARIANT otherwise an INVALID_ARGUMENT error is thrown. Should not set it for other types. A maximum of 1000 values are allowed. Otherwise, an INVALID_ARGUMENT error is return.
  --color-info: record # The color information of a Product. — shape: {colorFamilies?: list<string>, colors?: list<string>}
  --conditions: list<string> # The condition of the product. Strongly encouraged to use the standard values: "new", "refurbished", "used". A maximum of 1 value is allowed per Product. Each value must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [condition](https://support.google.com/merchants/answer/6324469). Schema.org property [Offer.itemCondition](https://schema.org/itemCondition).
  --description: string # Product description. This field must be a UTF-8 encoded string with a length limit of 5,000 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [description](https://support.google.com/merchants/answer/6324468). Schema.org property [Product.description](https://schema.org/description).
  --expire-time: string # The timestamp when this product becomes unavailable for SearchService.Search. Note that this is only applicable to Type.PRIMARY and Type.COLLECTION, and ignored for Type.VARIANT. In general, we suggest the users to delete the stale products explicitly, instead of using this field to determine staleness. If it is set, the Product is not available for SearchService.Search after expire_time. However, the product can still be retrieved by ProductService.GetProduct and ProductService.ListProducts. expire_time must be later than available_time and publish_time, otherwise an INVALID_ARGUMENT error is thrown. Corresponding properties: Google Merchant Center property [expiration_date](https://support.google.com/merchants/answer/6324499). (format: google-datetime)
  --fulfillment-info: list # Fulfillment information, such as the store IDs for in-store pickup or region IDs for different shipping methods. All the elements must have distinct FulfillmentInfo.type. Otherwise, an INVALID_ARGUMENT error is returned. — item shape: {placeIds?: list<string>, type?: string}
  --gtin: string # The Global Trade Item Number (GTIN) of the product. This field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned. This field must be a Unigram. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [gtin](https://support.google.com/merchants/answer/6324461). Schema.org property [Product.isbn](https://schema.org/isbn), [Product.gtin8](https://schema.org/gtin8), [Product.gtin12](https://schema.org/gtin12), [Product.gtin13](https://schema.org/gtin13), or [Product.gtin14](https://schema.org/gtin14). If the value is not a valid GTIN, an INVALID_ARGUMENT error is returned.
  --id: string # Immutable. Product identifier, which is the final component of name. For example, this field is "id_1", if name is `projects/*/locations/global/catalogs/default_catalog/branches/default_branch/products/id_1`. This field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [id](https://support.google.com/merchants/answer/6324405). Schema.org property [Product.sku](https://schema.org/sku).
  --images: list # Product images for the product. We highly recommend putting the main image first. A maximum of 300 images are allowed. Corresponding properties: Google Merchant Center property [image_link](https://support.google.com/merchants/answer/6324350). Schema.org property [Product.image](https://schema.org/image). — item shape: {height?: int, uri?: string, width?: int}
  --language-code: string # Language of the title/description and other string attributes. Use language tags defined by [BCP 47](https://www.rfc-editor.org/rfc/bcp/bcp47.txt). For product prediction, this field is ignored and the model automatically detects the text language. The Product can include text in different languages, but duplicating Products to provide text in multiple languages can result in degraded model performance. For product search this field is in use. It defaults to "en-US" if unset.
  --materials: list<string> # The material of the product. For example, "leather", "wooden". A maximum of 20 values are allowed. Each value must be a UTF-8 encoded string with a length limit of 200 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [material](https://support.google.com/merchants/answer/6324410). Schema.org property [Product.material](https://schema.org/material).
  --name: string # Immutable. Full resource name of the product, such as `projects/*/locations/global/catalogs/default_catalog/branches/default_branch/products/product_id`.
  --patterns: list<string> # The pattern or graphic print of the product. For example, "striped", "polka dot", "paisley". A maximum of 20 values are allowed per Product. Each value must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [pattern](https://support.google.com/merchants/answer/6324483). Schema.org property [Product.pattern](https://schema.org/pattern).
  --price-info: record # The price information of a Product. — shape: {cost?: float, currencyCode?: string, originalPrice?: float, price?: float, priceEffectiveTime?: string, priceExpireTime?: string, priceRange?: record}
  --primary-product-id: string # Variant group identifier. Must be an id, with the same parent branch with this product. Otherwise, an error is thrown. For Type.PRIMARY Products, this field can only be empty or set to the same value as id. For VARIANT Products, this field cannot be empty. A maximum of 2,000 products are allowed to share the same Type.PRIMARY Product. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [item_group_id](https://support.google.com/merchants/answer/6324507). Schema.org property [Product.inProductGroupWithID](https://schema.org/inProductGroupWithID).
  --promotions: list # The promotions applied to the product. A maximum of 10 values are allowed per Product. Only Promotion.promotion_id will be used, other fields will be ignored if set. — item shape: {promotionId?: string}
  --publish-time: string # The timestamp when the product is published by the retailer for the first time, which indicates the freshness of the products. Note that this field is different from available_time, given it purely describes product freshness regardless of when it is available on search and recommendation. (format: google-datetime)
  --rating: record # The rating of a Product. — shape: {averageRating?: float, ratingCount?: int, ratingHistogram?: list<int>}
  --retrievable-fields: string # Indicates which fields in the Products are returned in SearchResponse. Supported fields for all types: * audience * availability * brands * color_info * conditions * gtin * materials * name * patterns * price_info * rating * sizes * title * uri Supported fields only for Type.PRIMARY and Type.COLLECTION: * categories * description * images Supported fields only for Type.VARIANT: * Only the first image in images To mark attributes as retrievable, include paths of the form "attributes.key" where "key" is the key of a custom attribute, as specified in attributes. For Type.PRIMARY and Type.COLLECTION, the following fields are always returned in SearchResponse by default: * name For Type.VARIANT, the following fields are always returned in by default: * name * color_info The maximum number of paths is 30. Otherwise, an INVALID_ARGUMENT error is returned. Note: Returning more fields in SearchResponse can increase response payload size and serving latency. This field is deprecated. Use the retrievable site-wide control instead. (format: google-fieldmask)
  --sizes: list<string> # The size of the product. To represent different size systems or size types, consider using this format: [[[size_system:]size_type:]size_value]. For example, in "US:MENS:M", "US" represents size system; "MENS" represents size type; "M" represents size value. In "GIRLS:27", size system is empty; "GIRLS" represents size type; "27" represents size value. In "32 inches", both size system and size type are empty, while size value is "32 inches". A maximum of 20 values are allowed per Product. Each value must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [size](https://support.google.com/merchants/answer/6324492), [size_type](https://support.google.com/merchants/answer/6324497), and [size_system](https://support.google.com/merchants/answer/6324502). Schema.org property [Product.size](https://schema.org/size).
  --tags: list<string> # Custom tags associated with the product. At most 250 values are allowed per Product. This value must be a UTF-8 encoded string with a length limit of 1,000 characters. Otherwise, an INVALID_ARGUMENT error is returned. This tag can be used for filtering recommendation results by passing the tag as part of the PredictRequest.filter. Corresponding properties: Google Merchant Center property [custom_label_0–4](https://support.google.com/merchants/answer/6324473).
  --title: string # Required. Product title. This field must be a UTF-8 encoded string with a length limit of 1,000 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [title](https://support.google.com/merchants/answer/6324415). Schema.org property [Product.name](https://schema.org/name).
  --ttl: string # Input only. The TTL (time to live) of the product. Note that this is only applicable to Type.PRIMARY and Type.COLLECTION, and ignored for Type.VARIANT. In general, we suggest the users to delete the stale products explicitly, instead of using this field to determine staleness. If it is set, it must be a non-negative value, and expire_time is set as current timestamp plus ttl. The derived expire_time is returned in the output and ttl is left blank when retrieving the Product. If it is set, the product is not available for SearchService.Search after current timestamp plus ttl. However, the product can still be retrieved by ProductService.GetProduct and ProductService.ListProducts. (format: google-duration)
  --type: string@type-completer # Immutable. The type of the product. Default to Catalog.product_level_config.ingestion_product_type if unset.
  --uri: string # Canonical URL directly linking to the product detail page. It is strongly recommended to provide a valid uri for the product, otherwise the service performance could be significantly degraded. This field must be a UTF-8 encoded string with a length limit of 5,000 characters. Otherwise, an INVALID_ARGUMENT error is returned. Corresponding properties: Google Merchant Center property [link](https://support.google.com/merchants/answer/6324416). Schema.org property [Offer.url](https://schema.org/url).
]: any -> record<attributes: record, audience: record<ageGroups: list<string>, genders: list<string>>, availability: string, availableQuantity: int, availableTime: string, brands: list<string>, categories: list<string>, collectionMemberIds: list<string>, colorInfo: record<colorFamilies: list<string>, colors: list<string>>, conditions: list<string>, description: string, expireTime: string, fulfillmentInfo: table<placeIds: list, type: string>, gtin: string, id: string, images: table<height: int, uri: string, width: int>, languageCode: string, localInventories: table<attributes: record, fulfillmentTypes: list, placeId: string, priceInfo: record>, materials: list<string>, name: string, patterns: list<string>, priceInfo: record<cost: float, currencyCode: string, originalPrice: float, price: float, priceEffectiveTime: string, priceExpireTime: string, priceRange: record<originalPrice: record, price: record>>, primaryProductId: string, promotions: table<promotionId: string>, publishTime: string, rating: record<averageRating: float, ratingCount: int, ratingHistogram: list<int>>, retrievableFields: string, sizes: list<string>, tags: list<string>, title: string, ttl: string, type: string, uri: string, variants: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "productId" $product_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/products") $qp)
  let req_body = {"attributes": $attributes, "audience": $audience, "availability": $availability, "availableQuantity": $available_quantity, "availableTime": $available_time, "brands": $brands, "categories": $categories, "collectionMemberIds": $collection_member_ids, "colorInfo": $color_info, "conditions": $conditions, "description": $description, "expireTime": $expire_time, "fulfillmentInfo": $fulfillment_info, "gtin": $gtin, "id": $id, "images": $images, "languageCode": $language_code, "materials": $materials, "name": $name, "patterns": $patterns, "priceInfo": $price_info, "primaryProductId": $primary_product_id, "promotions": $promotions, "publishTime": $publish_time, "rating": $rating, "retrievableFields": $retrievable_fields, "sizes": $sizes, "tags": $tags, "title": $title, "ttl": $ttl, "type": $type, "uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Bulk import of multiple Products. Request processing may be synchronous. Non-existing items are created. Note that it is possible for a subset of the Products to be successfully updated.
#
# POST /v2alpha/{parent}/products:import
# operationId: retail.projects.locations.catalogs.branches.products.import
# --errorsConfig shape: {gcsPrefix?: string}
# --inputConfig shape: {bigQuerySource?: record, gcsSource?: record, productInlineSource?: record}
export def "v2alpha-products-import import" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --errors-config: record # Configuration of destination for Import related errors. — shape: {gcsPrefix?: string}
  --input-config: record # The input config source for products. — shape: {bigQuerySource?: record, gcsSource?: record, productInlineSource?: record}
  --notification-pubsub-topic: string # Full Pub/Sub topic name for receiving notification. If this field is set, when the import is finished, a notification is sent to specified Pub/Sub topic. The message data is JSON string of a Operation. Format of the Pub/Sub topic is `projects/{project}/topics/{topic}`. It has to be within the same project as ImportProductsRequest.parent. Make sure that `service-@gcp-sa-retail.iam.gserviceaccount.com` has the `pubsub.topics.publish` IAM permission on the topic.
  --reconciliation-mode: string@reconciliation-mode-completer # The mode of reconciliation between existing products and the products to be imported. Defaults to ReconciliationMode.INCREMENTAL.
  --request-id: string # Deprecated. This field has no effect.
  --skip-default-branch-protection: oneof<nothing, bool> # If true, this performs the FULL import even if it would delete a large proportion of the products in the default branch, which could potentially cause outages if you have live predict/search traffic. Only supported when ImportProductsRequest.reconciliation_mode is set to `FULL`.
  --update-mask: string # Indicates which fields in the provided imported `products` to update. If not set, all fields are updated. (format: google-fieldmask)
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/products:import") $qp)
  let req_body = {"errorsConfig": $errors_config, "inputConfig": $input_config, "notificationPubsubTopic": $notification_pubsub_topic, "reconciliationMode": $reconciliation_mode, "requestId": $request_id, "skipDefaultBranchProtection": $skip_default_branch_protection, "updateMask": $update_mask} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Permanently deletes all selected Products under a branch. This process is asynchronous. If the request is valid, the removal will be enqueued and processed offline. Depending on the number of Products, this operation could take hours to complete. Before the operation completes, some Products may still be returned by ProductService.GetProduct or ProductService.ListProducts. Depending on the number of Products, this operation could take hours to complete. To get a sample of Products that would be deleted, set PurgeProductsRequest.force to false.
#
# POST /v2alpha/{parent}/products:purge
# operationId: retail.projects.locations.catalogs.branches.products.purge
export def "v2alpha-products-purge create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Required. The filter string to specify the products to be deleted with a length limit of 5,000 characters. Empty string filter is not allowed. "*" implies delete all items in a branch. The eligible fields for filtering are: * `availability`: Double quoted Product.availability string. * `create_time` : in ISO 8601 "zulu" format. Supported syntax: * Comparators (">", "<", ">=", "<=", "="). Examples: * create_time <= "2015-02-13T17:05:46Z" * availability = "IN_STOCK" * Conjunctions ("AND") Examples: * create_time <= "2015-02-13T17:05:46Z" AND availability = "PREORDER" * Disjunctions ("OR") Examples: * create_time <= "2015-02-13T17:05:46Z" OR availability = "IN_STOCK" * Can support nested queries. Examples: * (create_time <= "2015-02-13T17:05:46Z" AND availability = "PREORDER") OR (create_time >= "2015-02-14T13:03:32Z" AND availability = "IN_STOCK") * Filter Limits: * Filter should not contain more than 6 conditions. * Max nesting depth should not exceed 2 levels. Examples queries: * Delete back order products created before a timestamp. create_time <= "2015-02-13T17:05:46Z" OR availability = "BACKORDER"
  --force: oneof<nothing, bool> # Actually perform the purge. If `force` is set to false, the method will return the expected purge count without deleting any products.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/products:purge") $qp)
  let req_body = {"filter": $filter, "force": $force} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists all ServingConfigs linked to this catalog.
#
# GET /v2alpha/{parent}/servingConfigs
# operationId: retail.projects.locations.catalogs.servingConfigs.list
export def "v2alpha-serving-configs list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Optional. Maximum number of results to return. If unspecified, defaults to 100. If a value greater than 100 is provided, at most 100 results are returned.
  --page-token: string # Optional. A page token, received from a previous `ListServingConfigs` call. Provide this to retrieve the subsequent page.
]: nothing -> record<nextPageToken: string, servingConfigs: table<boostControlIds: list, displayName: string, diversityLevel: string, diversityType: string, doNotAssociateControlIds: list, dynamicFacetSpec: record, enableCategoryFilterLevel: string, facetControlIds: list, filterControlIds: list, ignoreControlIds: list, modelId: string, name: string, onewaySynonymsControlIds: list, personalizationSpec: record, priceRerankingLevel: string, redirectControlIds: list, replacementControlIds: list, solutionTypes: list, twowaySynonymsControlIds: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/servingConfigs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a ServingConfig. A maximum of 100 ServingConfigs are allowed in a Catalog, otherwise a FAILED_PRECONDITION error is returned.
#
# POST /v2alpha/{parent}/servingConfigs
# operationId: retail.projects.locations.catalogs.servingConfigs.create
# --dynamicFacetSpec shape: {mode?: "MODE_UNSPECIFIED"|"DISABLED"|"ENABLED"}
# --personalizationSpec shape: {mode?: "MODE_UNSPECIFIED"|"AUTO"|"DISABLED"}
export def "v2alpha-serving-configs create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --serving-config-id: string # Required. The ID to use for the ServingConfig, which will become the final component of the ServingConfig's resource name. This value should be 4-63 characters, and valid characters are /a-z-_/.
  --boost-control-ids: list<string> # Condition boost specifications. If a product matches multiple conditions in the specifications, boost scores from these specifications are all applied and combined in a non-linear way. Maximum number of specifications is 100. Notice that if both ServingConfig.boost_control_ids and SearchRequest.boost_spec are set, the boost conditions from both places are evaluated. If a search request matches multiple boost conditions, the final boost score is equal to the sum of the boost scores from all matched boost conditions. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --display-name: string # Required. The human readable serving config display name. Used in Retail UI. This field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned.
  --diversity-level: string # How much diversity to use in recommendation model results e.g. `medium-diversity` or `high-diversity`. Currently supported values: * `no-diversity` * `low-diversity` * `medium-diversity` * `high-diversity` * `auto-diversity` If not specified, we choose default based on recommendation model type. Default value: `no-diversity`. Can only be set if solution_types is SOLUTION_TYPE_RECOMMENDATION.
  --diversity-type: string@diversity-type-completer # What kind of diversity to use - data driven or rule based. If unset, the server behavior defaults to RULE_BASED_DIVERSITY.
  --do-not-associate-control-ids: list<string> # Condition do not associate specifications. If multiple do not associate conditions match, all matching do not associate controls in the list will execute. - Order does not matter. - Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --dynamic-facet-spec: record # The specifications of dynamically generated facets. — shape: {mode?: "MODE_UNSPECIFIED"|"DISABLED"|"ENABLED"}
  --enable-category-filter-level: string # Whether to add additional category filters on the `similar-items` model. If not specified, we enable it by default. Allowed values are: * `no-category-match`: No additional filtering of original results from the model and the customer's filters. * `relaxed-category-match`: Only keep results with categories that match at least one item categories in the PredictRequests's context item. * If customer also sends filters in the PredictRequest, then the results will satisfy both conditions (user given and category match). Can only be set if solution_types is SOLUTION_TYPE_RECOMMENDATION.
  --facet-control-ids: list<string> # Facet specifications for faceted search. If empty, no facets are returned. The ids refer to the ids of Control resources with only the Facet control set. These controls are assumed to be in the same Catalog as the ServingConfig. A maximum of 100 values are allowed. Otherwise, an INVALID_ARGUMENT error is returned. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --filter-control-ids: list<string> # Condition filter specifications. If a product matches multiple conditions in the specifications, filters from these specifications are all applied and combined via the AND operator. Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --ignore-control-ids: list<string> # Condition ignore specifications. If multiple ignore conditions match, all matching ignore controls in the list will execute. - Order does not matter. - Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --model-id: string # The id of the model in the same Catalog to use at serving time. Currently only RecommendationModels are supported: https://cloud.google.com/retail/recommendations-ai/docs/create-models Can be changed but only to a compatible model (e.g. others-you-may-like CTR to others-you-may-like CVR). Required when solution_types is SOLUTION_TYPE_RECOMMENDATION.
  --name: string # Immutable. Fully qualified name `projects/*/locations/global/catalogs/*/servingConfig/*`
  --oneway-synonyms-control-ids: list<string> # Condition oneway synonyms specifications. If multiple oneway synonyms conditions match, all matching oneway synonyms controls in the list will execute. Order of controls in the list will not matter. Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --personalization-spec: record # The specification for personalization. — shape: {mode?: "MODE_UNSPECIFIED"|"AUTO"|"DISABLED"}
  --price-reranking-level: string # How much price ranking we want in serving results. Price reranking causes product items with a similar recommendation probability to be ordered by price, with the highest-priced items first. This setting could result in a decrease in click-through and conversion rates. Allowed values are: * `no-price-reranking` * `low-price-reranking` * `medium-price-reranking` * `high-price-reranking` If not specified, we choose default based on model type. Default value: `no-price-reranking`. Can only be set if solution_types is SOLUTION_TYPE_RECOMMENDATION.
  --redirect-control-ids: list<string> # Condition redirect specifications. Only the first triggered redirect action is applied, even if multiple apply. Maximum number of specifications is 1000. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --replacement-control-ids: list<string> # Condition replacement specifications. - Applied according to the order in the list. - A previously replaced term can not be re-replaced. - Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
  --solution-types: list<string> # Required. Immutable. Specifies the solution types that a serving config can be associated with. Currently we support setting only one type of solution.
  --twoway-synonyms-control-ids: list<string> # Condition synonyms specifications. If multiple syonyms conditions match, all matching synonyms control in the list will execute. Order of controls in the list will not matter. Maximum number of specifications is 100. Can only be set if solution_types is SOLUTION_TYPE_SEARCH.
]: any -> record<boostControlIds: list<string>, displayName: string, diversityLevel: string, diversityType: string, doNotAssociateControlIds: list<string>, dynamicFacetSpec: record<mode: string>, enableCategoryFilterLevel: string, facetControlIds: list<string>, filterControlIds: list<string>, ignoreControlIds: list<string>, modelId: string, name: string, onewaySynonymsControlIds: list<string>, personalizationSpec: record<mode: string>, priceRerankingLevel: string, redirectControlIds: list<string>, replacementControlIds: list<string>, solutionTypes: list<string>, twowaySynonymsControlIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "servingConfigId" $serving_config_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/servingConfigs") $qp)
  let req_body = {"boostControlIds": $boost_control_ids, "displayName": $display_name, "diversityLevel": $diversity_level, "diversityType": $diversity_type, "doNotAssociateControlIds": $do_not_associate_control_ids, "dynamicFacetSpec": $dynamic_facet_spec, "enableCategoryFilterLevel": $enable_category_filter_level, "facetControlIds": $facet_control_ids, "filterControlIds": $filter_control_ids, "ignoreControlIds": $ignore_control_ids, "modelId": $model_id, "name": $name, "onewaySynonymsControlIds": $oneway_synonyms_control_ids, "personalizationSpec": $personalization_spec, "priceRerankingLevel": $price_reranking_level, "redirectControlIds": $redirect_control_ids, "replacementControlIds": $replacement_control_ids, "solutionTypes": $solution_types, "twowaySynonymsControlIds": $twoway_synonyms_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Writes a single user event from the browser. This uses a GET request to due to browser restriction of POST-ing to a 3rd party domain. This method is used only by the Retail API JavaScript pixel and Google Tag Manager. Users should not call this method directly.
#
# GET /v2alpha/{parent}/userEvents:collect
# operationId: retail.projects.locations.catalogs.userEvents.collect
export def "v2alpha-user-events-collect get" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --ets: string # The event timestamp in milliseconds. This prevents browser caching of otherwise identical get requests. The name is abbreviated to reduce the payload bytes.
  --prebuilt-rule: string # The prebuilt rule name that can convert a specific type of raw_json. For example: "ga4_bq" rule for the GA4 user event schema.
  --raw-json: string # An arbitrary serialized JSON string that contains necessary information that can comprise a user event. When this field is specified, the user_event field will be ignored. Note: line-delimited JSON is not supported, a single JSON only.
  --uri: string # The URL including cgi-parameters but excluding the hash fragment with a length limit of 5,000 characters. This is often more useful than the referer URL, because many browsers only send the domain for 3rd party requests.
  --user-event: string # Required. URL encoded UserEvent proto with a length limit of 2,000,000 characters.
]: nothing -> record<contentType: string, data: string, extensions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "ets" $ets "scalar") (serialize-qp "prebuiltRule" $prebuilt_rule "scalar") (serialize-qp "rawJson" $raw_json "scalar") (serialize-qp "uri" $uri "scalar") (serialize-qp "userEvent" $user_event "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/userEvents:collect") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk import of User events. Request processing might be synchronous. Events that already exist are skipped. Use this method for backfilling historical user events. `Operation.response` is of type `ImportResponse`. Note that it is possible for a subset of the items to be successfully inserted. `Operation.metadata` is of type `ImportMetadata`.
#
# POST /v2alpha/{parent}/userEvents:import
# operationId: retail.projects.locations.catalogs.userEvents.import
# --errorsConfig shape: {gcsPrefix?: string}
# --inputConfig shape: {bigQuerySource?: record, gcsSource?: record, userEventInlineSource?: record}
export def "v2alpha-user-events-import import" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --errors-config: record # Configuration of destination for Import related errors. — shape: {gcsPrefix?: string}
  --input-config: record # The input config source for user events. — shape: {bigQuerySource?: record, gcsSource?: record, userEventInlineSource?: record}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/userEvents:import") $qp)
  let req_body = {"errorsConfig": $errors_config, "inputConfig": $input_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deletes permanently all user events specified by the filter provided. Depending on the number of events specified by the filter, this operation could take hours or days to complete. To test a filter, use the list command first.
#
# POST /v2alpha/{parent}/userEvents:purge
# operationId: retail.projects.locations.catalogs.userEvents.purge
export def "v2alpha-user-events-purge create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Required. The filter string to specify the events to be deleted with a length limit of 5,000 characters. Empty string filter is not allowed. The eligible fields for filtering are: * `eventType`: Double quoted UserEvent.event_type string. * `eventTime`: in ISO 8601 "zulu" format. * `visitorId`: Double quoted string. Specifying this will delete all events associated with a visitor. * `userId`: Double quoted string. Specifying this will delete all events associated with a user. Examples: * Deleting all events in a time range: `eventTime > "2012-04-23T18:25:43.511Z" eventTime < "2012-04-23T18:30:43.511Z"` * Deleting specific eventType in time range: `eventTime > "2012-04-23T18:25:43.511Z" eventType = "detail-page-view"` * Deleting all events for a specific visitor: `visitorId = "visitor1024"` The filtering fields are assumed to have an implicit AND.
  --force: oneof<nothing, bool> # Actually perform the purge. If `force` is set to false, the method will return the expected purge count without deleting any user events.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/userEvents:purge") $qp)
  let req_body = {"filter": $filter, "force": $force} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Starts a user-event rejoin operation with latest product catalog. Events are not annotated with detailed product information for products that are missing from the catalog when the user event is ingested. These events are stored as unjoined events with limited usage on training and serving. You can use this method to start a join operation on specified events with the latest version of product catalog. You can also use this method to correct events joined with the wrong product catalog. A rejoin operation can take hours or days to complete.
#
# POST /v2alpha/{parent}/userEvents:rejoin
# operationId: retail.projects.locations.catalogs.userEvents.rejoin
export def "v2alpha-user-events-rejoin create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --user-event-rejoin-scope: string@user-event-rejoin-scope-completer # The type of the user event rejoin to define the scope and range of the user events to be rejoined with the latest product catalog. Defaults to `USER_EVENT_REJOIN_SCOPE_UNSPECIFIED` if this field is not set, or set to an invalid integer value.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/userEvents:rejoin") $qp)
  let req_body = {"userEventRejoinScope": $user_event_rejoin_scope} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Writes a single user event.
#
# POST /v2alpha/{parent}/userEvents:write
# operationId: retail.projects.locations.catalogs.userEvents.write
# --completionDetail shape: {completionAttributionToken?: string, selectedPosition?: int, selectedSuggestion?: string}
# --productDetails item shape: {product?: record, quantity?: int}
# --purchaseTransaction shape: {cost?: float, currencyCode?: string, id?: string, revenue?: float, tax?: float}
# --userInfo shape: {directUserRequest?: bool, ipAddress?: string, userAgent?: string, userId?: string}
export def "v2alpha-user-events-write create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --write-async: oneof<nothing, bool> # If set to true, the user event will be written asynchronously after validation, and the API will respond without waiting for the write. Therefore, silent failures can occur even if the API returns success. In case of silent failures, error messages can be found in Stackdriver logs.
  --attributes: record # Extra user event features to include in the recommendation model. If you provide custom attributes for ingested user events, also include them in the user events that you associate with prediction requests. Custom attribute formatting must be consistent between imported events and events provided with prediction requests. This lets the Retail API use those custom attributes when training models and serving predictions, which helps improve recommendation quality. This field needs to pass all below criteria, otherwise an INVALID_ARGUMENT error is returned: * The key must be a UTF-8 encoded string with a length limit of 5,000 characters. * For text attributes, at most 400 values are allowed. Empty values are not allowed. Each value must be a UTF-8 encoded string with a length limit of 256 characters. * For number attributes, at most 400 values are allowed. For product recommendations, an example of extra user information is traffic_channel, which is how a user arrives at the site. Users can arrive at the site by coming to the site directly, coming through Google search, or in other ways.
  --attribution-token: string # Highly recommended for user events that are the result of PredictionService.Predict. This field enables accurate attribution of recommendation model performance. The value must be a valid PredictResponse.attribution_token for user events that are the result of PredictionService.Predict. The value must be a valid SearchResponse.attribution_token for user events that are the result of SearchService.Search. This token enables us to accurately attribute page view or purchase back to the event and the particular predict response containing this clicked/purchased product. If user clicks on product K in the recommendation results, pass PredictResponse.attribution_token as a URL parameter to product K's page. When recording events on product K's page, log the PredictResponse.attribution_token to this field.
  --cart-id: string # The ID or name of the associated shopping cart. This ID is used to associate multiple items added or present in the cart before purchase. This can only be set for `add-to-cart`, `purchase-complete`, or `shopping-cart-page-view` events.
  --completion-detail: record # Detailed completion information including completion attribution token and clicked completion info. — shape: {completionAttributionToken?: string, selectedPosition?: int, selectedSuggestion?: string}
  --entity: string # The entity for customers that may run multiple different entities, domains, sites or regions, for example, `Google US`, `Google Ads`, `Waymo`, `google.com`, `youtube.com`, etc. It is recommended to set this field to get better per-entity search, completion and prediction results.
  --event-time: string # Only required for UserEventService.ImportUserEvents method. Timestamp of when the user event happened. (format: google-datetime)
  --event-type: string # Required. User event type. Allowed values are: * `add-to-cart`: Products being added to cart. * `category-page-view`: Special pages such as sale or promotion pages viewed. * `detail-page-view`: Products detail page viewed. * `home-page-view`: Homepage viewed. * `promotion-offered`: Promotion is offered to a user. * `promotion-not-offered`: Promotion is not offered to a user. * `purchase-complete`: User finishing a purchase. * `search`: Product search. * `shopping-cart-page-view`: User viewing a shopping cart.
  --experiment-ids: list<string> # A list of identifiers for the independent experiment groups this user event belongs to. This is used to distinguish between user events associated with different experiment setups (e.g. using Retail API, using different recommendation models).
  --filter: string # The filter syntax consists of an expression language for constructing a predicate from one or more fields of the products being filtered. See SearchRequest.filter for definition and syntax. The value must be a UTF-8 encoded string with a length limit of 1,000 characters. Otherwise, an INVALID_ARGUMENT error is returned.
  --offset: int # An integer that specifies the current offset for pagination (the 0-indexed starting location, amongst the products deemed by the API as relevant). See SearchRequest.offset for definition. If this field is negative, an INVALID_ARGUMENT is returned. This can only be set for `search` events. Other event types should not set this field. Otherwise, an INVALID_ARGUMENT error is returned. (format: int32)
  --order-by: string # The order in which products are returned. See SearchRequest.order_by for definition and syntax. The value must be a UTF-8 encoded string with a length limit of 1,000 characters. Otherwise, an INVALID_ARGUMENT error is returned. This can only be set for `search` events. Other event types should not set this field. Otherwise, an INVALID_ARGUMENT error is returned.
  --page-categories: list<string> # The categories associated with a category page. To represent full path of category, use '>' sign to separate different hierarchies. If '>' is part of the category name, replace it with other character(s). Category pages include special pages such as sales or promotions. For instance, a special sale page may have the category hierarchy: "pageCategories" : ["Sales > 2017 Black Friday Deals"]. Required for `category-page-view` events. At least one of search_query or page_categories is required for `search` events. Other event types should not set this field. Otherwise, an INVALID_ARGUMENT error is returned.
  --page-view-id: string # A unique ID of a web page view. This should be kept the same for all user events triggered from the same pageview. For example, an item detail page view could trigger multiple events as the user is browsing the page. The `pageViewId` property should be kept the same for all these events so that they can be grouped together properly. When using the client side event reporting with JavaScript pixel and Google Tag Manager, this value is filled in automatically.
  --product-details: list # The main product details related to the event. This field is optional except for the following event types: * `add-to-cart` * `detail-page-view` * `purchase-complete` In a `search` event, this field represents the products returned to the end user on the current page (the end user may have not finished browsing the whole page yet). When a new page is returned to the end user, after pagination/filtering/ordering even for the same query, a new `search` event with different product_details is desired. The end user may have not finished browsing the whole page yet. — item shape: {product?: record, quantity?: int}
  --purchase-transaction: record # A transaction represents the entire purchase transaction. — shape: {cost?: float, currencyCode?: string, id?: string, revenue?: float, tax?: float}
  --referrer-uri: string # The referrer URL of the current page. When using the client side event reporting with JavaScript pixel and Google Tag Manager, this value is filled in automatically.
  --search-query: string # The user's search query. See SearchRequest.query for definition. The value must be a UTF-8 encoded string with a length limit of 5,000 characters. Otherwise, an INVALID_ARGUMENT error is returned. At least one of search_query or page_categories is required for `search` events. Other event types should not set this field. Otherwise, an INVALID_ARGUMENT error is returned.
  --session-id: string # A unique identifier for tracking a visitor session with a length limit of 128 bytes. A session is an aggregation of an end user behavior in a time span. A general guideline to populate the sesion_id: 1. If user has no activity for 30 min, a new session_id should be assigned. 2. The session_id should be unique across users, suggest use uuid or add visitor_id as prefix.
  --uri: string # Complete URL (window.location.href) of the user's current page. When using the client side event reporting with JavaScript pixel and Google Tag Manager, this value is filled in automatically. Maximum length 5,000 characters.
  --user-info: record # Information of an end user. — shape: {directUserRequest?: bool, ipAddress?: string, userAgent?: string, userId?: string}
  --visitor-id: string # Required. A unique identifier for tracking visitors. For example, this could be implemented with an HTTP cookie, which should be able to uniquely identify a visitor on a single device. This unique identifier should not change if the visitor log in/out of the website. Don't set the field to the same fixed ID for different users. This mixes the event history of those users together, which results in degraded model quality. The field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned. The field should not contain PII or user-data. We recommend to use Google Analytics [Client ID](https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#clientId) for this field.
]: any -> record<attributes: record, attributionToken: string, cartId: string, completionDetail: record<completionAttributionToken: string, selectedPosition: int, selectedSuggestion: string>, entity: string, eventTime: string, eventType: string, experimentIds: list<string>, filter: string, offset: int, orderBy: string, pageCategories: list<string>, pageViewId: string, productDetails: table<product: record, quantity: int>, purchaseTransaction: record<cost: float, currencyCode: string, id: string, revenue: float, tax: float>, referrerUri: string, searchQuery: string, sessionId: string, uri: string, userInfo: record<directUserRequest: bool, ipAddress: string, userAgent: string, userId: string>, visitorId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "writeAsync" $write_async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v2alpha/{parent}/userEvents:write") $qp)
  let req_body = {"attributes": $attributes, "attributionToken": $attribution_token, "cartId": $cart_id, "completionDetail": $completion_detail, "entity": $entity, "eventTime": $event_time, "eventType": $event_type, "experimentIds": $experiment_ids, "filter": $filter, "offset": $offset, "orderBy": $order_by, "pageCategories": $page_categories, "pageViewId": $page_view_id, "productDetails": $product_details, "purchaseTransaction": $purchase_transaction, "referrerUri": $referrer_uri, "searchQuery": $search_query, "sessionId": $session_id, "uri": $uri, "userInfo": $user_info, "visitorId": $visitor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Makes a recommendation prediction.
#
# POST /v2alpha/{placement}:predict
# operationId: retail.projects.locations.catalogs.servingConfigs.predict
# --userEvent shape: {attributes?: record, attributionToken?: string, cartId?: string, completionDetail?: record, entity?: string, eventTime?: string, eventType?: string, experimentIds?: list<string>, filter?: string, offset?: int, orderBy?: string, pageCategories?: list<string>, pageViewId?: string, productDetails?: list, purchaseTransaction?: record, referrerUri?: string, searchQuery?: string, sessionId?: string, uri?: string, userInfo?: record, visitorId?: string}
export def "v2alpha create-predict" [
  placement: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filter for restricting prediction results with a length limit of 5,000 characters. Accepts values for tags and the `filterOutOfStockItems` flag. * Tag expressions. Restricts predictions to products that match all of the specified tags. Boolean operators `OR` and `NOT` are supported if the expression is enclosed in parentheses, and must be separated from the tag values by a space. `-"tagA"` is also supported and is equivalent to `NOT "tagA"`. Tag values must be double quoted UTF-8 encoded strings with a size limit of 1,000 characters. Note: "Recently viewed" models don't support tag filtering at the moment. * filterOutOfStockItems. Restricts predictions to products that do not have a stockState value of OUT_OF_STOCK. Examples: * tag=("Red" OR "Blue") tag="New-Arrival" tag=(NOT "promotional") * filterOutOfStockItems tag=(-"promotional") * filterOutOfStockItems If your filter blocks all prediction results, the API will return *no* results. If instead you want empty result sets to return generic (unfiltered) popular products, set `strictFiltering` to False in `PredictRequest.params`. Note that the API will never return items with storageStatus of "EXPIRED" or "DELETED" regardless of filter choices. If `filterSyntaxV2` is set to true under the `params` field, then attribute-based expressions are expected instead of the above described tag-based syntax. Examples: * (colors: ANY("Red", "Blue")) AND NOT (categories: ANY("Phones")) * (availability: ANY("IN_STOCK")) AND (colors: ANY("Red") OR categories: ANY("Phones")) For more information, see [Filter recommendations](https://cloud.google.com/retail/docs/filter-recs).
  --labels: record # The labels applied to a resource must meet the following requirements: * Each resource can have multiple labels, up to a maximum of 64. * Each label must be a key-value pair. * Keys have a minimum length of 1 character and a maximum length of 63 characters and cannot be empty. Values can be empty and have a maximum length of 63 characters. * Keys and values can contain only lowercase letters, numeric characters, underscores, and dashes. All characters must use UTF-8 encoding, and international characters are allowed. * The key portion of a label must be unique. However, you can use the same key with multiple resources. * Keys must start with a lowercase letter or international character. See [Google Cloud Document](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements) for more details.
  --page-size: int # Maximum number of results to return. Set this property to the number of prediction results needed. If zero, the service will choose a reasonable default. The maximum allowed value is 100. Values above 100 will be coerced to 100. (format: int32)
  --page-token: string # This field is not used; leave it unset.
  --params: record # Additional domain specific parameters for the predictions. Allowed values: * `returnProduct`: Boolean. If set to true, the associated product object will be returned in the `results.metadata` field in the prediction response. * `returnScore`: Boolean. If set to true, the prediction 'score' corresponding to each returned product will be set in the `results.metadata` field in the prediction response. The given 'score' indicates the probability of a product being clicked/purchased given the user's context and history. * `strictFiltering`: Boolean. True by default. If set to false, the service will return generic (unfiltered) popular products instead of empty if your filter blocks all prediction results. * `priceRerankLevel`: String. Default empty. If set to be non-empty, then it needs to be one of {'no-price-reranking', 'low-price-reranking', 'medium-price-reranking', 'high-price-reranking'}. This gives request-level control and adjusts prediction results based on product price. * `diversityLevel`: String. Default empty. If set to be non-empty, then it needs to be one of {'no-diversity', 'low-diversity', 'medium-diversity', 'high-diversity', 'auto-diversity'}. This gives request-level control and adjusts prediction results based on product category. * `filterSyntaxV2`: Boolean. False by default. If set to true, the `filter` field is interpreteted according to the new, attribute-based syntax.
  --user-event: record # UserEvent captures all metadata information Retail API needs to know about how end users interact with customers' website. — shape: {attributes?: record, attributionToken?: string, cartId?: string, completionDetail?: record, entity?: string, eventTime?: string, eventType?: string, experimentIds?: list<string>, filter?: string, offset?: int, orderBy?: string, pageCategories?: list<string>, pageViewId?: string, productDetails?: list, purchaseTransaction?: record, referrerUri?: string, searchQuery?: string, sessionId?: string, uri?: string, userInfo?: record, visitorId?: string}
  --validate-only: oneof<nothing, bool> # Use validate only mode for this prediction query. If set to true, a dummy model will be used that returns arbitrary products. Note that the validate only mode should only be used for testing the API, or if the model is not ready.
]: any -> record<attributionToken: string, missingIds: list<string>, results: table<id: string, metadata: record>, validateOnly: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({placement: (encode-path-segment $placement)} | format pattern "/v2alpha/{placement}:predict") $qp)
  let req_body = {"filter": $filter, "labels": $labels, "pageSize": $page_size, "pageToken": $page_token, "params": $params, "userEvent": $user_event, "validateOnly": $validate_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Performs a search. This feature is only available for users who have Retail Search enabled. Enable Retail Search on Cloud Console before using this feature.
#
# POST /v2alpha/{placement}:search
# operationId: retail.projects.locations.catalogs.servingConfigs.search
# --boostSpec shape: {conditionBoostSpecs?: list, skipBoostSpecValidation?: bool}
# --dynamicFacetSpec shape: {mode?: "MODE_UNSPECIFIED"|"DISABLED"|"ENABLED"}
# --facetSpecs item shape: {enableDynamicPosition?: bool, excludedFilterKeys?: list<string>, facetKey?: record, limit?: int}
# --personalizationSpec shape: {mode?: "MODE_UNSPECIFIED"|"AUTO"|"DISABLED"}
# --queryExpansionSpec shape: {condition?: "CONDITION_UNSPECIFIED"|"DISABLED"|"AUTO", pinUnexpandedResults?: bool}
# --spellCorrectionSpec shape: {mode?: "MODE_UNSPECIFIED"|"SUGGESTION_ONLY"|"AUTO"}
# --userInfo shape: {directUserRequest?: bool, ipAddress?: string, userAgent?: string, userId?: string}
export def "v2alpha list" [
  placement: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --boost-spec: record # Boost specification to boost certain items. — shape: {conditionBoostSpecs?: list, skipBoostSpecValidation?: bool}
  --branch: string # The branch resource name, such as `projects/*/locations/global/catalogs/default_catalog/branches/0`. Use "default_branch" as the branch ID or leave this field empty, to search products under the default branch.
  --canonical-filter: string # The default filter that is applied when a user performs a search without checking any filters on the search page. The filter applied to every search request when quality improvement such as query expansion is needed. For example, if a query does not have enough results, an expanded query with SearchRequest.canonical_filter will be returned as a supplement of the original query. This field is strongly recommended to achieve high search quality. See SearchRequest.filter for more details about filter syntax.
  --dynamic-facet-spec: record # The specifications of dynamically generated facets. — shape: {mode?: "MODE_UNSPECIFIED"|"DISABLED"|"ENABLED"}
  --entity: string # The entity for customers that may run multiple different entities, domains, sites or regions, for example, `Google US`, `Google Ads`, `Waymo`, `google.com`, `youtube.com`, etc. If this is set, it should be exactly matched with UserEvent.entity to get search results boosted by entity.
  --facet-specs: list # Facet specifications for faceted search. If empty, no facets are returned. A maximum of 200 values are allowed. Otherwise, an INVALID_ARGUMENT error is returned. — item shape: {enableDynamicPosition?: bool, excludedFilterKeys?: list<string>, facetKey?: record, limit?: int}
  --filter: string # The filter syntax consists of an expression language for constructing a predicate from one or more fields of the products being filtered. Filter expression is case-sensitive. See more details at this [user guide](https://cloud.google.com/retail/docs/filter-and-order#filter). If this field is unrecognizable, an INVALID_ARGUMENT is returned.
  --labels: record # The labels applied to a resource must meet the following requirements: * Each resource can have multiple labels, up to a maximum of 64. * Each label must be a key-value pair. * Keys have a minimum length of 1 character and a maximum length of 63 characters and cannot be empty. Values can be empty and have a maximum length of 63 characters. * Keys and values can contain only lowercase letters, numeric characters, underscores, and dashes. All characters must use UTF-8 encoding, and international characters are allowed. * The key portion of a label must be unique. However, you can use the same key with multiple resources. * Keys must start with a lowercase letter or international character. See [Google Cloud Document](https://cloud.google.com/resource-manager/docs/creating-managing-labels#requirements) for more details.
  --offset: int # A 0-indexed integer that specifies the current offset (that is, starting result location, amongst the Products deemed by the API as relevant) in search results. This field is only considered if page_token is unset. If this field is negative, an INVALID_ARGUMENT is returned. (format: int32)
  --order-by: string # The order in which products are returned. Products can be ordered by a field in an Product object. Leave it unset if ordered by relevance. OrderBy expression is case-sensitive. See more details at this [user guide](https://cloud.google.com/retail/docs/filter-and-order#order). If this field is unrecognizable, an INVALID_ARGUMENT is returned.
  --page-categories: list<string> # The categories associated with a category page. Must be set for category navigation queries to achieve good search quality. The format should be the same as UserEvent.page_categories; To represent full path of category, use '>' sign to separate different hierarchies. If '>' is part of the category name, replace it with other character(s). Category pages include special pages such as sales or promotions. For instance, a special sale page may have the category hierarchy: "pageCategories" : ["Sales > 2017 Black Friday Deals"].
  --page-size: int # Maximum number of Products to return. If unspecified, defaults to a reasonable value. The maximum allowed value is 120. Values above 120 will be coerced to 120. If this field is negative, an INVALID_ARGUMENT is returned. (format: int32)
  --page-token: string # A page token SearchResponse.next_page_token, received from a previous SearchService.Search call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to SearchService.Search must match the call that provided the page token. Otherwise, an INVALID_ARGUMENT error is returned.
  --personalization-spec: record # The specification for personalization. — shape: {mode?: "MODE_UNSPECIFIED"|"AUTO"|"DISABLED"}
  --query: string # Raw search query. If this field is empty, the request is considered a category browsing request and returned results are based on filter and page_categories.
  --query-expansion-spec: record # Specification to determine under which conditions query expansion should occur. — shape: {condition?: "CONDITION_UNSPECIFIED"|"DISABLED"|"AUTO", pinUnexpandedResults?: bool}
  --relevance-threshold: string@relevance-threshold-completer # The relevance threshold of the search results. Defaults to RelevanceThreshold.HIGH, which means only the most relevant results are shown, and the least number of results are returned. See more details at this [user guide](https://cloud.google.com/retail/docs/result-size#relevance_thresholding).
  --search-mode: string@search-mode-completer # The search mode of the search request. If not specified, a single search request triggers both product search and faceted search.
  --spell-correction-spec: record # The specification for query spell correction. — shape: {mode?: "MODE_UNSPECIFIED"|"SUGGESTION_ONLY"|"AUTO"}
  --user-info: record # Information of an end user. — shape: {directUserRequest?: bool, ipAddress?: string, userAgent?: string, userId?: string}
  --variant-rollup-keys: list<string> # The keys to fetch and rollup the matching variant Products attributes, FulfillmentInfo or LocalInventorys attributes. The attributes from all the matching variant Products or LocalInventorys are merged and de-duplicated. Notice that rollup attributes will lead to extra query latency. Maximum number of keys is 30. For FulfillmentInfo, a fulfillment type and a fulfillment ID must be provided in the format of "fulfillmentType.fulfillmentId". E.g., in "pickupInStore.store123", "pickupInStore" is fulfillment type and "store123" is the store ID. Supported keys are: * colorFamilies * price * originalPrice * discount * variantId * inventory(place_id,price) * inventory(place_id,original_price) * inventory(place_id,attributes.key), where key is any key in the Product.local_inventories.attributes map. * attributes.key, where key is any key in the Product.attributes map. * pickupInStore.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "pickup-in-store". * shipToStore.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "ship-to-store". * sameDayDelivery.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "same-day-delivery". * nextDayDelivery.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "next-day-delivery". * customFulfillment1.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "custom-type-1". * customFulfillment2.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "custom-type-2". * customFulfillment3.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "custom-type-3". * customFulfillment4.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "custom-type-4". * customFulfillment5.id, where id is any FulfillmentInfo.place_ids for FulfillmentInfo.type "custom-type-5". If this field is set to an invalid value other than these, an INVALID_ARGUMENT error is returned.
  --visitor-id: string # Required. A unique identifier for tracking visitors. For example, this could be implemented with an HTTP cookie, which should be able to uniquely identify a visitor on a single device. This unique identifier should not change if the visitor logs in or out of the website. This should be the same identifier as UserEvent.visitor_id. The field must be a UTF-8 encoded string with a length limit of 128 characters. Otherwise, an INVALID_ARGUMENT error is returned.
]: any -> record<appliedControls: list<string>, attributionToken: string, correctedQuery: string, experimentInfo: table<experiment: string, servingConfigExperiment: record>, facets: table<dynamicFacet: bool, key: string, values: list>, invalidConditionBoostSpecs: table<boost: float, condition: string>, nextPageToken: string, queryExpansionInfo: record<expandedQuery: bool, pinnedResultCount: string>, redirectUri: string, results: table<id: string, matchingVariantCount: int, matchingVariantFields: record, personalLabels: list, product: record, variantRollupValues: record>, totalSize: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({placement: (encode-path-segment $placement)} | format pattern "/v2alpha/{placement}:search") $qp)
  let req_body = {"boostSpec": $boost_spec, "branch": $branch, "canonicalFilter": $canonical_filter, "dynamicFacetSpec": $dynamic_facet_spec, "entity": $entity, "facetSpecs": $facet_specs, "filter": $filter, "labels": $labels, "offset": $offset, "orderBy": $order_by, "pageCategories": $page_categories, "pageSize": $page_size, "pageToken": $page_token, "personalizationSpec": $personalization_spec, "query": $query, "queryExpansionSpec": $query_expansion_spec, "relevanceThreshold": $relevance_threshold, "searchMode": $search_mode, "spellCorrectionSpec": $spell_correction_spec, "userInfo": $user_info, "variantRollupKeys": $variant_rollup_keys, "visitorId": $visitor_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# It is recommended to use the ProductService.AddLocalInventories method instead of ProductService.AddFulfillmentPlaces. ProductService.AddLocalInventories achieves the same results but provides more fine-grained control over ingesting local inventory data. Incrementally adds place IDs to Product.fulfillment_info.place_ids. This process is asynchronous and does not require the Product to exist before updating fulfillment information. If the request is valid, the update will be enqueued and processed downstream. As a consequence, when a response is returned, the added place IDs are not immediately manifested in the Product queried by ProductService.GetProduct or ProductService.ListProducts. The returned Operations will be obsolete after 1 day, and GetOperation API will return NOT_FOUND afterwards. If conflicting updates are issued, the Operations associated with the stale updates will not be marked as done until being obsolete.
#
# POST /v2alpha/{product}:addFulfillmentPlaces
# operationId: retail.projects.locations.catalogs.branches.products.addFulfillmentPlaces
export def "v2alpha create-fulfillment-places" [
  product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --add-time: string # The time when the fulfillment updates are issued, used to prevent out-of-order updates on fulfillment information. If not provided, the internal system time will be used. (format: google-datetime)
  --allow-missing: oneof<nothing, bool> # If set to true, and the Product is not found, the fulfillment information will still be processed and retained for at most 1 day and processed once the Product is created. If set to false, a NOT_FOUND error is returned if the Product is not found.
  --place-ids: list<string> # Required. The IDs for this type, such as the store IDs for "pickup-in-store" or the region IDs for "same-day-delivery" to be added for this type. Duplicate IDs will be automatically ignored. At least 1 value is required, and a maximum of 2000 values are allowed. Each value must be a string with a length limit of 10 characters, matching the pattern `[a-zA-Z0-9_-]+`, such as "store1" or "REGION-2". Otherwise, an INVALID_ARGUMENT error is returned. If the total number of place IDs exceeds 2000 for this type after adding, then the update will be rejected.
  --type: string # Required. The fulfillment type, including commonly used types (such as pickup in store and same day delivery), and custom types. Supported values: * "pickup-in-store" * "ship-to-store" * "same-day-delivery" * "next-day-delivery" * "custom-type-1" * "custom-type-2" * "custom-type-3" * "custom-type-4" * "custom-type-5" If this field is set to an invalid value other than these, an INVALID_ARGUMENT error is returned. This field directly corresponds to Product.fulfillment_info.type.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product: (encode-path-segment $product)} | format pattern "/v2alpha/{product}:addFulfillmentPlaces") $qp)
  let req_body = {"addTime": $add_time, "allowMissing": $allow_missing, "placeIds": $place_ids, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Updates local inventory information for a Product at a list of places, while respecting the last update timestamps of each inventory field. This process is asynchronous and does not require the Product to exist before updating inventory information. If the request is valid, the update will be enqueued and processed downstream. As a consequence, when a response is returned, updates are not immediately manifested in the Product queried by ProductService.GetProduct or ProductService.ListProducts. Local inventory information can only be modified using this method. ProductService.CreateProduct and ProductService.UpdateProduct has no effect on local inventories. The returned Operations will be obsolete after 1 day, and GetOperation API will return NOT_FOUND afterwards. If conflicting updates are issued, the Operations associated with the stale updates will not be marked as done until being obsolete.
#
# POST /v2alpha/{product}:addLocalInventories
# operationId: retail.projects.locations.catalogs.branches.products.addLocalInventories
# --localInventories item shape: {attributes?: record, fulfillmentTypes?: list<string>, placeId?: string, priceInfo?: record}
export def "v2alpha create-local-inventories" [
  product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --add-mask: string # Indicates which inventory fields in the provided list of LocalInventory to update. The field is updated to the provided value. If a field is set while the place does not have a previous local inventory, the local inventory at that store is created. If a field is set while the value of that field is not provided, the original field value, if it exists, is deleted. If the mask is not set or set with empty paths, all inventory fields will be updated. If an unsupported or unknown field is provided, an INVALID_ARGUMENT error is returned and the entire update will be ignored. (format: google-fieldmask)
  --add-time: string # The time when the inventory updates are issued. Used to prevent out-of-order updates on local inventory fields. If not provided, the internal system time will be used. (format: google-datetime)
  --allow-missing: oneof<nothing, bool> # If set to true, and the Product is not found, the local inventory will still be processed and retained for at most 1 day and processed once the Product is created. If set to false, a NOT_FOUND error is returned if the Product is not found.
  --local-inventories: list # Required. A list of inventory information at difference places. Each place is identified by its place ID. At most 3000 inventories are allowed per request. — item shape: {attributes?: record, fulfillmentTypes?: list<string>, placeId?: string, priceInfo?: record}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product: (encode-path-segment $product)} | format pattern "/v2alpha/{product}:addLocalInventories") $qp)
  let req_body = {"addMask": $add_mask, "addTime": $add_time, "allowMissing": $allow_missing, "localInventories": $local_inventories} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# It is recommended to use the ProductService.RemoveLocalInventories method instead of ProductService.RemoveFulfillmentPlaces. ProductService.RemoveLocalInventories achieves the same results but provides more fine-grained control over ingesting local inventory data. Incrementally removes place IDs from a Product.fulfillment_info.place_ids. This process is asynchronous and does not require the Product to exist before updating fulfillment information. If the request is valid, the update will be enqueued and processed downstream. As a consequence, when a response is returned, the removed place IDs are not immediately manifested in the Product queried by ProductService.GetProduct or ProductService.ListProducts. The returned Operations will be obsolete after 1 day, and GetOperation API will return NOT_FOUND afterwards. If conflicting updates are issued, the Operations associated with the stale updates will not be marked as done until being obsolete.
#
# POST /v2alpha/{product}:removeFulfillmentPlaces
# operationId: retail.projects.locations.catalogs.branches.products.removeFulfillmentPlaces
export def "v2alpha delete-fulfillment-places" [
  product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-missing: oneof<nothing, bool> # If set to true, and the Product is not found, the fulfillment information will still be processed and retained for at most 1 day and processed once the Product is created. If set to false, a NOT_FOUND error is returned if the Product is not found.
  --place-ids: list<string> # Required. The IDs for this type, such as the store IDs for "pickup-in-store" or the region IDs for "same-day-delivery", to be removed for this type. At least 1 value is required, and a maximum of 2000 values are allowed. Each value must be a string with a length limit of 10 characters, matching the pattern `[a-zA-Z0-9_-]+`, such as "store1" or "REGION-2". Otherwise, an INVALID_ARGUMENT error is returned.
  --remove-time: string # The time when the fulfillment updates are issued, used to prevent out-of-order updates on fulfillment information. If not provided, the internal system time will be used. (format: google-datetime)
  --type: string # Required. The fulfillment type, including commonly used types (such as pickup in store and same day delivery), and custom types. Supported values: * "pickup-in-store" * "ship-to-store" * "same-day-delivery" * "next-day-delivery" * "custom-type-1" * "custom-type-2" * "custom-type-3" * "custom-type-4" * "custom-type-5" If this field is set to an invalid value other than these, an INVALID_ARGUMENT error is returned. This field directly corresponds to Product.fulfillment_info.type.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product: (encode-path-segment $product)} | format pattern "/v2alpha/{product}:removeFulfillmentPlaces") $qp)
  let req_body = {"allowMissing": $allow_missing, "placeIds": $place_ids, "removeTime": $remove_time, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove local inventory information for a Product at a list of places at a removal timestamp. This process is asynchronous. If the request is valid, the removal will be enqueued and processed downstream. As a consequence, when a response is returned, removals are not immediately manifested in the Product queried by ProductService.GetProduct or ProductService.ListProducts. Local inventory information can only be removed using this method. ProductService.CreateProduct and ProductService.UpdateProduct has no effect on local inventories. The returned Operations will be obsolete after 1 day, and GetOperation API will return NOT_FOUND afterwards. If conflicting updates are issued, the Operations associated with the stale updates will not be marked as done until being obsolete.
#
# POST /v2alpha/{product}:removeLocalInventories
# operationId: retail.projects.locations.catalogs.branches.products.removeLocalInventories
export def "v2alpha delete-local-inventories" [
  product: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-missing: oneof<nothing, bool> # If set to true, and the Product is not found, the local inventory removal request will still be processed and retained for at most 1 day and processed once the Product is created. If set to false, a NOT_FOUND error is returned if the Product is not found.
  --place-ids: list<string> # Required. A list of place IDs to have their inventory deleted. At most 3000 place IDs are allowed per request.
  --remove-time: string # The time when the inventory deletions are issued. Used to prevent out-of-order updates and deletions on local inventory fields. If not provided, the internal system time will be used. (format: google-datetime)
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({product: (encode-path-segment $product)} | format pattern "/v2alpha/{product}:removeLocalInventories") $qp)
  let req_body = {"allowMissing": $allow_missing, "placeIds": $place_ids, "removeTime": $remove_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Enables a Control on the specified ServingConfig. The control is added in the last position of the list of controls it belongs to (e.g. if it's a facet spec control it will be applied in the last position of servingConfig.facetSpecIds) Returns a ALREADY_EXISTS error if the control has already been applied. Returns a FAILED_PRECONDITION error if the addition could exceed maximum number of control allowed for that type of control.
#
# POST /v2alpha/{servingConfig}:addControl
# operationId: retail.projects.locations.catalogs.servingConfigs.addControl
export def "v2alpha create-control" [
  serving_config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --control-id: string # Required. The id of the control to apply. Assumed to be in the same catalog as the serving config - if id is not found a NOT_FOUND error is returned.
]: any -> record<boostControlIds: list<string>, displayName: string, diversityLevel: string, diversityType: string, doNotAssociateControlIds: list<string>, dynamicFacetSpec: record<mode: string>, enableCategoryFilterLevel: string, facetControlIds: list<string>, filterControlIds: list<string>, ignoreControlIds: list<string>, modelId: string, name: string, onewaySynonymsControlIds: list<string>, personalizationSpec: record<mode: string>, priceRerankingLevel: string, redirectControlIds: list<string>, replacementControlIds: list<string>, solutionTypes: list<string>, twowaySynonymsControlIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serving_config: (encode-path-segment $serving_config)} | format pattern "/v2alpha/{serving_config}:addControl") $qp)
  let req_body = {"controlId": $control_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disables a Control on the specified ServingConfig. The control is removed from the ServingConfig. Returns a NOT_FOUND error if the Control is not enabled for the ServingConfig.
#
# POST /v2alpha/{servingConfig}:removeControl
# operationId: retail.projects.locations.catalogs.servingConfigs.removeControl
export def "v2alpha delete-control" [
  serving_config: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --control-id: string # Required. The id of the control to apply. Assumed to be in the same catalog as the serving config.
]: any -> record<boostControlIds: list<string>, displayName: string, diversityLevel: string, diversityType: string, doNotAssociateControlIds: list<string>, dynamicFacetSpec: record<mode: string>, enableCategoryFilterLevel: string, facetControlIds: list<string>, filterControlIds: list<string>, ignoreControlIds: list<string>, modelId: string, name: string, onewaySynonymsControlIds: list<string>, personalizationSpec: record<mode: string>, priceRerankingLevel: string, redirectControlIds: list<string>, replacementControlIds: list<string>, solutionTypes: list<string>, twowaySynonymsControlIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serving_config: (encode-path-segment $serving_config)} | format pattern "/v2alpha/{serving_config}:removeControl") $qp)
  let req_body = {"controlId": $control_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
