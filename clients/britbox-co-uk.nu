# Auto-generated client for Rocket Services v3.730.300-ref-1-39-0
# Source: https://api.apis.guru/v2/specs/britbox.co.uk/3.730.300-ref-1-39-0/openapi.json
# Auth: --token flag or $env.ROCKET_SERVICES_TOKEN

const BASE_URL = "http://localhost/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o ROCKET_SERVICES_TOKEN | default "" }
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://localhost/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["Card"] }
def resolution-completer [] { ["External" "HD-1080" "HD-4K" "HD-720" "SD"] }
def order-completer [] { ["asc" "desc"] }
def item-type-completer [] { ["channel" "customAsset" "episode" "link" "movie" "program" "season" "show" "trailer"] }
def show-item-type-completer [] { ["episode" "season" "show"] }
def expand-completer [] { ["ancestors" "parent"] }
def order-by-completer [] { ["date-added" "date-modified"] }
def cookie-type-completer [] { ["Persistent" "Session"] }
def provider-completer [] { ["Facebook"] }
def expand-completer-1 [] { ["all" "ancestors" "children" "parent"] }
def select-season-completer [] { ["first" "latest"] }
def item-detail-expand-completer [] { ["all" "ancestors" "children"] }
def item-detail-select-season-completer [] { ["first" "latest"] }
def text-entry-format-completer [] { ["html" "markdown"] }
def order-by-completer-1 [] { ["a-z" "date-added" "release-year"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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

# Get the details of an account along with the profiles and entitlements under it.
#
# GET /account
# operationId: getAccount
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<address: record<addressLine1: string, addressLine2: string, city: string, country: string, postcode: string, state: string>, defaultPaymentInstrumentId: string, defaultPaymentMethodId: string, emailVerified: bool, entitlements: table<deliveryType: string, exclusionRules: list, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list, activationDate: string, classification: record, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int>, firstName: string, id: string, isFirstTimeSubscriber: bool, lastName: string, marketingEnabled: bool, minRatingPlaybackGuard: string, pinEnabled: bool, primaryProfileId: string, profiles: table<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record, minRatingPlaybackGuard: record, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list>, segments: list<string>, subscriptionCode: string, subscriptions: table<code: string, endDate: string, id: string, isTrialPeriod: bool, planId: string, startDate: string, status: string>, trackingEnabled: bool, usedFreeTrial: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the details of an account. With the exception of the address, this supports partial updates, so you can send just the properties you wish to update. When the address is provided any properties which are omitted from the address will be cleared.
#
# PATCH /account
# operationId: updateAccount
# --address shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postcode?: string, state?: string}
export def "account update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --address: record # shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, postcode?: string, state?: string}
  --default-payment-instrument-id: string # The id of the payment instrument to use by default for account transactions. **DEPRECATED** The property `defaultPaymentMethodId` is now preferred.
  --default-payment-method-id: string # The id of the payment method to use by default for account transactions.
  --first-name: string # The first name of the account holder.
  --last-name: string # The last name of the account holder.
  --min-rating-playback-guard: string # The classification rating defining the minimum rating level a user should be forced to enter the account pin code for playback. Anything at this rating level or above will require the pin for playback. e.g. AUOFLC-MA15+ If you want to disable this guard pass an empty string or `null`.
  --segments: list<string> # The segments an account should be placed under
  --tracking-enabled: oneof<nothing, bool> # Whether usage tracking is associated with an account or anonymous.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account" $qp $auth.query)
  let req_body = {"address": $address, "defaultPaymentInstrumentId": $default_payment_instrument_id, "defaultPaymentMethodId": $default_payment_method_id, "firstName": $first_name, "lastName": $last_name, "minRatingPlaybackGuard": $min_rating_playback_guard, "segments": $segments, "trackingEnabled": $tracking_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get the available payment methods under an account.
#
# GET /account/billing/methods
# operationId: getPaymentMethods
export def "account-billing-methods list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> table<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/billing/methods" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add a new payment method to an account.
#
# POST /account/billing/methods
# operationId: addPaymentMethod
export def "account-billing-methods create-payment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --make-default: oneof<nothing, bool> # Whether this payment method should become the account default when making purchases. Note that if this is the first payment method of type Card being added to an account then it will become the default whether this property is true or false.
  --body-token: string # The payment provider token representing a payment method, obtained by submitting payment method details to your third party provider.
  type: string@type-completer # The type of payment method.
]: any -> record<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/billing/methods" $qp $auth.query)
  let req_body = {"makeDefault": $make_default, "token": $body_token, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Remove a payment method from an account.
#
# DELETE /account/billing/methods/{id}
# operationId: removePaymentMethod
export def "account-billing-methods delete-payment" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/billing/methods/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a payment method under an account.
#
# GET /account/billing/methods/{id}
# operationId: getPaymentMethod
export def "account-billing-methods get-payment" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<balance: float, brand: string, currency: string, description: string, expiryMonth: float, expiryYear: float, id: string, lastDigits: float, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/billing/methods/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of all purchases made under an account.
#
# GET /account/billing/purchases
# operationId: getPurchases
export def "account-billing-purchases get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> table<authorizationDate: string, creationDate: string, currency: string, id: string, item: record<id: string, ownership: string, resolution: string, title: string, type: string>, paymentMethodId: string, plan: record<id: string, price: float, subscriptionId: string, title: string, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/billing/purchases" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Purchase a plan or item offer. The result of a successful transaction is a new entitlement.
#
# POST /account/billing/purchases
# operationId: makePurchase
export def "account-billing-purchases create-make" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --item-id: string # The identifier of the item to purchase. Both `itemId` and `offerId` are required for item purchases.
  --offer-id: string # The identifier of the item offer to purchase. Both `itemId` and `offerId` are required for item purchases.
  --payment-method-id: string # The identifier of the payment method to use. If omitted, or if purchasing a plan, the default payment method will be used.
  --plan-id: string # The identifier of the plan to purchase.
]: any -> record<deliveryType: string, exclusionRules: table<description: string, device: string, excludeAirplay: bool, excludeChromecast: bool, excludeDelivery: string, excludeMinResolution: string>, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list<string>, activationDate: string, classification: record<code: string, name: string>, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/billing/purchases" $qp $auth.query)
  let req_body = {"itemId": $item_id, "offerId": $offer_id, "paymentMethodId": $payment_method_id, "planId": $plan_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancel a plan subscription. A cancelled subscription will continue to be valid until the subscription expiry date or next renewal date.
#
# DELETE /account/billing/subscriptions/{id}
# operationId: cancelSubscription
export def "account-billing-subscriptions cancel" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/billing/subscriptions/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Renew a cancelled subscription or switch subscription to a different plan. When renewing a cancelled subscription membership, hit this endpoint with the id of subscription to renew. To switch plans provide the id of the current active subscription membership of the account, and in the query specify the id of the plan to switch to.
#
# PUT /account/billing/subscriptions/{id}
# operationId: updateSubscription
export def "account-billing-subscriptions update" [
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
  --plan-id: string # The id of the plan to switch to if switching plans.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/billing/subscriptions/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"planId": $plan_id, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Get all devices registered under this account. Also includes information around device registration and deregistration limits.
#
# GET /account/devices
# operationId: getDevices
export def "account-devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<deregistrationWindow: record<endDate: string, limit: int, periodDays: int, remaining: int, startDate: string>, devices: table<id: string, name: string, registrationDate: string, type: string>, maxRegistered: int, registrationWindow: record<endDate: string, limit: int, periodDays: int, remaining: int, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/devices" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Register a playback device under an account. If a device with the same id already exists a `409` conflict will be returned.
#
# POST /account/devices
# operationId: registerDevice
export def "account-devices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  id: string # The unique identifier for this device e.g. serial number.
  name: string # A human recognisable name for this device.
  type: string # The device type e.g. web_browser.
]: any -> record<id: string, name: string, registrationDate: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/devices" $qp $auth.query)
  let req_body = {"id": $id, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Authorize a device from a generated device authorization code. This is the second step in the process of authorizing a device by pin code. Firstly the device must request a generated authorization code via the `/authorization/device/code` endpoint. This endpoint then authorizes the device associated with the code to sign in to a user account. Typically this endpoint will be called from a page presented in the web app under the account section. Once authorized, the device will then be able to sign in to that account via the `/authorization/device` endpoint, without needing to provide the credentials of the user.
#
# POST /account/devices/authorization
# operationId: authorizeDevice
export def "account-devices-authorization create-authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  code: string # The generated device authorization code.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/devices/authorization" $qp $auth.query)
  let req_body = {"code": $code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Deregister a playback device from an account.
#
# DELETE /account/devices/{id}
# operationId: deregisterDevice
export def "account-devices delete-deregister" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/devices/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get a registered device.
#
# GET /account/devices/{id}
# operationId: getDevice
export def "account-devices get" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<id: string, name: string, registrationDate: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/devices/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Rename a device
#
# PUT /account/devices/{id}/name
# operationId: renameDevice
export def "account-devices-name rename" [
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
  --name: string # The new name for the device.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/devices/{id}/name") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"name": $name, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [204]
}

# Get all entitlements under the account. This list is returned under the call to get account information so a call here is only required when wishing to refresh a local copy of entitlements.
#
# GET /account/entitlements
# operationId: getEntitlements
export def "account-entitlements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> table<deliveryType: string, exclusionRules: list<record>, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list<string>, activationDate: string, classification: record<code: string, name: string>, creationDate: string, expirationDate: string, itemId: string, itemType: string, mediaDuration: int, planId: string, playCount: int, remainingDownloads: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/entitlements" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the video files associated with an item given maximum resolution, device type and one or more delivery types. This endpoint accepts an Account Catalog token, however if when requesting playback files you receive an *403 status code with error code 1* then the file you're requesting is classification restricted. This means you should switch to target the `/account/items/{id}/videos-guarded` endpoint, passing it an Account Playback token. If not already obtained, this token can be requested via the `/itv/pinauthorization` endpoint with an account level pin. For convenience you may also access free / public files through this endpoint instead of the /items/{id}/videos endpoint, when authenticated. Returns an array of video file objects which each include a url to a video. The first entry in the array contains what is predicted to be the best match. The remainder of the entries, if any, may contain resolutions below what was requests. For example if you request HD-720 the response may also contain SD entries. If you specify multiple delivery types, then the response array will insert types in the order you specify them in the query. For example `stream,progressive` would return an array with 0 or more stream files followed by 0 or more progressive files. If no files are found a 404 is returned.
#
# GET /account/items/{id}/videos
# operationId: getItemMediaFiles
export def "account-items-videos get-media-files" [
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
  --delivery: list<string> # The video delivery type you require.
  --resolution: string@resolution-completer # The maximum resolution the device to playback the media can present.
  --formats: list<string> # The set of media file formats that the device supports, in the order of preference. When provided, Rocket API returns only media files in formats specified in this parameter. For each resolution, only the first media file of matching supported format is returned. Files of different resolutions may be of different supported media file formats. `external` value is reserved for project customizations where the real MIME type of the file on the specified URL is unknown at the time of ingestion. When not provided, Rocket API uses the legacy `User-Agent` header-based logic to find matching media files.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "delivery" $delivery "csv") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "formats" $formats "csv") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/items/{id}/videos") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"delivery": $delivery, "resolution": $resolution, "formats": $formats, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the video files associated with an item given maximum resolution, device type and one or more delivery types. This endpoint is identical to the `/account/items/{id}/videos` however it expects an Account Playback token. This token, and in association this endpoint, is specifically for use when playback files are classification restricted and require an account level pin to access them. Returns an array of video file objects which each include a url to a video. The first entry in the array contains what is predicted to be the best match. The remainder of the entries, if any, may contain resolutions below what was requests. For example if you request HD-720 the response may also contain SD entries. If you specify multiple delivery types, then the response array will insert types in the order you specify them in the query. For example `stream,progressive` would return an array with 0 or more stream files followed by 0 or more progressive files. If no files are found a 404 is returned.
#
# GET /account/items/{id}/videos-guarded
# operationId: getItemMediaFilesGuarded
export def "account-items-videos-guarded get-media-files" [
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
  --delivery: list<string> # The video delivery type you require.
  --resolution: string@resolution-completer # The maximum resolution the device to playback the media can present.
  --formats: list<string> # The set of media file formats that the device supports, in the order of preference. When provided, Rocket API returns only media files in formats specified in this parameter. For each resolution, only the first media file of matching supported format is returned. Files of different resolutions may be of different supported media file formats. `external` value is reserved for project customizations where the real MIME type of the file on the specified URL is unknown at the time of ingestion. When not provided, Rocket API uses the legacy `User-Agent` header-based logic to find matching media files.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "delivery" $delivery "csv") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "formats" $formats "csv") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/items/{id}/videos-guarded") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"delivery": $delivery, "resolution": $resolution, "formats": $formats, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Generate a new account nonce. A nonce may be required to help sign a response from a third party service which will be passed back to these services. For example a Facebook single-sign-on request initiated by a client application may first get a nonce from here to include in the request. Facebook will then include the nonce in the auth token it issues. This token can be passed back to our services and the nonce checked for validity.
#
# GET /account/nonce
# operationId: generateNonce
export def "account-nonce generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/nonce" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Change the password of an account. The expected token scope is Settings.
#
# PUT /account/password
# operationId: changePassword
export def "account-password update-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  password: string # The new password for the account.
  profile_token: string # The ITV profile token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/password" $qp $auth.query)
  let req_body = {"password": $password, "profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Change the pin of an account.
#
# PUT /account/pin
# operationId: changePin
export def "account-pin update-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  pin: string # The new pin to set.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/pin" $qp $auth.query)
  let req_body = {"pin": $pin} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get the details of the active profile, including watched, bookmarked and rated items.
#
# GET /account/profile
# operationId: getProfile
export def "account-profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>, bookmarked: record, rated: record, watched: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the map of bookmarked item ids (itemId => creationDate) under the active profile.
#
# GET /account/profile/bookmarks
# operationId: getBookmarks
export def "account-profile-bookmarks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile/bookmarks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the list of bookmarked items under the active profile.
#
# GET /account/profile/bookmarks/list
# operationId: getBookmarkList
export def "account-profile-bookmarks-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of items to load. Starts from page 1. (format: int32)
  --page-size: int # The number of items to return in a page. (format: int32)
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "item_type" $item_type "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile/bookmarks/list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "page_size": $page_size, "order": $order, "item_type": $item_type, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Unbookmark an item under the active profile.
#
# DELETE /account/profile/bookmarks/{itemId}
# operationId: deleteItemBookmark
export def "account-profile-bookmarks delete-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/account/profile/bookmarks/{item_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the bookmark for an item under the active profile.
#
# GET /account/profile/bookmarks/{itemId}
# operationId: getItemBookmark
export def "account-profile-bookmarks get-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<creationDate: string, itemId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/account/profile/bookmarks/{item_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Bookmark an item under the active profile. Creates one if it doesn't exist, overwrites one if it does.
#
# PUT /account/profile/bookmarks/{itemId}
# operationId: bookmarkItem
export def "account-profile-bookmarks update-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<creationDate: string, itemId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/account/profile/bookmarks/{item_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Returns a list of items which have been watched but not completed under the active profile. Multiple episodes under the same show may be watched or in progress, however only a single item belonging to a particular show will be included in the returned list. The next episode to continue watching for a particular show will be the most recent incompletely watched episode, or the next episode following the most recently completely watched episode. Based on the specified `show_item_type` type, either the next episode, the season of the next episode, or the show will be included in the list.
#
# GET /account/profile/continue-watching/list
# operationId: getContinueWatchingList
export def "account-profile-continue-watching-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-item-type: string@show-item-type-completer # The item type to be returned for continue watching items belonging to a show. Multiple episodes under the same show may be watched or in progress, however only a single item belonging to a particular show will be included in the returned list. The next episode to continue watching for a particular show will be the most recent incompletely watched episode, or the next episode following the most recently completely watched episode. Based on the specified `show_item_type` type, either the next episode, the season of the next episode, or the show will be included in the list. If `episode` is specified, then only the next episode to continue watching for a show will be returned. If `season` is specified, then only the season of the next episode will be returned. If `show` is specified, then only the show of the next episode will be returned The recommended value of this parameter should reflect the desitination the user will be sent to when they select this item in the list. So if a user will be sent to the show detail page then this should be `show` and you can use the `include` parameter to get metadata about the episode or season if needed (default: episode)
  --include: list<string> # Include one opr more ancestor/children for items belonging to a show. Extra items will be populated in the `listData` property of the list If no value is specified no dependencies are included. If `episode` is specified, then the next episode will be added for season/show items. Has no effect if `show_item_type` is set to `episode`. If `season` is specified, then the season of the next episode will be added for episode/show items. Has no effect if `show_item_type` is set to `season`. If `show` is specified, then the show of the next episode will be added for episode/season items. Has no effect if `show_item_type` is set to `show`. (default: [])
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of an item returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_item_type" $show_item_type "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile/continue-watching/list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"show_item_type": $show_item_type, "include": $include, "page": $page, "page_size": $page_size, "max_rating": $max_rating, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the next item to play given a source item id. For an unwatched show it returns the first episode available to the account. For a watched show it returns the last incompletely watched episode by the profile, or the episode that immediately follows the last completely watched episode or nothing. For an episode it always returns the immediately following episode, if available to the account, or nothing. If the response does not contain a `next` property then no item was found.
#
# GET /account/profile/items/{itemId}/next
# operationId: getNextPlaybackItem
export def "account-profile-items-next get-playback" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-rating: string # The maximum rating (inclusive) of an item returned, e.g. 'auoflc-pg'.
  --expand: string@expand-completer # If no value is specified no dependencies are expanded. If 'parent' is specified then only the direct parent will be expanded. For example if an `Episode` then the `Season` would be included. If 'ancestors' is specified then the full parent chain is expanded. For example if an `Episode` then both the `Season` and `Show` would be included.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<firstWatchedDate: string, lastWatchedDate: string, next: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, sourceItemId: string, suggestionType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/account/profile/items/{item_id}/next") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max_rating": $max_rating, "expand": $expand, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the map of rated item ids (itemId => rating out of 10) under the active profile.
#
# GET /account/profile/ratings
# operationId: getRatings
export def "account-profile-ratings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile/ratings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the list of rated items under the active profile.
#
# GET /account/profile/ratings/list
# operationId: getRatingsList
export def "account-profile-ratings-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --order-by: string@order-by-completer # What to order by. Ordering by `date-modified` equates to ordering by the last rated date. (default: date-added)
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "item_type" $item_type "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile/ratings/list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "page_size": $page_size, "order": $order, "order_by": $order_by, "item_type": $item_type, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the rating info for an item under the active profile.
#
# GET /account/profile/ratings/{itemId}
# operationId: getItemRating
export def "account-profile-ratings get-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<itemId: string, rating: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/account/profile/ratings/{item_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Rate an item under the active profile. Creates one if it doesn't exist, overwrites one if it does.
#
# PUT /account/profile/ratings/{itemId}
# operationId: rateItem
export def "account-profile-ratings update-rate-item" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rating: int # The item rating between 1 and 10 inclusive. (format: int32)
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<itemId: string, rating: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "rating" $rating "scalar") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/account/profile/ratings/{item_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"rating": $rating, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Remove the watched status of items under the active profile. Passing in specific `itemId`s to the `item_ids` query parameter will cause only these items to be removed. **If this list is missing all watched items will be removed**
#
# DELETE /account/profile/watched
# operationId: deleteWatched
export def "account-profile-watched delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-ids: list<string> # List of `itemId`s to delete. Omit this parameter to delete all items
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "item_ids" $item_ids "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile/watched" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"item_ids": $item_ids, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the map of watched item ids (itemId => last playhead position) under the active profile.
#
# GET /account/profile/watched
# operationId: getWatched
export def "account-profile-watched get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile/watched" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the list of watched items under the active profile.
#
# GET /account/profile/watched/list
# operationId: getWatchedList
export def "account-profile-watched-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --completed: oneof<nothing, bool> # Filter by whether an item has been fully watched (completed) or not. If `undefined` then both partially and fully watched items are returned.
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --order-by: string@order-by-completer # What to order by. Ordering by `date-modified` equates to ordering by the last watched date. (default: date-added)
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "completed" $completed "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "item_type" $item_type "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profile/watched/list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "page_size": $page_size, "completed": $completed, "order": $order, "order_by": $order_by, "item_type": $item_type, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the watched status info for an item under the active profile.
#
# GET /account/profile/watched/{itemId}
# operationId: getItemWatchedStatus
export def "account-profile-watched get-item-status" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<firstWatchedDate: string, isFullyWatched: bool, itemId: string, lastWatchedDate: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/account/profile/watched/{item_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Record the watched playhead position of a video under the active profile. Can be used later to resume a video from where it was last watched. Creates one if it doesn't exist, overwrites one if it does.
#
# PUT /account/profile/watched/{itemId}
# operationId: setItemWatchedStatus
export def "account-profile-watched update-item-status" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --position: int # The playhead position to record. (format: int32)
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<firstWatchedDate: string, isFullyWatched: bool, itemId: string, lastWatchedDate: string, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "position" $position "scalar") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/account/profile/watched/{item_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"position": $position, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200 204]
}

# Create a new profile under the active account.
#
# POST /account/profiles
# operationId: createProfile
export def "account-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --language-code: string # The code of the preferred language for the profile. Must be a valid ISO language code e.g. "en-US" and must match the code of one of the languages specified in the app config. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  name: string # The unique name of the profile.
  --pin-enabled: oneof<nothing, bool> # Whether an account pin is required to enter the profile. If no account pin is defined this has no impact. (default: false)
  --purchase-enabled: oneof<nothing, bool> # Whether the profile can make purchases with the account payment options. (default: true)
  --segments: list<string> # The segments a profile should be placed under
]: any -> record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>, bookmarked: record, rated: record, watched: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/profiles" $qp $auth.query)
  let req_body = {"languageCode": $language_code, "name": $name, "pinEnabled": $pin_enabled, "purchaseEnabled": $purchase_enabled, "segments": $segments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete a profile with a specific id under the active account. Note that you cannot delete the primary profile.
#
# DELETE /account/profiles/{id}
# operationId: deleteProfileWithId
export def "account-profiles delete" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/profiles/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the summary of a profile with a specific id under the active account.
#
# GET /account/profiles/{id}
# operationId: getProfileWithId
export def "account-profiles get" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<color: string, heroAutoplay: bool, heroWithAudio: bool, id: string, isActive: bool, languageCode: string, marketingEnabled: bool, maxRatingContentFilter: record<code: string, name: string>, minRatingPlaybackGuard: record<code: string, name: string>, name: string, pinEnabled: bool, purchaseEnabled: bool, segments: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/profiles/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update the summary of a profile with a specific id under the active account. This supports partial updates so you can send just the properties you wish to update.
#
# PATCH /account/profiles/{id}
# operationId: updateProfileWithId
export def "account-profiles update" [
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
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --hero-autoplay: oneof<nothing, bool> # Sets the Hero row clip auto playback enabled
  --hero-with-audio: oneof<nothing, bool> # Sets the Hero row clip auto playback audio enabled
  --language-code: string # The code of the preferred language for the profile. Must be a valid ISO language code e.g. "en-US" and must match the code of one of the languages specified in the app config. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --name: string # The unique name of the profile.
  --pin-enabled: oneof<nothing, bool> # Whether an account pin is required to enter the profile. If no account pin is defined this has no impact.
  --purchase-enabled: oneof<nothing, bool> # Whether the profile can make purchases with the account payment options.
  --segments: list<string> # The segments a profile should be placed under
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/account/profiles/{id}") $qp $auth.query)
  let req_body = {"heroAutoplay": $hero_autoplay, "heroWithAudio": $hero_with_audio, "languageCode": $language_code, "name": $name, "pinEnabled": $pin_enabled, "purchaseEnabled": $purchase_enabled, "segments": $segments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [204]
}

# Request that the email address tied to an account be verified. This will send a verification email to the email address of the primary profile containing a link which, once clicked, completes the verification process via the /verify-email endpoint. Note that when an account is created this email is sent automatically so there's no need to call this directly. If the user doesn't click the link before it expires then this endpoint can be called to request a new verification email. In the future it may also be used if we add support for changing an account email address.
#
# POST /account/request-email-verification
# operationId: requestEmailVerification
export def "account-request-email-verification request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/request-email-verification" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}

# When a user signs out of an application we need to clear some basic cookies we assigned them during token authorization.
#
# DELETE /authorization
# operationId: signOut
export def "authorization delete-sign-out" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Request one or more `Account` level authorization tokens each with a chosen scope. Tokens are used to access restricted service endpoints. These restricted endpoints will require a specific token type (e.g Account) with a specific scope (e.g. Catalog) before access is granted. For convenience, where a Profile level token with the same scope exists it will also be returned. Authorization with pin is not supported on this endpoint anymore. Use `/itv/pinauthorization` endpoint instead.
#
# POST /authorization
# operationId: getAccountToken
export def "authorization get-account-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  email: string # The email associated with the account.
  password: string # The password associated with the account.
  scopes: list<string> # The scope(s) of the tokens required. For each scope listed an Account and Profile token of that scope will be returned
]: any -> table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization" $qp $auth.query)
  let req_body = {"cookieType": $cookie_type, "email": $email, "password": $password, "scopes": $scopes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Catalog tokens for an account using a device authorization code. Where a Profile level token of Catalog scope exists it will also be returned. This is the final step in the process of authorizing a device by pin code. Firstly the device must request a generated authorization code via the `/authorization/device/code` endpoint. The code is subsequently used to authorize the device to sign in to a given account via the `/account/devices/authorization` endpoint. Typically this will be from a page presented in the web app under the account section. Once authorized, this endpoint will allow the device to sign in without needing to provide the credentials of the user.
#
# POST /authorization/device
# operationId: getAccountTokenByCode
export def "authorization-device get-account-token-by-code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  code: string # The generated device authorization code.
  id: string # The unique identifier for the device e.g. serial number.
  scopes: list<string> # The scope(s) of the token(s) required.
]: any -> table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization/device" $qp $auth.query)
  let req_body = {"code": $code, "id": $id, "scopes": $scopes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get a generated device authorization code. This is the first step in the process of authorizing a device by pin code. The device will make a request to this endpoint providing a unique identifier for the device such as a serial number. This endpoint will then return a generated code which is tied to the given device. The code may subsequently be used to authorize the device to sign in to an account via the `/account/devices/authorization` endpoint. Typically this will be from a page presented in the web app under the account section. Once authorized, the device will then be able to sign in to that account via the `/authorization/device` endpoint, without needing to provide the credentials of the user.
#
# POST /authorization/device/code
# operationId: generateDeviceAuthorizationCode
export def "authorization-device-code generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  id: string # The unique identifier for this device e.g. serial number.
  name: string # A human recognisable name for this device.
  type: string # The device type e.g. web_browser.
]: any -> record<code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization/device/code" $qp $auth.query)
  let req_body = {"id": $id, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Request one or more `Profile` level authorization tokens each with a chosen scope. Tokens are used to access restricted service endpoints. These restriced endpoints will require a specific token type (e.g Profile) with a specific scope (e.g. Catalog) before access is granted.
#
# POST /authorization/profile
# operationId: getProfileToken
export def "authorization-profile get-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  --pin: string # The pin associated with this profile, if any.
  profile_id: string # The id of the profile the token should grant access rights to.
  scopes: list<string> # The scope(s) of the token(s) required.
]: any -> table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization/profile" $qp $auth.query)
  let req_body = {"cookieType": $cookie_type, "pin": $pin, "profileId": $profile_id, "scopes": $scopes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Refresh an account or profile level authorization token which is marked as refreshable.
#
# POST /authorization/refresh
# operationId: refreshToken
export def "authorization-refresh refresh-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  --body-token: string # The token to refresh.
]: any -> record<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization/refresh" $qp $auth.query)
  let req_body = {"cookieType": $cookie_type, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Exchange a third party single-sign-on token for our own authorization tokens.
#
# POST /authorization/sso
# operationId: singleSignOn
export def "authorization-sso create-single-sign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  --link-accounts: oneof<nothing, bool> # When a user attempts to sign in using single-sign-on, we may find an account created previously through the manual sign up flow with the same email. If this is the case then an option to link the two accounts can be made available. If this flag is set to true then accounts will be linked automatically. If this flag is not set or set to false and an existing account is found then an http 401 with subcode `6001` will be returned. Client apps can then present the option to link the accounts. If the user decides to accept, then the same call can be repeated with this flag set to true.
  provider: string@provider-completer # The third party single-sign-on provider.
  --scopes: list<string> # The scope(s) of the tokens required. For each scope listed an Account and Profile token of that scope will be returned.
  --body-token: string # A token from the third party single-sign-on provider e.g. an identity token from Facebook.
]: any -> table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authorization/sso" $qp $auth.query)
  let req_body = {"cookieType": $cookie_type, "linkAccounts": $link_accounts, "provider": $provider, "scopes": $scopes, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all the plans available for BT flow including additional description data.
#
# GET /bt/plan/{token}
# operationId: getPlanByToken
export def "bt-plan get" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<amount: float, ctaText: string, currency: string, description: string, ees07PlanDescription: string, ees07PlanTitle: string, ees07Title: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, noThanksText: string, product: string, switchingText: string, termsAndConditionsItunes: string, termsAndConditionsStripe: string, trialPeriodDays: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($token_arg | is-empty) { error make --unspanned { msg: "path parameter 'token' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: (encode-path-segment $token_arg)} | format pattern "/bt/plan/{token_arg}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns all the plans available for BT flow including additional description data.
#
# GET /bt/plans
# operationId: getPlans
export def "bt-plans get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<plans: table<amount: float, ctaText: string, currency: string, description: string, ees07PlanDescription: string, ees07PlanTitle: string, ees07Title: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, noThanksText: string, product: string, switchingText: string, termsAndConditionsItunes: string, termsAndConditionsStripe: string, trialPeriodDays: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bt/plans" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Assigns an UserToken to a profile on the ITV side. Currently throws an exception.
#
# POST /bt/token/assign
# operationId: assignToken
export def "bt-token-assign assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token
  --body-token: string # The validated userToken.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bt/token/assign" $qp $auth.query)
  let req_body = {"profileToken": $profile_token, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Checks a provided token for BT eligible user.
#
# GET /bt/token/validate
# operationId: checkUserToken
export def "bt-token-validate check-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # User token provided by BT.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bt/token/validate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the details of subscription data for a user with specified id.
#
# GET /check-subscription/{id}
# operationId: getSubscriptionData
export def "check-subscription get-data" [
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
]: nothing -> record<itvData_purchased: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/check-subscription/{id}") $auth.query)
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

# Get the global configuration for an application. Should be called during app statup. This includes things like device and playback rules, classifications, sitemap and subscriptions. You have the option to select specific configuration objects using the 'include' parameter, or if unspecified, getting all configuration.
#
# GET /config
# operationId: getAppConfig
export def "config get-app" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: list<string> # A comma delimited list of config objects to return. If none specified then all configuration is returned.
  --system: string # Classification system to load in case include = classification.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<classification: record, display: record<themes: list<record>>, general: record<currencyCode: string, customFields: record, defaultTimeZone: string, facebookAppId: string, gaToken: string, itemImageTypes: record, mandatorySignIn: bool, maxUserRating: int, stripeKey: string, websiteUrl: string>, i18n: record<languages: list<record>>, linear: record<scheduleCacheMaxAgeMinutes: int, viewingWindowDaysAfter: int, viewingWindowDaysBefore: int>, navigation: record<account: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>, copyright: string, customFields: record, footer: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>, header: list<record>, mobile: record<children: list, content: record, customFields: record, depth: int, featured: bool, icon: string, label: string, path: string>>, playback: record<chainPlayCountdown: int, chainPlaySqueezeback: int, chainPlayTimeout: int, heartbeatFrequency: int, viewEventPoints: list<float>>, sitemap: table<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string>, subscription: record<plans: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "csv") (serialize-qp "system" $system "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/config" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include": $include, "system": $system, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Check whether or not a user is eligible for switching to Bt or EE offers.
#
# GET /ee-bt/eligibility
# operationId: checkEeBtEligibility
export def "ee-bt-eligibility check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<eligible: bool, plan: string, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ee-bt/eligibility" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Assigns a msisdn to a profile on ITV side.
#
# POST /ee/msisdn
# operationId: assignMsisdn
export def "ee-msisdn assign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  ee_product_id: string # Product id from /ee/offers
  msisdn: string # The validated msisdn.
  profile_token: string # The ITV profile token
  tracking_header: string # trackingHeader
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ee/msisdn" $qp $auth.query)
  let req_body = {"eeProductId": $ee_product_id, "msisdn": $msisdn, "profileToken": $profile_token, "trackingHeader": $tracking_header} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Returns eligible partner specific offers for the querying partner for an EE MSISDN. This call is supposed to be called after we have MSISDN accired. This call should be followed by POST /ee/msisdn.
#
# POST /ee/offers
# operationId: getEligibleOffers
export def "ee-offers get-eligible" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  access_token: string # EE API authorization Token received from GET /ee/token/create.
  msisdn: string # The msisdn.
  --tracking-header: string # trackingHeader.
]: any -> record<eligibleOffers: table<name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ee/offers" $qp $auth.query)
  let req_body = {"accessToken": $access_token, "msisdn": $msisdn, "trackingHeader": $tracking_header} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Validate PIN request created by calling POST /ee/pin This call is to validate MSISDN entered by a user not comming through EE network. This call should be called after PUT /ee/pin. This call should be followed by POST /ee/offers.
#
# POST /ee/pin
# operationId: validatePinRequest
export def "ee-pin validate-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  access_token: string # EE API authorization Token received from GET /ee/token/create.
  pin: string # The pin entered by a user. 6 digits
  pin_reference: string # The pinReference.
  --tracking-header: string # Tracking header to be able to search logs for a specific user requests. If not provided it will be generated. FE should store it for later user.
]: any -> record<pinValid: string, trackingHeader: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ee/pin" $qp $auth.query)
  let req_body = {"accessToken": $access_token, "pin": $pin, "pinReference": $pin_reference, "trackingHeader": $tracking_header} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Creates a PIN request that will send an SMS to the given msisdn. This call is to validate MSISDN entered by a user not comming through EE network. This call should be followed by POST ee/pin.
#
# PUT /ee/pin
# operationId: createPinRequest
export def "ee-pin create-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  access_token: string # EE API authorization Token received from GET /ee/token/create.
  msisdn: string # The msisdn.
  --tracking-header: string # trackingHeader
]: any -> record<pinReference: string, trackingHeader: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ee/pin" $qp $auth.query)
  let req_body = {"accessToken": $access_token, "msisdn": $msisdn, "trackingHeader": $tracking_header} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns all the plans available for EE flow including additional description data.
#
# GET /ee/plans
export def "ee-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<plans: table<amount: float, ctaText: string, currency: string, description: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, product: string, trialPeriodDays: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ee/plans" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the plan description for EE flow including additional description data.
#
# GET /ee/plans/{id}
# operationId: getPlan
export def "ee-plans get" [
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
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<amount: float, ctaText: string, currency: string, description: string, headerText: string, heroText: string, id: string, interval: string, intervalCount: int, longText: string, nickname: string, product: string, trialPeriodDays: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ee/plans/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a token for later calls to EE API. TTL is one hour. Recommended is FE refreshes this token before each call.
#
# GET /ee/token/create
# operationId: createToken
export def "ee-token-create create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accessToken: string, expiresIn: float, tokenType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ee/token/create" $auth.query)
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

# Returns the details of an item with the specified id.
#
# GET /items/{id}
# operationId: getItem
export def "items get" [
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
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --expand: string@expand-completer-1 # If no value is specified no dependencies are expanded. If 'children' is specified then the list of any direct children will be expanded. For example seasons of a show or episodes of a season. If 'all' is specified then the parent chain will be expanded along with any child list at each level. For example if an episode is specified then its season will be expanded and that season's episode list. The season will have its show expanded and the show will have its season list expanded. The 'all' options is useful when you deep link into a show/season/episode for the first time as it provides full context for navigating around the show page. Subsequent navigation around children of the show should only need to request expand of children. If 'ancestors' is specified then only the parent chain is included. If 'parent' is specified then only the direct parent is included. If an expand is specified which is not relevant to the item type, it will be ignored.
  --select-season: string@select-season-completer # Given a provided show id, it can be useful to get the details of a child season. This option provides a means to return the `first` or `latest` season of a show given the show id. The `expand` parameter also works here so for example you could land on a show page and request the latest season along with `expand=all`. This would then return the detail of the latest season with its list of child episode summaries, and also expand the detail of the show with its list of seasons summaries. Note the `id` parameter must be a show id for this parameter to work correctly.
  --use-custom-id: oneof<nothing, bool> # Set to true when passing a custom Id as the `id` path parameter.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: table<deliveryType: string, exclusionRules: list, maxDownloads: int, maxPlays: int, ownership: string, playPeriod: int, rentalPeriod: int, resolution: string, scopes: list, availability: string, customFields: record, endDate: string, id: string, name: string, price: float, startDate: string, subscriptionCode: string>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: table<colors: list, type: string>, title: string, type: string, watchPath: string, copyright: string, credits: table<name: string, path: string, character: string, role: string>, customMetadata: table<name: string, value: string>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, show: any, totalUserRatings: int, trailers: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, venue: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "select_season" $select_season "scalar") (serialize-qp "use_custom_id" $use_custom_id "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/items/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max_rating": $max_rating, "expand": $expand, "select_season": $select_season, "use_custom_id": $use_custom_id, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the List of child summary items under an item. If the item is a Season then the children will be episodes and ordered by episode number. If the item is a Show then the children will be Seasons and ordered by season number. Returns 404 if no children found.
#
# GET /items/{id}/children
# operationId: getItemChildrenList
export def "items-children get-list" [
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
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/items/{id}/children") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "page_size": $page_size, "max_rating": $max_rating, "order": $order, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the list of items related to the parent item. Note for now, due to the size of the list being unknown, only a single page will be returned.
#
# GET /items/{id}/related
# operationId: getItemRelatedList
export def "items-related get-list" [
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
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/items/{id}/related") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "page_size": $page_size, "max_rating": $max_rating, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the free / public video files associated with an item given maximum resolution, device type and one or more delivery types. Returns an array of video file objects which each include a url to a video. The first entry in the array contains what is predicted to be the best match. The remainder of the entries, if any, may contain resolutions below what was requests. For example if you request HD-720 the response may also contain SD entries. If you specify multiple delivery types, then the response array will insert types in the order you specify them in the query. For example `stream,progressive` would return an array with 0 or more stream files followed by 0 or more progressive files. If no files are found a 404 is returned.
#
# GET /items/{id}/videos
# operationId: getPublicItemMediaFiles
export def "items-videos get-public-media-files" [
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
  --delivery: list<string> # The video delivery type you require.
  --resolution: string@resolution-completer # The maximum resolution the device to playback the media can present.
  --formats: list<string> # The set of media file formats that the device supports, in the order of preference. When provided, Rocket API returns only media files in formats specified in this parameter. For each resolution, only the first media file of matching supported format is returned. Files of different resolutions may be of different supported media file formats. `external` value is reserved for project customizations where the real MIME type of the file on the specified URL is unknown at the time of ingestion. When not provided, Rocket API uses the legacy `User-Agent` header-based logic to find matching media files.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> table<channels: int, deliveryType: string, drm: string, format: string, height: int, language: string, name: string, resolution: string, url: string, width: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "delivery" $delivery "csv") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "formats" $formats "csv") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/items/{id}/videos") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"delivery": $delivery, "resolution": $resolution, "formats": $formats, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Identical to GET /account/profile/items/{itemId}/next route but for users that are not logged in i.e. this endpoint does not require authorisation
#
# GET /items/{itemId}/next
# operationId: getAnonNextPlaybackItem
export def "items-next get-anon-playback" [
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-rating: string # The maximum rating (inclusive) of an item returned, e.g. 'auoflc-pg'.
  --expand: string@expand-completer # If no value is specified no dependencies are expanded. If 'parent' is specified then only the direct parent will be expanded. For example if an `Episode` then the `Season` would be included. If 'ancestors' is specified then the full parent chain is expanded. For example if an `Episode` then both the `Season` and `Show` would be included.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<firstWatchedDate: string, lastWatchedDate: string, next: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, sourceItemId: string, suggestionType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($item_id | is-empty) { error make --unspanned { msg: "path parameter 'itemId' must be non-empty" } }
  let qp = [(serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({item_id: (encode-path-segment $item_id)} | format pattern "/items/{item_id}/next") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max_rating": $max_rating, "expand": $expand, "device": $device, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the list of billing records for specified payment platform.
#
# POST /itv/billinghistory/{platform}
# operationId: getBillingHistory
export def "itv-billinghistory get-billing-history" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> record<payment_history: table<card: record, charge: record, invoice: record, subscription: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/billinghistory/{platform}") $qp $auth.query)
  let req_body = {"profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get payment card details.
#
# POST /itv/cards/{platform}
# operationId: getCardDetails
export def "itv-cards get-details" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> record<card_type: string, exp_month: int, exp_year: int, last4: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/cards/{platform}") $qp $auth.query)
  let req_body = {"profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Change payment card details.
#
# PUT /itv/cards/{platform}
# operationId: changeCardDetails
export def "itv-cards update-change-details" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  card_token: string # The credit card token.
  profile_token: string # The ITV profile token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/cards/{platform}") $qp $auth.query)
  let req_body = {"cardToken": $card_token, "profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Change email address related to account/profile. The expected token scope is Settings.
#
# POST /itv/changeemail
# operationId: changeEmail
export def "itv-changeemail create-change-email" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  email: string # New email address for account/profile.
  profile_token: string # The ITV profile token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/changeemail" $qp $auth.query)
  let req_body = {"email": $email, "profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Change marketing preferences related to account/profile. The expected token scope is Settings.
#
# POST /itv/changemarketing
# operationId: changeMarketing
export def "itv-changemarketing create-change-marketing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --email-opt-in: oneof<nothing, bool> # Updated marketing preferences for account/profile.
  profile_token: string # The ITV profile token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/changemarketing" $qp $auth.query)
  let req_body = {"emailOptIn": $email_opt_in, "profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Delete account in compliance with GDPR. The expected token scope is Settings.
#
# POST /itv/deleteaccount
# operationId: deleteAccount
export def "itv-delete-account delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/deleteaccount" $qp $auth.query)
  let req_body = {"profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns current entitlement.
#
# GET /itv/entitlements/current
# operationId: getCurrentEntitlement
export def "itv-entitlements-current get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/entitlements/current" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the state of subscription for any payment platform.
#
# GET /itv/entitlements/history
# operationId: getEntitlementsHistory
export def "itv-entitlements-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<cancellations: table<cancelled_at: string, itvId: string, source: string, subscriptionId: string>, entitlements: table<card_type: string, expiry: string, plan: record, source: string, subscriptionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/entitlements/history" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets info whether or not a feature is enabled or disabled using a feature flag. Feature flags are set as a custom field within PM. It also supports custom feature flag data if needed. Such data can be return as well.
#
# GET /itv/featureFlag/{feature}
# operationId: getFeatureFlag
export def "itv-feature-flag get" [
  feature: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<enabled: bool, flag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($feature | is-empty) { error make --unspanned { msg: "path parameter 'feature' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({feature: (encode-path-segment $feature)} | format pattern "/itv/featureFlag/{feature}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the list of recommended items under the active profile.
#
# POST /itv/googlepay/subscription
# operationId: googlePaySubscription
export def "itv-googlepay-subscription create-google-pay" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  purchase_token: string # the unique identifier for this purchase
  subscription_item: string # the SKU of the item from the play console
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/googlepay/subscription" $qp $auth.query)
  let req_body = {"purchaseToken": $purchase_token, "subscriptionItem": $subscription_item} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Check whether the user has been previously entitled.
#
# GET /itv/had/entitlements
# operationId: checkPreviousEntitlements
export def "itv-had-entitlements check-previous" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<hasHadEntitlements: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/had/entitlements" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the media clip files associated with items.
#
# POST /itv/items/clips
# operationId: getItemsMediaClipFiles
export def "itv-items-clips get-media-files" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  ids: string # Comma-separated list of AXIS item ids.
]: any -> record<items: table<clips: list, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/items/clips" $qp $auth.query)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the details of an item with the specified id.
#
# POST /itv/items/downloadable
# operationId: getItemDownloadables
export def "itv-items-downloadable get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  ids: string # Comma-separated list of AXIS item ids.
]: any -> record<items: table<downloadable: bool, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/items/downloadable" $qp $auth.query)
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Redirects to corresponding Axis Item details page.
#
# GET /itv/itemsummary/{externalId}
export def "itv-itemsummary get" [
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($external_id | is-empty) { error make --unspanned { msg: "path parameter 'externalId' must be non-empty" } }
  let full_url = (build-url $base ({external_id: (encode-path-segment $external_id)} | format pattern "/itv/itemsummary/{external_id}") $auth.query)
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
  send-get $req $insecure $raw $allow_errors $full [302]
}

# Returns a page with the specified id. This is a cut down version for low memory devices.123 If targeting the search page you must url encode the search term as a parameter using the `q` key. For example if your browser path looks like `/search?q=the` then what you pass to this endpoint would look like `/itv/page?path=/search%3Fq%3Dthe`.
#
# GET /itv/page
# operationId: getItvPage
export def "itv-page get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The path of the page to load, e.g. '/movies'.
  --list-page-size: int # The number of items to load when prefetching and paging each list in the page row. (format: int32, default: 12)
  --list-page-size-large: int # The number of items to load when prefetching a continuous scroll list entry in a page. By default any list page entry with template pattern `/^CS\d+$/` will be considered a continuous scroll list. (format: int32, default: 50)
  --max-list-prefetch: int # The maximum number of lists to prefetch in the page. (format: int32, default: 2)
  --item-detail-expand: string@item-detail-expand-completer # Only relevant when loading item detail pages as these embed a detailed item in the main page entry. If no value is specified no item dependencies are expanded. If 'children' is specified then the list of any direct children will be expanded. For example seasons of a show or episodes of a season. If 'all' is specified then the parent chain will be expanded along with any child list at each level. For example if an episode is specified then its season will be expanded and that season's episode list. The season will have its show expanded and the show will have its season list expanded. The 'all' options is useful when you deep link into a show/season/episode for the first time as it provides full context for navigating around the show page. Subsequent navigation around children of the show should only need to request expand of children. If 'ancestors' is specified then only the parent chain is included If an expand is specified which is not relevant to the item type, it will be ignored.
  --item-detail-select-season: string@item-detail-select-season-completer # Only relevant when loading show detail pages as these embed a detailed item in the main page entry. Since the introduction of the D1,2,3 templates this parameter is now somewhat redundant, or less likely to have any effect. While it may still be useful in some cases, most of the time the season selection will be dictated by the configuration of the rows scheduled on the show detail page. This parameter will only take effect if there are rows used to schedule episodes of a season, like D1,2,3, or if no rows have a value set for their `seasonOrder` custom field. Given a targeted show page, it can be useful to get the details of a child season. This option provides a means to return the `first` or `latest` season of a show embedded in the page. The `expand` parameter also works here so for example you could land on a show page and request the `item_detail_select_season=latest` along with `item_detail_expand=all`. This would then return the detail of the latest season with its list of child episode summaries, and also expand the detail of the show with its list of seasons summaries.
  --text-entry-format: string@text-entry-format-completer # Only relevant to page entries of type `TextEntry`. Converts the value of a text page entry to the specified format. (default: markdown)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string, customFields: record, entries: table<customFields: record, id: string, images: record, item: record, list: record, people: list, template: string, text: string, title: string, type: string>, item: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, list: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, metadata: record<description: string, keywords: list<string>, segments: list<string>>, themes: table<colors: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "list_page_size" $list_page_size "scalar") (serialize-qp "list_page_size_large" $list_page_size_large "scalar") (serialize-qp "max_list_prefetch" $max_list_prefetch "scalar") (serialize-qp "item_detail_expand" $item_detail_expand "scalar") (serialize-qp "item_detail_select_season" $item_detail_select_season "scalar") (serialize-qp "text_entry_format" $text_entry_format "scalar") (serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/page" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"path": $path, "list_page_size": $list_page_size, "list_page_size_large": $list_page_size_large, "max_list_prefetch": $max_list_prefetch, "item_detail_expand": $item_detail_expand, "item_detail_select_season": $item_detail_select_season, "text_entry_format": $text_entry_format, "max_rating": $max_rating, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 301]
}

# Provides authorization with parental control pin. Returns an array containing account token with Playback scope. Requires access token with Catalog scope. Pin must be a 4-digit string
#
# POST /itv/pinauthorization
# operationId: getAccountTokenWithPin
export def "itv-pinauthorization get-account-token-with-pin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --cookie-type: string@cookie-type-completer # If you specify a cookie type then a content filter cookie will be returned along with the token(s). This is only intended for web based clients which need to pass the cookies to a server to render a page based on the user's content filters e.g subscription code. If type `Session` the cookie will be session based. If type `Persistent` the cookie will have a medium term lifespan. If undefined no cookies will be set.
  pin: string # The 4-digit parental control pin.
  --scopes: list<string> # The scope(s) of the token(s) required.
]: any -> table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/pinauthorization" $qp $auth.query)
  let req_body = {"cookieType": $cookie_type, "pin": $pin, "scopes": $scopes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Upgrades the plan for the current user.
#
# POST /itv/plan/{platform}
# operationId: upgradePlan
export def "itv-plan create-upgrade" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  plan_id: string # The identifier of the plan to purchase.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/plan/{platform}") $qp $auth.query)
  let req_body = {"planId": $plan_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns the plans available for specified payment platform.
#
# GET /itv/plans/{platform}
export def "itv-plans get" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<plans: table<amount: float, currency: string, description: string, id: string, interval: string, intervalCount: int, nickname: string, product: string, savingLabel: string, switchingText: string, trialPeriodDays: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/plans/{platform}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the ITV profile object.
#
# GET /itv/profile
export def "itv-profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/profile" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update ITV profile. The expected token scope is Settings.
#
# PUT /itv/profile
# operationId: updateProfile
export def "itv-profile update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --date-of-birth: string # The date of birth.
  --email: string # The email address.
  --first-name: string # Last name.
  --last-name: string # First name.
  --postcode: string # The postal code.
  profile_token: string # The ITV profile token.
  --title: string # The title.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/profile" $qp $auth.query)
  let req_body = {"dateOfBirth": $date_of_birth, "email": $email, "firstName": $first_name, "lastName": $last_name, "postcode": $postcode, "profileToken": $profile_token, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get the list of recommended items under the active profile.
#
# GET /itv/profile/recommendation/list
# operationId: getRecommendedList
export def "itv-profile-recommendation-list get-recommended" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --item-types: list<string> # List of item types to filter the recommendation list (e.g. {item_types: show,movie})
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "item_types" $item_types "csv") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/profile/recommendation/list" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"item_types": $item_types, "page": $page, "page_size": $page_size, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the ITV profile token.
#
# POST /itv/profiletoken
# operationId: getItvProfileToken
export def "itv-profiletoken get-profile-token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  password: string # The password.
]: any -> record<profileToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/profiletoken" $qp $auth.query)
  let req_body = {"password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Cancel a plan subscription. A cancelled subscription will continue to be valid until the subscription expiry date or next renewal date.
#
# DELETE /itv/purchase/{platform}
export def "itv-purchase delete" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/purchase/{platform}") $qp $auth.query)
  let req_body = {"profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns the details of current subscription for specified payment platform.
#
# GET /itv/purchase/{platform}
# operationId: getCurrentSubscription
export def "itv-purchase get-subscription" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<cancelAtPeriodEnd: bool, collectionMethod: string, created: int, currentPeriodEnd: int, currentPeriodStart: int, plan: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/purchase/{platform}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Confirms purchase and returns the details of purchased subscription for specified payment platform.
#
# POST /itv/purchase/{platform}
# operationId: confirmPurchase
export def "itv-purchase confirm" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  card_token: string # The credit card token.
  plan_id: string # The identifier of the plan to purchase.
  profile_token: string # The ITV profile token.
  --voucher: string # A coupon/voucher for a discount.
]: any -> record<customerId: string, planId: string, subscriptionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/purchase/{platform}") $qp $auth.query)
  let req_body = {"cardToken": $card_token, "planId": $plan_id, "profileToken": $profile_token, "voucher": $voucher} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Confirms purchase and returns the details of purchased subscription for specified payment platform.
#
# POST /itv/purchase/{platform}/strong
# operationId: confirmPurchaseStrong
export def "itv-purchase-strong confirm" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --payment-method-from-token: string # A paymentMethodFromToken.
  --payment-method-id: string # A paymentMethodId from Stripe.
  plan_id: string # The identifier of the plan to purchase.
  profile_token: string # The ITV profile token.
  --voucher: string # A coupon/voucher for a discount.
]: any -> record<clientSecret: string, customerId: string, intentId: string, intentType: string, planId: string, status: string, subscriptionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/purchase/{platform}/strong") $qp $auth.query)
  let req_body = {"paymentMethodFromToken": $payment_method_from_token, "paymentMethodId": $payment_method_id, "planId": $plan_id, "profileToken": $profile_token, "voucher": $voucher} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Confirms purchase and returns the details of purchased subscription for specified payment platform.
#
# POST /itv/purchase/{platform}/withoffer
# operationId: confirmPurchaseWithOffer
export def "itv-purchase-withoffer confirm-with-offer" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  coupon_id: string # A coupon/voucher for a discount. Can be retrieved from GET itv/voucher/{platform} endpoint
  --payment-method-from-token: string # A paymentMethodFromToken.
  --payment-method-id: string # A paymentMethodId from Stripe.
  plan_id: string # The identifier of the plan to purchase.
  profile_token: string # The ITV profile token.
]: any -> record<clientSecret: string, customerId: string, intentId: string, intentType: string, paymentMethodId: string, status: string, subscriptionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/purchase/{platform}/withoffer") $qp $auth.query)
  let req_body = {"couponId": $coupon_id, "paymentMethodFromToken": $payment_method_from_token, "paymentMethodId": $payment_method_id, "planId": $plan_id, "profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Resubscription for a user.
#
# POST /itv/resubscribe/{platform}
# operationId: resubscribe
export def "itv-resubscribe create" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plan-id: string # The id of the plan to renew.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "planId" $plan_id "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/resubscribe/{platform}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"planId": $plan_id, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Gets available Roku plans.
#
# GET /itv/roku/plans
export def "itv-roku-plans get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<plans: table<amount: float, currency: string, description: string, interval: string, intervalCount: int, nickname: string, product: string, productCode: string, savingLabel: string, trialPeriodDays: int>, termsAndConditions: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/roku/plans" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Sends request to execute specified transaction.
#
# POST /itv/roku/transaction/{transactionid}
# operationId: executeTransaction
export def "itv-roku-transaction create-execute" [
  transactionid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  profile_token: string # The ITV profile token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($transactionid | is-empty) { error make --unspanned { msg: "path parameter 'transactionid' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transactionid: (encode-path-segment $transactionid)} | format pattern "/itv/roku/transaction/{transactionid}") $qp $auth.query)
  let req_body = {"profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Checks the provided coupon id for a user. Only Stripe platform is currently supported.
#
# GET /itv/save-offer
# operationId: getSaveOffer
export def "itv-save-offer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<currency: string, description: string, headline: string, id: string, initialCost: float, longDescription: string, nickname: string, offerdurationperiod: string, shortDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/save-offer" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Activates the discount for a user. Only Stripe platform is currently supported.
#
# POST /itv/save-offer
# operationId: activateSaveOffer
export def "itv-save-offer create-activate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/save-offer" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns full price renewal state and reason for specific user.
#
# GET /itv/subscription/fullpricerenewal
# operationId: getFullPriceRenewal
export def "itv-subscription-fullpricerenewal get-full-price-renewal" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<fullPriceRenewal: bool, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/subscription/fullpricerenewal" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns status of latest payment intent.
#
# GET /itv/subscription/status/{platform}
# operationId: getSubscriptionStatus
export def "itv-subscription-status get" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<is_active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/subscription/status/{platform}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns the state of subscription for any payment platform.
#
# GET /itv/subscriptionstate
# operationId: getSubscriptionState
export def "itv-subscriptionstate get-subscription-state" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<effective_entitlements: table<card_type: string, expiry: string, plan: record, source: string, subscriptionId: string>, failed_availability_checks: list<string>, purchased: list<string>, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/subscriptionstate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns an upcoming invoice
#
# GET /itv/upcominginvoice
# operationId: getUpcomingInvoice
export def "itv-upcominginvoice get-upcoming-invoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<currency: string, description: string, headline: string, id: string, initialCost: float, longDescription: string, nickname: string, offerdurationperiod: string, shortDescription: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/itv/upcominginvoice" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Change payment method details.
#
# PUT /itv/updateIntent/strong/{platform}
# operationId: updatePaymentIntentStrong
export def "itv-update-intent-strong update-payment" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --payment-method-from-token: string # A paymentMethodFromToken.
  --payment-method-id: string # The paymentMethodId from Stripe.
  profile_token: string # The ITV profile token.
]: any -> record<clientSecret: string, intentId: string, intentType: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/updateIntent/strong/{platform}") $qp $auth.query)
  let req_body = {"paymentMethodFromToken": $payment_method_from_token, "paymentMethodId": $payment_method_id, "profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Change payment method details.
#
# PUT /itv/updatePayment/strong/{platform}
# operationId: updatePaymentMethodStrong
export def "itv-update-payment-strong update-method" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --payment-method-from-token: string # A paymentMethodFromToken.
  --payment-method-id: string # The paymentMethodId from Stripe.
  profile_token: string # The ITV profile token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/updatePayment/strong/{platform}") $qp $auth.query)
  let req_body = {"paymentMethodFromToken": $payment_method_from_token, "paymentMethodId": $payment_method_id, "profileToken": $profile_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [204]
}

# Checks the provided coupon id for a user. Only Stripe platform is currently supported.
#
# GET /itv/voucher/{planId}/{voucherId}
# operationId: getVoucherById
export def "itv-voucher get" [
  plan_id: string
  voucher_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<display: record<currency: string, discountPrice: string, duration: string, durationInMonths: float, headlineLabel: string, initialCost: float, longDescription: string, percentOff: float, savingLabel: string, shortDescription: string>, id: string, links: record<redeem: record<href: string>, self: record<href: string>>, offerType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($plan_id | is-empty) { error make --unspanned { msg: "path parameter 'planId' must be non-empty" } }
  if ($voucher_id | is-empty) { error make --unspanned { msg: "path parameter 'voucherId' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({plan_id: (encode-path-segment $plan_id), voucher_id: (encode-path-segment $voucher_id)} | format pattern "/itv/voucher/{plan_id}/{voucher_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Validates the coupon/voucher for specified payment platform.
#
# POST /itv/voucher/{platform}
# operationId: checkVoucher
export def "itv-voucher check" [
  platform: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  voucher: string # The voucher.
]: any -> record<display: record<currency: string, discountPrice: string, duration: string, durationInMonths: float, headlineLabel: string, initialCost: float, longDescription: string, percentOff: float, savingLabel: string, shortDescription: string>, id: string, links: record<redeem: record<href: string>, self: record<href: string>>, offerType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform)} | format pattern "/itv/voucher/{platform}") $qp $auth.query)
  let req_body = {"voucher": $voucher} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Returns an array of item lists with their first page of content resolved.
#
# GET /lists
# operationId: getLists
export def "lists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list<string> # A comma delimited list of item list identifiers. These can be list ids e.g. `14354,65473,3234` Or more complex sort/filter queries using pipes e.g. `14354|max_rating=AUOFLC-E|order=asc|order_by=year-added,65473|page_size=30,3234` _Note the id must always come first for each encoded list query_ List parameters may be provide without the `param=` prefix e.g. `14354|genre:action` Only the following options can be present. - `order` - `order_by` - `max_rating` - `page_size` - `item_type` - `param`
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --order-by: string@order-by-completer-1 # What to order by.
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> table<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "item_type" $item_type "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ids": $ids, "page_size": $page_size, "max_rating": $max_rating, "order": $order, "order_by": $order_by, "item_type": $item_type, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of items under the specified item list
#
# GET /lists/{id}
# operationId: getList
export def "lists get" [
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
  --page: int # The page of items to load. Starts from page 1. (format: int32, default: 1)
  --page-size: int # The number of items to return in a page. (format: int32, default: 12)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --order: string@order-completer # The list sort order, either 'asc' or 'desc'. (default: desc)
  --order-by: string@order-by-completer-1 # What to order by.
  --param: string # The list parameter in format 'key:value', e.g. 'genre:action'.
  --item-type: string@item-type-completer # The item type to filter by. Defaults to unspecified.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: table<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list, hasClosedCaptions: bool, id: string, images: record, offers: list, path: string, releaseYear: int, scopes: list, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list, title: string, type: string, watchPath: string>, listData: record<ContinueWatching: record<itemInclusions: record>>, paging: record<authorization: record<scope: string, type: string>, next: string, options: record<completed: bool, itemType: string, maxRating: string, order: string, orderBy: string, pageSize: int>, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: table<colors: list, type: string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "param" $param "scalar") (serialize-qp "item_type" $item_type "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/lists/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "page_size": $page_size, "max_rating": $max_rating, "order": $order, "order_by": $order_by, "param": $param, "item_type": $item_type, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a page with the specified id. If targeting the search page you must url encode the search term as a parameter using the `q` key. For example if your browser path looks like `/search?q=the` then what you pass to this endpoint would look like `/page?path=/search%3Fq%3Dthe`.
#
# GET /page
# operationId: getPage
export def "page get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --path: string # The path of the page to load, e.g. '/movies'.
  --list-page-size: int # The number of items to load when prefetching and paging each list in the page row. (format: int32, default: 12)
  --list-page-size-large: int # The number of items to load when prefetching a continuous scroll list entry in a page. By default any list page entry with template pattern `/^CS\d+$/` will be considered a continuous scroll list. (format: int32, default: 50)
  --max-list-prefetch: int # The maximum number of lists to prefetch in the page. (format: int32, default: 2)
  --item-detail-expand: string@item-detail-expand-completer # Only relevant when loading item detail pages as these embed a detailed item in the main page entry. If no value is specified no item dependencies are expanded. If 'children' is specified then the list of any direct children will be expanded. For example seasons of a show or episodes of a season. If 'all' is specified then the parent chain will be expanded along with any child list at each level. For example if an episode is specified then its season will be expanded and that season's episode list. The season will have its show expanded and the show will have its season list expanded. The 'all' options is useful when you deep link into a show/season/episode for the first time as it provides full context for navigating around the show page. Subsequent navigation around children of the show should only need to request expand of children. If 'ancestors' is specified then only the parent chain is included If an expand is specified which is not relevant to the item type, it will be ignored.
  --item-detail-select-season: string@item-detail-select-season-completer # Only relevant when loading show detail pages as these embed a detailed item in the main page entry. Since the introduction of the D1,2,3 templates this parameter is now somewhat redundant, or less likely to have any effect. While it may still be useful in some cases, most of the time the season selection will be dictated by the configuration of the rows scheduled on the show detail page. This parameter will only take effect if there are rows used to schedule episodes of a season, like D1,2,3, or if no rows have a value set for their `seasonOrder` custom field. Given a targeted show page, it can be useful to get the details of a child season. This option provides a means to return the `first` or `latest` season of a show embedded in the page. The `expand` parameter also works here so for example you could land on a show page and request the `item_detail_select_season=latest` along with `item_detail_expand=all`. This would then return the detail of the latest season with its list of child episode summaries, and also expand the detail of the show with its list of seasons summaries.
  --text-entry-format: string@text-entry-format-completer # Only relevant to page entries of type `TextEntry`. Converts the value of a text page entry to the specified format. (default: markdown)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<id: string, isStatic: bool, isSystemPage: bool, key: string, path: string, template: string, title: string, customFields: record, entries: table<customFields: record, id: string, images: record, item: record, list: record, people: list, template: string, text: string, title: string, type: string>, item: record<advisoryText: string, availableEpisodeCount: int, availableSeasonCount: int, averageUserRating: float, badge: string, channelShortCode: string, classification: record<code: string, name: string>, contextualTitle: string, customFields: record, customId: string, duration: int, episodeCount: int, episodeName: string, episodeNumber: int, genres: list<string>, hasClosedCaptions: bool, id: string, images: record, offers: list<record>, path: string, releaseYear: int, scopes: list<string>, seasonId: string, seasonNumber: int, shortDescription: string, showId: string, showTitle: string, subtype: string, tagline: string, themes: list<record>, title: string, type: string, watchPath: string, copyright: string, credits: list<record>, customMetadata: list<record>, description: string, distributor: string, episodes: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, eventDate: string, genrePaths: list<string>, location: string, season: any, seasons: record<customFields: record, description: string, id: string, images: record, itemTypes: list, items: list, listData: record, paging: record, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list, title: string>, show: any, totalUserRatings: int, trailers: list<record>, venue: string>, list: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, metadata: record<description: string, keywords: list<string>, segments: list<string>>, themes: table<colors: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "path" $path "scalar") (serialize-qp "list_page_size" $list_page_size "scalar") (serialize-qp "list_page_size_large" $list_page_size_large "scalar") (serialize-qp "max_list_prefetch" $max_list_prefetch "scalar") (serialize-qp "item_detail_expand" $item_detail_expand "scalar") (serialize-qp "item_detail_select_season" $item_detail_select_season "scalar") (serialize-qp "text_entry_format" $text_entry_format "scalar") (serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/page" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"path": $path, "list_page_size": $list_page_size, "list_page_size_large": $list_page_size_large, "max_list_prefetch": $max_list_prefetch, "item_detail_expand": $item_detail_expand, "item_detail_select_season": $item_detail_select_season, "text_entry_format": $text_entry_format, "max_rating": $max_rating, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200 301]
}

# Returns the details of a Plan with the specified id.
#
# GET /plans/{id}
export def "plans get" [
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
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<alias: string, benefits: list<string>, billingPeriodFrequency: int, billingPeriodType: string, currency: string, customFields: record, hasTrialPeriod: bool, id: string, isActive: bool, isFeatured: bool, isPrivate: bool, price: float, revenueType: string, subscriptionCode: string, tagline: string, termsAndConditions: string, title: string, trialPeriodDays: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/plans/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Register a new user, creating them an account. Registration, when successful, will return an array of access tokens so the user is immediately signed in. It returns Catalog and Commerce scoped tokens for both Account and Profile. The Commerce ones are intended to allow the purchase of a subscription plan in the step after registration, without the user being prompted to enter their username and password again. An email will also be sent with a link they need to click to confirm their email address. This confirmation is done via the /verify-email endpoint.
#
# POST /register
# operationId: register
export def "register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  email: string
  --first-name: string
  --language-code: string # The code of the preferred language for the primary profile. Must be a valid ISO language code e.g. "en-US" and must match the code of one of the languages specified in the app config. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  --last-name: string
  --marketing: oneof<nothing, bool> # Whether to receive marketing material or not. Default to true. (default: true)
  password: string
  --pin: string # The primary account pin.
  --segments: list<string> # The segments to apply to the primary profile.
]: any -> table<accountCreated: bool, expirationDate: string, refreshable: bool, type: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/register" $qp $auth.query)
  let req_body = {"email": $email, "firstName": $first_name, "languageCode": $language_code, "lastName": $last_name, "marketing": $marketing, "password": $password, "pin": $pin, "segments": $segments} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Request the password of an account's primary profile be reset. Should be called when a user has forgotten their password. This will send an email with a password reset link to the email address of the primary profile of an account. The link, once clicked, should take the user to the "reset-password" page of the website. Here they will enter their new password and submit to the /reset-password endpoint here, along with the password reset token provided in the original link.
#
# POST /request-password-reset
# operationId: forgotPassword
export def "request-password-reset create-forgot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  email: string # The email address of the primary account profile to reset the password for.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/request-password-reset" $qp $auth.query)
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# When a user requests to reset their password via the /request-password-reset endpoint, an email is sent to the email address of the primary profile of the account. This email contains a link with a reset token as query parameter. The link should take the user to the "reset-password" page of the website. From the reset-password page a user should enter the new password they wish to use. It should then be submitted to this endpoint, along with the reset token from the email link. The token should be provided in the body as resetToken property.
#
# POST /reset-password
# operationId: resetPassword
export def "reset-password reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
  password: string # The new password for the account.
  reset_token: string # The ITV reset token.
]: any -> record<code: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reset-password" $qp $auth.query)
  let req_body = {"password": $password, "resetToken": $reset_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Returns public preview for Samsung based on the page '/samsung-preview' configured in PresentationManager. There is a hard limit of max 40 items to be returned. It splits evenly items count into the page rows, remaining items are added into the first row.
#
# GET /samsung-preview
# operationId: getPublicPreview
export def "samsung-preview get-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<expires: int, expires_only: bool, sections: table<position: int, tiles: list, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/samsung-preview" $auth.query)
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

# Returns schedules for a defined set of channels over a requested period. Schedules are requested in hour blocks and returned grouped by the channel they belong to. For example, to load 12 hours of schedules for channels `4343` and `5234`, on 21/2/2017 starting from 08:00. ``` channels=4343,5234 date=2017-02-21 hour=8 duration=12 ``` Please remember that `date` and `hour` combined represent a normal datetime, so they should be converted to UTC on the client - this will help to avoid issues with EPG schedules near midnight. If a channel id is passed which doesn't exist then this endpoint will return an empty schedule list for it. If instead we returned 404, this would invalidate all other channel schedules in the same request which would be unfriendly for clients presenting these channel schedules.
#
# GET /schedules
# operationId: getSchedules
export def "schedules get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channels: list<string> # The list of channel ids to get schedules for.
  --date: string # The date to target in ISO format, e.g. `2017-05-23` (converted to UTC - see main description). The base hour requested will belong to this date. (format: date)
  --hour: int # The base hour in the day, defined by the `date` parameter, you wish to load schedules for (converted to UTC - see main description). From 0 to 23, where 0 is midnight. (format: int32)
  --duration: int # The number of hours of schedules to load from the base `hour` parameter. This may be negative or positive depending on whether you want to load past or future schedules. Minimum value is -24, maximum is 24. A value of zero is invalid. (format: int32)
  --intersect: oneof<nothing, bool> # Flag indicating whether schedules should intersect or be contained in the provided interval. If set to `true`, the result will contain all schedules where either schedule start time or end time touches the provided interval. If set to `false`, only schedules fully contained in the given period will be returned. (default: false)
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> table<channelId: string, endDate: string, schedules: list<record>, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channels" $channels "csv") (serialize-qp "date" $date "scalar") (serialize-qp "hour" $hour "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "intersect" $intersect "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schedules" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"channels": $channels, "date": $date, "hour": $hour, "duration": $duration, "intersect": $intersect, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search the catalog of items and people.
#
# GET /search
# operationId: search
export def "search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --term: string # The search term to query.
  --include: list<string> # By default people, movies and tv (shows + programs) will be included in the search results. If the `cas` feature flag is set, "other" items (`customAsset`s) will also be included by default If you don't want all of these types you can specifiy the specific includes you care about.
  --group: oneof<nothing, bool> # When this option is set, instead of all search result items being returned in a single list, they will instead be returned under two lists. One for movies and another for tv (shows + programs). if the `cas` feature flag is set, a third `other` list will be included containing `customAsset` results Default is undefined meaning items will be returned in a single list. The array of `people` results will always be separate from items.
  --max-results: int # The maximum number of results to return. (format: int32, default: 20)
  --max-rating: string # The maximum rating (inclusive) of items returned, e.g. 'auoflc-pg'.
  --device: string # The type of device the content is targeting. (default: web_browser)
  --sub: string # The active subscription code.
  --segments: list<string> # The list of segments to filter the response by.
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<items: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, movies: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, other: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>, people: table<name: string, path: string>, term: string, total: int, tv: record<customFields: record, description: string, id: string, images: record, itemTypes: list<string>, items: list<record>, listData: record<ContinueWatching: record>, paging: record<authorization: record, next: string, options: record, page: int, previous: string, size: int, total: int>, parameter: string, path: string, shortDescription: string, size: int, tagline: string, themes: list<record>, title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "term" $term "scalar") (serialize-qp "include" $include "csv") (serialize-qp "group" $group "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "max_rating" $max_rating "scalar") (serialize-qp "device" $device "scalar") (serialize-qp "sub" $sub "scalar") (serialize-qp "segments" $segments "csv") (serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"term": $term, "include": $include, "group": $group, "max_results": $max_results, "max_rating": $max_rating, "device": $device, "sub": $sub, "segments": $segments, "ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# When an account is created an email is sent to the email address of the new account. This contains a link, which once clicked, verifies the email address of the account is correct. The link contains a token as a query parameter which should be passed as the authorization bearer token to this endpoint to complete email verification. The token has en expiry, so if the link is not clicked before it expires, the account holder may need to request a new verification email be sent. This can be done via the endpoint /account/request-email-verification.
#
# POST /verify-email
# operationId: verifyEmail
export def "verify-email verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ff: list<string> # The set of opt in feature flags which cause breaking changes to responses. While Rocket APIs look to avoid breaking changes under the active major version, the formats of responses may need to evolve over this time. These feature flags allow clients to select which response formats they expect and avoid breaking clients as these formats evolve under the current major version. ### Flags - `all` - Enable all flags. Useful for testing. _Don't use in production_. - `idp` - Dynamic item detail pages with schedulable rows. - `ldp` - Dynamic list detail pages with schedulable rows. - `hb` - Hubble formatted image urls. - `rpt` - Updated resume point threshold logic. - `cas` - "Custom Asset Search", inlcude `customAssets` in search results. - `lrl` - Do not pre-populate related list if more than `max_list_prefetch` down the page. - `cd` - Custom Destination support. See the `feature-flags.md` for available flag details.
  --lang: string # Language code for the preferred language to be returned in the response. Parameter value is case-insensitive and should be - a valid 2 letter language code without region such as en, de - or with region such as en_us, en_au If undefined then defaults to 'en', unless the server has been configured with a custom default. See https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes
]: nothing -> record<code: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ff" $ff "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verify-email" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"ff": $ff, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [204]
}
