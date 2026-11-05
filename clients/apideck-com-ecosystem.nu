# Auto-generated client for Ecosystem API v0.0.6
# Source: https://api.apis.guru/v2/specs/apideck.com/ecosystem/0.0.6/openapi.json
# Auth: --token flag or $env.ECOSYSTEM_API_TOKEN

const BASE_URL = "https://api.apideck.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ECOSYSTEM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.apideck.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["ecosystems-one" "categories-all" "categories-one" "category-listings-all" "collections-all" "collections-one" "collection-listings-all" "listings-all" "listings-one" "products-all" "products-one" "product-listings-all" "commands"] | sort) } | get name | first)
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

# Get ecosystem
#
# GET /ecosystems/{ecosystem_id}
# operationId: ecosystemsOne
export def "ecosystems-one" [
  ecosystem_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<data: record<about: string, alternatives_background_color: string, alternatives_color: string, attribution: bool, body_background_color: string, body_button_background_color: string, body_button_color: string, body_color: string, body_link_color: string, card_settings: record<background_color: string, border_color: string, border_radius: string, border_size: string, color: string, columns: int, description_lines: int, icon_border_radius: string, icon_shadow_enabled: bool, icon_size: int, shadow_enabled: bool, show_action: bool, show_badges: bool, show_category: bool, show_description: bool, style: string>, categories_count_badge: bool, categories_show_max_items: int, collections_count_badge: bool, collections_title: string, create_link: string, created_at: string, cta_settings: record<background_color: string, button_background_color: string, button_color: string, button_label: string, button_link: string, color: string, description: string, enabled: bool, title: string>, custom_domain: string, custom_settings: record<css: string, css_link: string, domain: string, html_footer: string, html_nav: string, java_script_link: string>, detail_pages_enabled: bool, footer_background_color: string, footer_color: string, google_site_verification_id: string, hide_install_buttons: bool, home_page_collection_category_cards: bool, home_page_show_all_listings: bool, id: string, installation_request_flow_enabled: bool, integration_settings: record<albacross_id: string, automate_enabled: bool, blendr_enabled: bool, combidesk_enabled: bool, crisp_id: string, drift_id: string, google_analytics_id: string, google_tag_manager_id: string, heap_id: string, hubspot_portal_id: string, integromat_enabled: bool, intercom_app_id: string, iubenda_cookie_policy_id: string, iubenda_site_id: string, journy_io_domain: string, journy_io_id: string, livechat_id: string, metomic_id: string, microsoft_flow_enabled: bool, microsoft_flow_id: string, onetrust_id: string, piesync_enabled: bool, segment_enabled: bool, segment_id: string, tray_io_enabled: bool, zapier_beta_link: string, zapier_enabled: bool, zapier_id: string>, is_published: bool, lead_form_settings: record<capture_form_enabled: bool, first_name_field_enabled: bool, first_name_field_required: bool, integration_enabled: bool, last_name_field_enabled: bool, last_name_field_required: bool, telephone_field_enabled: bool, telephone_field_required: bool, work_email_validation: bool>, listing_settings: record<description_text_template: string, description_title: string, features_text_template: string, features_title: string, install_button_label: string, name_postfix: string, naming: string, native_integration_link: string, pricing_disabled: bool, pricing_text_template: string, pricing_title: string, sidebar_position: string>, masthead_settings: record<background: string, background_color: string, color: string, columns: int, description: string, title: string>, menu_position: string, menu_style: string, meta_tag_settings: record<description: string, description_category_page: string, description_collection_page: string, description_listing_page: string, keywords: string, title: string, title_postfix: string>, name: string, navigation_background_color: string, navigation_color: string, navigation_logo_post_fix: string, navigation_mobile_menu_type: string, navigation_sticky: bool, primary_color: string, privacy_link: string, request_link: string, shadow_page_description: string, shadow_pages_enabled: bool, show_attribution_badge: bool, show_requested_listings: bool, slug: string, terms_link: string, total_published_listings: int, unify_application_id: string, updated_at: string, utm_campaign: string, website: string, zaps_menu_title: string, zaps_page_enabled: bool>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id)} | format pattern "/ecosystems/{ecosystem_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List categories
#
# GET /ecosystems/{ecosystem_id}/categories
# operationId: categoriesAll
export def "categories-all" [
  ecosystem_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of records to return (default: 50)
]: nothing -> oneof<record<data: table<count: int, created_at: string, description: string, id: string, listing_description_text_template: string, listing_features_text_template: string, listing_pricing_text_template: string, logo: record, name: string, slug: string, translations: list, updated_at: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id)} | format pattern "/ecosystems/{ecosystem_id}/categories") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get category
#
# GET /ecosystems/{ecosystem_id}/categories/{id}
# operationId: categoriesOne
export def "categories-one" [
  ecosystem_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<data: record<count: int, created_at: string, description: string, id: string, listing_description_text_template: string, listing_features_text_template: string, listing_pricing_text_template: string, logo: record<content_type: string, id: string, type: string, url: string>, name: string, slug: string, translations: list<record>, updated_at: string>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id), id: (encode-path-segment $id)} | format pattern "/ecosystems/{ecosystem_id}/categories/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List category listings
#
# GET /ecosystems/{ecosystem_id}/categories/{id}/listings
# operationId: categoryListingsAll
export def "category-listings-all" [
  ecosystem_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of records to return (default: 50)
]: nothing -> oneof<record<data: table<automate_id: string, blendr_id: string, card_background_color: string, card_background_image: record, categories: list, cloud_service_id: string, collections: list, combidesk_id: string, created_at: string, description: string, detail_page_disabled: bool, external_id: string, features: string, id: string, integromat_id: string, logo: record, media: list, meta_tag_description: string, meta_tag_keywords: string, meta_tag_title: string, microsoft_flow_id: string, name: string, native_integration: bool, native_integration_link: string, partner: record, piesync_id: string, pricing: string, products: list, published: bool, published_at: string, screenshots: list, segment_id: string, slug: string, sticky: bool, tag_line: string, third_party_integration: bool, third_party_integration_link: string, translations: list, tray_io_id: string, unify_connector_id: string, upcoming: bool, updated_at: string, zapier_id: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id), id: (encode-path-segment $id)} | format pattern "/ecosystems/{ecosystem_id}/categories/{id}/listings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List collections
#
# GET /ecosystems/{ecosystem_id}/collections
# operationId: collectionsAll
export def "collections-all" [
  ecosystem_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of records to return (default: 50)
]: nothing -> oneof<record<data: table<card_background_color: string, card_background_image: record, card_columns: int, card_style: string, count: int, description: string, hidden_from_homepage: bool, id: string, logo: record, name: string, sequence: int, show_max_items_homepage: int, slug: string, translations: list, visible: bool>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id)} | format pattern "/ecosystems/{ecosystem_id}/collections") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get collection
#
# GET /ecosystems/{ecosystem_id}/collections/{id}
# operationId: collectionsOne
export def "collections-one" [
  ecosystem_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<data: record<card_background_color: string, card_background_image: record<content_type: string, created_at: string, id: string, type: string, updated_at: string, url: string>, card_columns: int, card_style: string, count: int, description: string, hidden_from_homepage: bool, id: string, logo: record<content_type: string, created_at: string, id: string, type: string, updated_at: string, url: string>, name: string, sequence: int, show_max_items_homepage: int, slug: string, translations: list<record>, visible: bool>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id), id: (encode-path-segment $id)} | format pattern "/ecosystems/{ecosystem_id}/collections/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List collection listings
#
# GET /ecosystems/{ecosystem_id}/collections/{id}/listings
# operationId: collectionListingsAll
export def "collection-listings-all" [
  ecosystem_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of records to return (default: 50)
]: nothing -> oneof<record<data: table<automate_id: string, blendr_id: string, card_background_color: string, card_background_image: record, categories: list, cloud_service_id: string, collections: list, combidesk_id: string, created_at: string, description: string, detail_page_disabled: bool, external_id: string, features: string, id: string, integromat_id: string, logo: record, media: list, meta_tag_description: string, meta_tag_keywords: string, meta_tag_title: string, microsoft_flow_id: string, name: string, native_integration: bool, native_integration_link: string, partner: record, piesync_id: string, pricing: string, products: list, published: bool, published_at: string, screenshots: list, segment_id: string, slug: string, sticky: bool, tag_line: string, third_party_integration: bool, third_party_integration_link: string, translations: list, tray_io_id: string, unify_connector_id: string, upcoming: bool, updated_at: string, zapier_id: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id), id: (encode-path-segment $id)} | format pattern "/ecosystems/{ecosystem_id}/collections/{id}/listings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List listings
#
# GET /ecosystems/{ecosystem_id}/listings
# operationId: listingsAll
export def "listings-all" [
  ecosystem_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of records to return (default: 50)
  --external-id: string # Filter on external_id
]: nothing -> oneof<record<data: table<automate_id: string, blendr_id: string, card_background_color: string, card_background_image: record, categories: list, cloud_service_id: string, collections: list, combidesk_id: string, created_at: string, description: string, detail_page_disabled: bool, external_id: string, features: string, id: string, integromat_id: string, logo: record, media: list, meta_tag_description: string, meta_tag_keywords: string, meta_tag_title: string, microsoft_flow_id: string, name: string, native_integration: bool, native_integration_link: string, partner: record, piesync_id: string, pricing: string, products: list, published: bool, published_at: string, screenshots: list, segment_id: string, slug: string, sticky: bool, tag_line: string, third_party_integration: bool, third_party_integration_link: string, translations: list, tray_io_id: string, unify_connector_id: string, upcoming: bool, updated_at: string, zapier_id: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "external_id" $external_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id)} | format pattern "/ecosystems/{ecosystem_id}/listings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit, "external_id": $external_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get listing
#
# GET /ecosystems/{ecosystem_id}/listings/{id}
# operationId: listingsOne
export def "listings-one" [
  ecosystem_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<data: record<automate_id: string, blendr_id: string, card_background_color: string, card_background_image: record<content_type: string, created_at: string, id: string, type: string, updated_at: string, url: string>, categories: list<record>, cloud_service_id: string, collections: list<record>, combidesk_id: string, created_at: string, description: string, detail_page_disabled: bool, external_id: string, features: string, id: string, integromat_id: string, logo: record<content_type: string, id: string, type: string, url: string>, media: list<record>, meta_tag_description: string, meta_tag_keywords: string, meta_tag_title: string, microsoft_flow_id: string, name: string, native_integration: bool, native_integration_link: string, partner: record<company: string, contacts: list, created_at: string, icon: record, id: string, listed: string, twitter: string, updated_at: string, website: string>, piesync_id: string, pricing: string, products: list<record>, published: bool, published_at: string, screenshots: list<record>, segment_id: string, slug: string, sticky: bool, tag_line: string, third_party_integration: bool, third_party_integration_link: string, translations: list<record>, tray_io_id: string, unify_connector_id: string, upcoming: bool, updated_at: string, zapier_id: string>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id), id: (encode-path-segment $id)} | format pattern "/ecosystems/{ecosystem_id}/listings/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List products
#
# GET /ecosystems/{ecosystem_id}/products
# operationId: productsAll
export def "products-all" [
  ecosystem_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<data: table<count: int, description: string, id: string, logo: record, name: string, sequence: int, slug: string, translations: list, visible: bool>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id)} | format pattern "/ecosystems/{ecosystem_id}/products") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get product
#
# GET /ecosystems/{ecosystem_id}/products/{id}
# operationId: productsOne
export def "products-one" [
  ecosystem_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<record<data: record<count: int, description: string, id: string, logo: record<content_type: string, created_at: string, id: string, type: string, updated_at: string, url: string>, name: string, sequence: int, slug: string, translations: list<record>, visible: bool>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id), id: (encode-path-segment $id)} | format pattern "/ecosystems/{ecosystem_id}/products/{id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List product listings
#
# GET /ecosystems/{ecosystem_id}/products/{id}/listings
# operationId: productListingsAll
export def "product-listings-all" [
  ecosystem_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of records to return (default: 50)
]: nothing -> oneof<record<data: table<automate_id: string, blendr_id: string, card_background_color: string, card_background_image: record, categories: list, cloud_service_id: string, collections: list, combidesk_id: string, created_at: string, description: string, detail_page_disabled: bool, external_id: string, features: string, id: string, integromat_id: string, logo: record, media: list, meta_tag_description: string, meta_tag_keywords: string, meta_tag_title: string, microsoft_flow_id: string, name: string, native_integration: bool, native_integration_link: string, partner: record, piesync_id: string, pricing: string, products: list, published: bool, published_at: string, screenshots: list, segment_id: string, slug: string, sticky: bool, tag_line: string, third_party_integration: bool, third_party_integration_link: string, translations: list, tray_io_id: string, unify_connector_id: string, upcoming: bool, updated_at: string, zapier_id: string>, links: record<current: string, next: string, previous: string>, meta: record<cursors: record<current: string, next: string, previous: string>, items_on_page: int>, status: string, status_code: int>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($ecosystem_id | is-empty) { error make --unspanned { msg: "path parameter 'ecosystem_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ecosystem_id: (encode-path-segment $ecosystem_id), id: (encode-path-segment $id)} | format pattern "/ecosystems/{ecosystem_id}/products/{id}/listings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cursor": $cursor, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
