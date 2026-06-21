# Auto-generated client for Amazon Personalize Runtime v2018-05-22
# Source: https://api.apis.guru/v2/specs/amazonaws.com/personalize-runtime/2018-05-22/openapi.json
# Auth: --token flag or $env.AMAZON_PERSONALIZE_RUNTIME_TOKEN

const BASE_URL = "http://personalize-runtime.us-east-1.amazonaws.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AMAZON_PERSONALIZE_RUNTIME_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://personalize-runtime.us-east-1.amazonaws.com" "http://personalize-runtime.us-east-2.amazonaws.com" "http://personalize-runtime.us-west-1.amazonaws.com" "http://personalize-runtime.us-west-2.amazonaws.com" "http://personalize-runtime.us-gov-west-1.amazonaws.com" "http://personalize-runtime.us-gov-east-1.amazonaws.com" "http://personalize-runtime.ca-central-1.amazonaws.com" "http://personalize-runtime.eu-north-1.amazonaws.com" "http://personalize-runtime.eu-west-1.amazonaws.com" "http://personalize-runtime.eu-west-2.amazonaws.com" "http://personalize-runtime.eu-west-3.amazonaws.com" "http://personalize-runtime.eu-central-1.amazonaws.com" "http://personalize-runtime.eu-south-1.amazonaws.com" "http://personalize-runtime.af-south-1.amazonaws.com" "http://personalize-runtime.ap-northeast-1.amazonaws.com" "http://personalize-runtime.ap-northeast-2.amazonaws.com" "http://personalize-runtime.ap-northeast-3.amazonaws.com" "http://personalize-runtime.ap-southeast-1.amazonaws.com" "http://personalize-runtime.ap-southeast-2.amazonaws.com" "http://personalize-runtime.ap-east-1.amazonaws.com" "http://personalize-runtime.ap-south-1.amazonaws.com" "http://personalize-runtime.sa-east-1.amazonaws.com" "http://personalize-runtime.me-south-1.amazonaws.com" "https://personalize-runtime.us-east-1.amazonaws.com" "https://personalize-runtime.us-east-2.amazonaws.com" "https://personalize-runtime.us-west-1.amazonaws.com" "https://personalize-runtime.us-west-2.amazonaws.com" "https://personalize-runtime.us-gov-west-1.amazonaws.com" "https://personalize-runtime.us-gov-east-1.amazonaws.com" "https://personalize-runtime.ca-central-1.amazonaws.com" "https://personalize-runtime.eu-north-1.amazonaws.com" "https://personalize-runtime.eu-west-1.amazonaws.com" "https://personalize-runtime.eu-west-2.amazonaws.com" "https://personalize-runtime.eu-west-3.amazonaws.com" "https://personalize-runtime.eu-central-1.amazonaws.com" "https://personalize-runtime.eu-south-1.amazonaws.com" "https://personalize-runtime.af-south-1.amazonaws.com" "https://personalize-runtime.ap-northeast-1.amazonaws.com" "https://personalize-runtime.ap-northeast-2.amazonaws.com" "https://personalize-runtime.ap-northeast-3.amazonaws.com" "https://personalize-runtime.ap-southeast-1.amazonaws.com" "https://personalize-runtime.ap-southeast-2.amazonaws.com" "https://personalize-runtime.ap-east-1.amazonaws.com" "https://personalize-runtime.ap-south-1.amazonaws.com" "https://personalize-runtime.sa-east-1.amazonaws.com" "https://personalize-runtime.me-south-1.amazonaws.com" "http://personalize-runtime.cn-north-1.amazonaws.com.cn" "http://personalize-runtime.cn-northwest-1.amazonaws.com.cn" "https://personalize-runtime.cn-north-1.amazonaws.com.cn" "https://personalize-runtime.cn-northwest-1.amazonaws.com.cn"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "personalize-ranking get-personalized" } } | get name | first)
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

# Re-ranks a list of recommended items for the given user. The first item in the list is deemed the most likely item to be of interest to the user. The solution backing the campaign must have been created using a recipe of type PERSONALIZED_RANKING.
#
# POST /personalize-ranking
# operationId: GetPersonalizedRanking
export def "personalize-ranking get-personalized" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  campaign_arn: string # The Amazon Resource Name (ARN) of the campaign to use for generating the personalized ranking.
  input_list: list<string> # A list of items (by itemId) to rank. If an item was not included in the training dataset, the item is appended to the end of the reranked list. The maximum is 500.
  user_id: string # The user for which you want the campaign to provide a personalized ranking.
  --context: record # The contextual metadata to use when getting recommendations. Contextual metadata includes any interaction information that might be relevant when getting a user's recommendations, such as the user's current location or device type.
  --filter-arn: string # The Amazon Resource Name (ARN) of a filter you created to include items or exclude items from recommendations for a given user. For more information, see Filtering Recommendations (https://docs.aws.amazon.com/personalize/latest/dg/filter.html).
  --filter-values: record # The values to use when filtering recommendations. For each placeholder parameter in your filter expression, provide the parameter name (in matching case) as a key and the filter value(s) as the corresponding value. Separate multiple values for one parameter with a comma. For filter expressions that use an INCLUDE element to include items, you must provide values for all parameters that are defined in the expression. For filters with expressions that use an EXCLUDE element to exclude items, you can omit the filter-values.In this case, Amazon Personalize doesn't use that portion of the expression to filter recommendations. For more information, see Filtering Recommendations (https://docs.aws.amazon.com/personalize/latest/dg/filter.html).
]: any -> record<personalizedRanking: record, recommendationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/personalize-ranking")
  let req_body = {"campaignArn": $campaign_arn, "inputList": $input_list, "userId": $user_id, "context": $context, "filterArn": $filter_arn, "filterValues": $filter_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of recommended items. For campaigns, the campaign's Amazon Resource Name (ARN) is required and the required user and item input depends on the recipe type used to create the solution backing the campaign as follows: USER_PERSONALIZATION - userId required, itemId not used RELATED_ITEMS - itemId required, userId not used Campaigns that are backed by a solution created using a recipe of type PERSONALIZED_RANKING use the API. For recommenders, the recommender's ARN is required and the required item and user input depends on the use case (domain-based recipe) backing the recommender. For information on use case requirements see Choosing recommender use cases (https://docs.aws.amazon.com/personalize/latest/dg/domain-use-cases.html).
#
# POST /recommendations
# operationId: GetRecommendations
# --promotions item shape: {name?: any, percentPromotedItems?: any, filterArn?: any, filterValues?: any}
export def "recommendations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-amz-content-sha256: string
  --x-amz-date: string
  --x-amz-algorithm: string
  --x-amz-credential: string
  --x-amz-security-token: string
  --x-amz-signature: string
  --x-amz-signed-headers: string
  --campaign-arn: string # The Amazon Resource Name (ARN) of the campaign to use for getting recommendations.
  --item-id: string # The item ID to provide recommendations for. Required for RELATED_ITEMS recipe type.
  --user-id: string # The user ID to provide recommendations for. Required for USER_PERSONALIZATION recipe type.
  --num-results: int # The number of results to return. The default is 25. The maximum is 500.
  --context: record # The contextual metadata to use when getting recommendations. Contextual metadata includes any interaction information that might be relevant when getting a user's recommendations, such as the user's current location or device type.
  --filter-arn: string # The ARN of the filter to apply to the returned recommendations. For more information, see Filtering Recommendations (https://docs.aws.amazon.com/personalize/latest/dg/filter.html). When using this parameter, be sure the filter resource is ACTIVE.
  --filter-values: record # The values to use when filtering recommendations. For each placeholder parameter in your filter expression, provide the parameter name (in matching case) as a key and the filter value(s) as the corresponding value. Separate multiple values for one parameter with a comma. For filter expressions that use an INCLUDE element to include items, you must provide values for all parameters that are defined in the expression. For filters with expressions that use an EXCLUDE element to exclude items, you can omit the filter-values.In this case, Amazon Personalize doesn't use that portion of the expression to filter recommendations. For more information, see Filtering recommendations and user segments (https://docs.aws.amazon.com/personalize/latest/dg/filter.html).
  --recommender-arn: string # The Amazon Resource Name (ARN) of the recommender to use to get recommendations. Provide a recommender ARN if you created a Domain dataset group with a recommender for a domain use case.
  --promotions: list # The promotions to apply to the recommendation request. A promotion defines additional business rules that apply to a configurable subset of recommended items. — item shape: {name?: any, percentPromotedItems?: any, filterArn?: any, filterValues?: any}
]: any -> record<itemList: record, recommendationId: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/recommendations")
  let req_body = {"campaignArn": $campaign_arn, "itemId": $item_id, "userId": $user_id, "numResults": $num_results, "context": $context, "filterArn": $filter_arn, "filterValues": $filter_values, "recommenderArn": $recommender_arn, "promotions": $promotions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Amz-Content-Sha256": $x_amz_content_sha256, "X-Amz-Date": $x_amz_date, "X-Amz-Algorithm": $x_amz_algorithm, "X-Amz-Credential": $x_amz_credential, "X-Amz-Security-Token": $x_amz_security_token, "X-Amz-Signature": $x_amz_signature, "X-Amz-SignedHeaders": $x_amz_signed_headers} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
