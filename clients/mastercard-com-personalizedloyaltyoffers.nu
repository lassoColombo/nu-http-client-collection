# Auto-generated client for Personalized Offers v1.3
# Source: https://api.apis.guru/v2/specs/mastercard.com/PersonalizedLoyaltyOffers/1.3/swagger.json
# Auth: --token flag or $env.PERSONALIZED_OFFERS_TOKEN

const BASE_URL = "https://api.mastercard.com/plo/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PERSONALIZED_OFFERS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.mastercard.com/plo/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
  --offer-id: string # System-wide identifier for the campaign, not intended for end-user display. (e.g. c7dcfca7-cf35-36b0-9e67-d4f363d643e0)
]: nothing -> record<Response: record<ScActivation: record<ActivationDate: string, ActivationId: string, CashBack: string, DaysRemaining: string, Headline: string, Merchant: string, MerchantLogo: string, OfferId: string, PointsEarned: string, RedemptionEndDate: string, RedemptionMode: string, RemainingSpend: string, ShortDescription: string, Status: string, TotalSpend: string>, Status: record<Code: string, Message: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "OfferId" $offer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/activatestatementcreditoffer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/matchedoffers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource. (e.g. mh3WonUm5xmE)
  --offer-id: string # System-wide identifier for the campaign, not intended for end-user display. (e.g. c7dcfca7-cf35-36b0-9e67-d4f363d643e0)
]: nothing -> record<Response: record<OfferDetails: record<CurrencyCode: string, DetailPostpaidCreditOffer: record, EventEndDate: string, EventStartDate: string, Headline: string, Language: string, LinkOut: any, LongDescription: string, Merchant: record, OfferDisplay: record, OfferId: string, OfferMedia: record, OfferSource: string, OfferType: string, OfferUrl: any, RedemptionMode: string, RedemptionType: string, ShortDescription: string>, Status: record<Code: string, Message: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "OfferId" $offer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/offerdetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  let full_url = (build-url $base "/redeemedoffers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
  --activation-id: string # Distinct identifier for the offer being available for redemption by the user as returned by Activate Statement Credit Offer or Redeemed Offers, not intended for end-user display. (e.g. TRU_1000136)
]: nothing -> record<Response: record<ScActivation: record<ActivationDate: string, ActivationId: string, CashBack: string, DaysRemaining: string, Headline: string, Merchant: string, MerchantLogo: string, OfferId: string, PointsEarned: string, RedemptionEndDate: string, RedemptionMode: string, RemainingSpend: string, ShortDescription: string, Status: string, TotalSpend: string>, Status: record<Code: string, Message: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "ActivationId" $activation_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statementcreditactivationdetail" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
  --offer-id: string # System-wide identifier for the campaign, not intended for end-user display. (e.g. d82e1e7c-c6b9-3b46-acd0-5498731c2838)
  --feedback: int # User response to the offer. 0- Dislike offer. 1- Like offer. (e.g. 1)
]: nothing -> record<Response: record<Status: record<Code: string, Message: string>, UserFeedback: record<Feedback: string, OfferId: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar") (serialize-qp "OfferId" $offer_id "scalar") (serialize-qp "Feedback" $feedback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/userfeedback" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --user-token: string # Session identifier as returned by the UserToken resource.
]: nothing -> record<Response: record<Status: record<Code: string, Message: string>, UserSavings: record<PrepaidOfferSavings: record, StatementCreditOffersSavings: record, TotalAmountSaved: string, TotalOffersUsed: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "UserToken" $user_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usersavings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-id: string # Financial Institution Identifier. Code that specifies the platform and configuration instance, provided by Mastercard during implementation. (e.g. 999999)
  --auth-info: string # Authorization Information. AES 128-bit encrypted concatenation of "User ID as specified in enrollment:FI ID as provided by Mastercard:current Unix time". Key exchange and establishment of maintenance procedures occur during implementation.
]: nothing -> record<Response: record<Status: record<Code: string, Message: string>, UserToken: record<Token: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FId" $f_id "scalar") (serialize-qp "AuthInfo" $auth_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/usertoken" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
