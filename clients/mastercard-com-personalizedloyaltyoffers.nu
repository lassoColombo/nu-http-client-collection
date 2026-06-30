# Auto-generated client for Personalized Offers v1.3
# Source: https://api.apis.guru/v2/specs/mastercard.com/PersonalizedLoyaltyOffers/1.3/swagger.json
# Auth: --token flag or $env.PERSONALIZED_OFFERS_TOKEN

const BASE_URL = "https://api.mastercard.com/plo/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PERSONALIZED_OFFERS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://api.mastercard.com/plo/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activatestatementcreditoffer create" } } | get name | first)
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

# Make Statement Credit Offer Available Redeemable
#
# POST /activatestatementcreditoffer
export def "activatestatementcreditoffer create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
  --offer-id: string # System-wide identifier for the campaign, not intended for end-user display. (e.g. c7dcfca7-cf35-36b0-9e67-d4f363d643e0)
]: nothing -> record<Response: record<ScActivation: record<ActivationDate: string, ActivationId: string, CashBack: string, DaysRemaining: string, Headline: string, Merchant: string, MerchantLogo: string, OfferId: string, PointsEarned: string, RedemptionEndDate: string, RedemptionMode: string, RemainingSpend: string, ShortDescription: string, Status: string, TotalSpend: string>, Status: record<Code: string, Message: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "OfferId" $offer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activatestatementcreditoffer" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"FId": $f_id, "UserToken": $user_token, "OfferId": $offer_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns Matched Offers
#
# GET /matchedoffers
export def "matchedoffers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
  --lang: string # When utilized with a multi-lingual implementation, may be the tongue and country of the user in ISO 639-1, underscore, ISO 3166-1 alpha-2 format. (e.g. en_US)
  --merchant-name: string # Fuzzy term to search retailers with offers for the user. In general, searching of Matched Offers is not advised as users generally have a modest selection of highly relevant promotions. (e.g. Example.com)
  --category: string # Offer Categories. (e.g. DEPARTMENTSTORE)
  --offer-type: string # The kind of deal. POSTPAIDCREDIT- Statement Credit Offer, which is a discount that is automatically applied to the card linked to the user and utilized to make the purchase. (e.g. POSTPAIDCREDIT)
  --page-number: int # Segment of offers to return. (e.g. 1)
  --items-per-page: int # Segment size of offer to be returned. Default is 25. (e.g. 1)
]: nothing -> record<Response: record<CurrentPage: int, Items: record<MatchedOffer: record>, ItemsPerPage: int, NumberOfPages: int, Status: record<Code: string, Message: string>, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "Lang" $lang "scalar") (serialize-qp "MerchantName" $merchant_name "scalar") (serialize-qp "Category" $category "scalar") (serialize-qp "OfferType" $offer_type "scalar") (serialize-qp "PageNumber" $page_number "scalar") (serialize-qp "ItemsPerPage" $items_per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matchedoffers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"FId": $f_id, "UserToken": $user_token, "Lang": $lang, "MerchantName": $merchant_name, "Category": $category, "OfferType": $offer_type, "PageNumber": $page_number, "ItemsPerPage": $items_per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Information on an Offer
#
# GET /offerdetails
export def "offerdetails get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource. (e.g. mh3WonUm5xmE)
  --offer-id: string # System-wide identifier for the campaign, not intended for end-user display. (e.g. c7dcfca7-cf35-36b0-9e67-d4f363d643e0)
]: nothing -> record<Response: record<OfferDetails: record<CurrencyCode: string, DetailPostpaidCreditOffer: record, EventEndDate: string, EventStartDate: string, Headline: string, Language: string, LinkOut: any, LongDescription: string, Merchant: record, OfferDisplay: record, OfferId: string, OfferMedia: record, OfferSource: string, OfferType: string, OfferUrl: any, RedemptionMode: string, RedemptionType: string, ShortDescription: string>, Status: record<Code: string, Message: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "OfferId" $offer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offerdetails" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"FId": $f_id, "UserToken": $user_token, "OfferId": $offer_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Redeemed Offers
#
# GET /redeemedoffers
export def "redeemedoffers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
  --lang: string # When utilized with a multi-lingual implementation, may be the tongue and country of the user in ISO 639-1, underscore, ISO 3166-1 alpha-2 format. (e.g. en_US)
  --page-number: int # Segment of offers to return. (e.g. 1)
  --items-per-page: int # Segment size of offer to be returned. Default is 25. (e.g. 1)
]: nothing -> record<Response: record<CurrentPage: int, Items: record<RedemedOffer: record>, ItemsPerPage: int, NumberOfPages: int, Status: record<Code: string, Message: string>, TotalCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "Lang" $lang "scalar") (serialize-qp "PageNumber" $page_number "scalar") (serialize-qp "ItemsPerPage" $items_per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/redeemedoffers" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"FId": $f_id, "UserToken": $user_token, "Lang": $lang, "PageNumber": $page_number, "ItemsPerPage": $items_per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns Information About Redeemable Postpaid Credit Offer
#
# GET /statementcreditactivationdetail
export def "statementcreditactivationdetail get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
  --activation-id: string # Distinct identifier for the offer being available for redemption by the user as returned by Activate Statement Credit Offer or Redeemed Offers, not intended for end-user display. (e.g. TRU_1000136)
]: nothing -> record<Response: record<ScActivation: record<ActivationDate: string, ActivationId: string, CashBack: string, DaysRemaining: string, Headline: string, Merchant: string, MerchantLogo: string, OfferId: string, PointsEarned: string, RedemptionEndDate: string, RedemptionMode: string, RemainingSpend: string, ShortDescription: string, Status: string, TotalSpend: string>, Status: record<Code: string, Message: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "ActivationId" $activation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statementcreditactivationdetail" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"FId": $f_id, "UserToken": $user_token, "ActivationId": $activation_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Provide User Feedback on Offer
#
# POST /userfeedback
export def "userfeedback create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
  --offer-id: string # System-wide identifier for the campaign, not intended for end-user display. (e.g. d82e1e7c-c6b9-3b46-acd0-5498731c2838)
  --feedback: int # User response to the offer. 0- Dislike offer. 1- Like offer. (e.g. 1)
]: nothing -> record<Response: record<Status: record<Code: string, Message: string>, UserFeedback: record<Feedback: string, OfferId: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "OfferId" $offer_id "scalar") (serialize-qp "Feedback" $feedback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/userfeedback" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"FId": $f_id, "UserToken": $user_token, "OfferId": $offer_id, "Feedback": $feedback} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns Savings for the User
#
# GET /usersavings
export def "usersavings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
]: nothing -> record<Response: record<Status: record<Code: string, Message: string>, UserSavings: record<PrepaidOfferSavings: record, StatementCreditOffersSavings: record, TotalAmountSaved: string, TotalOffersUsed: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usersavings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"FId": $f_id, "UserToken": $user_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns User Session Token
#
# GET /usertoken
export def "usertoken get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --auth-info: string # Authorization Information. AES 128-bit encrypted concatenation of "User ID as specified in enrollment:FI ID as provided by Mastercard:current Unix time". Key exchange and establishment of maintenance procedures occur during implementation.
]: nothing -> record<Response: record<Status: record<Code: string, Message: string>, UserToken: record<Token: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "AuthInfo" $auth_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usertoken" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"FId": $f_id, "AuthInfo": $auth_info} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
