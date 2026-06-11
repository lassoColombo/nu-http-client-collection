# Auto-generated client for Search API v2.0
# Source: https://raw.githubusercontent.com/yext/openapi/main/yaml/answersapi.yaml
# Auth: --token flag or $env.SEARCH_API_TOKEN

const BASE_URL = "https://cdn.yextapis.com/v2"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
    "api-key" => { {headers: {api-key: $token_val}, query: ""} }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://cdn.yextapis.com/v2"] }
def auth-scheme-completer [] { ["query-api_key" "api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts-search-autocomplete autocomplete" } } | get name | first)
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

# Universal Search: Autocomplete
#
# GET /accounts/{accountId}/search/autocomplete
# operationId: autocomplete
export def "accounts-search-autocomplete autocomplete" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --v: string # A date in `YYYYMMDD` format.
  --experienceKey: string # String key that uniquely identifies the Search experience.
  --locale: string # The locale code of the experience (e.g. `en_GB`).
  --input: string # The partial search term from the user.
  --limit: int # Number of autocomplete results to return. (default: 10)
  --version: string # The label or version number of the experience configuration to use. Label options are `STAGING` or `PRODUCTION`. `STAGING` uses the Latest version of the configuration. If omitted the `PRODUCTION` label will be used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "experienceKey" $experienceKey "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/search/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Universal Search: Query
#
# GET /accounts/{accountId}/search/query
# operationId: query
export def "accounts-search-query query" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --v: string # A date in `YYYYMMDD` format.
  --experienceKey: string # String key that uniquely identifies the Search experience.
  --locale: string # The locale code of the experience (e.g. `en_GB`). Only returns entities that have an entity profile associated with this locale.
  --input: string # The search term of the user.
  --version: string # The label or version number of the experience configuration to use. Label options are `STAGING` or `PRODUCTION`. `STAGING` uses the Latest version of the configuration. If omitted the `PRODUCTION` label will be used.
  --location: string # The user's location as a comma separated latitude and longitude (e.g. `"40.740957,-73.987565"`).
  --session-id: string # UUID used to track session state when cookies are blocked.
  --limit: string # JSON object specifying the limit for each vertical.  Each key is a vertical key and the value for each of those keys is a number 1-50 that denotes the limit for that vertical. This parameter should be provided as a URL-encoded string containing a JSON object.
  --queryTrigger: string # String value that is logged to analytics denoting the trigger for the query. Options include: * `suggest`, sent if the query is triggered from a spelling correction. * `initialize`, sent if the query is being triggered by a default initial search (in other words, the user did not enter query).
  --context: string # Context is an arbitrary JSON object that is passed to query rules to be used for triggering rules as well as passing data to those rules. This parameter should be provided as a URL-encoded string containing a JSON object.
  --referrerPageUrl: string # The URL of the webpage that directed to the page this request was made from.
  --skipSpellCheck: string@bool-completer # If true the query will skip spell checking.
  --restrictVerticals: string # A comma-separated list of verticals (e.g. `"people,locations"`). If specified, only results from these verticals will be returned.
  --ignoreQueryRules: string@bool-completer # When set to true, ignores any Query Rules that would otherwise affect the results. Defaults to false.
  --queryId: string # UUID of the query; recommended when moving through results, to associate multiple requests to the same query.
  --qp-source: string # Indicates where the query is coming from (e.g. `"HOME_HEADER"` or `"TICKET_FORM"`). Can be used in Analytics reports via the `Integration Source` dimension. Defaults to `"STANDARD"`.
  --jsLibVersion: string # The version of the Search UI used for this request. Deprecated.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "experienceKey" $experienceKey "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "queryTrigger" $queryTrigger "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "referrerPageUrl" $referrerPageUrl "scalar") (serialize-qp "skipSpellCheck" $skipSpellCheck "scalar") (serialize-qp "restrictVerticals" $restrictVerticals "scalar") (serialize-qp "ignoreQueryRules" $ignoreQueryRules "scalar") (serialize-qp "queryId" $queryId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "jsLibVersion" $jsLibVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/search/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Vertical Search: Autocomplete
#
# GET /accounts/{accountId}/search/vertical/autocomplete
# operationId: verticalAutocomplete
export def "accounts-search-vertical-autocomplete verticalAutocomplete" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --v: string # A date in `YYYYMMDD` format.
  --experienceKey: string # String key that uniquely identifies the Search experience.
  --verticalKey: string # String key that uniquely identifies the vertical.
  --locale: string # The locale code of the experience (e.g. `en_GB`).
  --input: string # The partial search term from the user.
  --limit: int # Number of autocomplete results to return. (default: 10)
  --version: string # The label or version number of the experience configuration to use. Label options are `STAGING` or `PRODUCTION`. `STAGING` uses the Latest version of the configuration. If omitted the `PRODUCTION` label will be used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "experienceKey" $experienceKey "scalar") (serialize-qp "verticalKey" $verticalKey "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/search/vertical/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Vertical Search: Query
#
# GET /accounts/{accountId}/search/vertical/query
# operationId: verticalQuery
export def "accounts-search-vertical-query verticalQuery" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --v: string # A date in `YYYYMMDD` format.
  --experienceKey: string # String key that uniquely identifies the Search experience.
  --verticalKey: string # String key that uniquely identifies the vertical.
  --locale: string # The locale code of the experience (e.g. `en_GB`). Only returns entities that have an entity profile associated with this locale.
  --input: string # The search term of the user.
  --version: string # The label or version number of the experience configuration to use. Label options are `STAGING` or `PRODUCTION`. `STAGING` uses the Latest version of the configuration. If omitted the `PRODUCTION` label will be used.
  --location: string # The user's location as a comma separated latitude and longitude (e.g. `"40.740957,-73.987565"`).
  --locationRadius: string # Radius (in meters) that should be applied to any location filter that does not already have an explicit radius.
  --session-id: string # UUID used to track session state when cookies are blocked.
  --limit: int # Number of results to return. (default: 10)
  --offset: int # Number of results to skip. Used to move through results. (default: 0)
  --queryTrigger: string # String value that is logged to analytics denoting the trigger for the query. Options include: * `suggest`, sent if the query is triggered from a spelling correction. * `initialize`, sent if the query is being triggered by a default initial search (in other words, the user did not enter query).
  --context: string # Context is an arbitrary JSON object that is passed to query rules to be used for triggering rules as well as passing data to those rules. This parameter should be provided as a URL-encoded string containing a JSON object.
  --referrerPageUrl: string # The URL of the webpage that directed to the page this request was made from.
  --skipSpellCheck: string@bool-completer # If true the query will skip spell checking.
  --filters: string # This parameter represents one or more filtering conditions that are applied to the set of entities that would otherwise be returned. This parameter should be provided as a URL-encoded string containing a JSON object.  For example, if the filter JSON is `{"name":{"$eq":"John"}}`, then the filters param after URL-encoding will be: `filters=%7B%22name%22%3A%7B%22%24eq%22%3A%22John%22%7D%7D`  **Basic Filter Structure**  The filter object at its core consists of a *matcher*, a *field*, and an *argument*.  For example, in the following filter JSON:  ``` {   "name":{     "$eq":"John"   } } ```  `$eq` is the *matcher*, or filtering operation (equals, in this example),  `name` is the *field* being filtered by, and  `John` is *value* to be matched against.  **Combining Multiple Filters**  Multiple filters can be combined to form a conjunction (AND) of disjunctions (ORs) using the *combinators* `$and` and `$or`.  For example: ``` {   "$and": [     {       "$or": [         {           "firstName": {             "$eq": "Jane"           }         },         {           "firstName": {             "$eq": "John"           }         }       ]     },     {       "lastName": {         "$eq": "Smith"       }     }   ] } ``` Any filter that is the only item in its respective combinator may omit the combinator as is done with the lastName above.  **Filter Negation**  Certain filter types may be negated. For example:  ``` {   "$not": {     "name": {       "$eq": "John"     }   } } ```  This can also be written more simply with a `!` in the `$eq` parameter. The following filter would have the same effect:  ``` {   "name":{     "!$eq":"John"   } } ```  **TEXT**  The `TEXT` filter type is supported for text fields. (e.g., **`name`**, **`countryCode`**)  <table style="width:100%">   <tr>     <th>Matcher</th>     <th>Details</th>   </tr>   <tr>     <th>$eq (equals)</th>     <th>      {       "countryCode":{         "$eq":"US"       }     },     {       "countryCode":{         "!$eq":"US"       }     }    Supports negation. Case insensitive.   </tr>   <tr> </table>  **BOOLEAN**   The BOOLEAN filter type is supported for boolean fields and Yes / No custom fields. <table style="width:100%">   <tr>     <th>Matcher</th>     <th>Details</th>   </tr>   <tr>     <th>$eq</th>     <th>      {       "isFreeEvent": {         "$eq": true       }     }    For booleans, the filter takes a boolean value, not a string.   Supports negation.   </tr> </table>  **OPTION**  The OPTION filter type is supported for option custom fields and fields that have a predetermined list of valid values.   *e.g., **`eventStatus`**, **`gender`**, `SINGLE_OPTION` and `MULTI_OPTION` types of custom fields.*  <table style="width:100%">   <tr>     <th>Matcher</th>     <th>Details</th>   </tr>   <tr>     <th>$eq</th>     <th>    Matching is case insensitive and insensitive to consecutive whitespace.    e.g., "XYZ 123" matches "xyz       123"      {       "eventStatus": {         "$eq": "SCHEDULED"       }     } </table>  **INTEGER, FLOAT, DATE, DATETIME, and TIME**  These filter types are strictly ordered -- therefore, they support the following matchers: - Equals - Less Than / Less Than or Equal To - Greater Than / Greater Than or Equal To  <table style="width:100%">   <tr>     <th>Matcher</th>     <th>Details</th>   </tr>   <tr>     <th>$eq</th>     <th>    Equals      {       "ageRange.maxValue": {         "$eq": "80"       }     }    Supports negation.    </tr>   <tr>     <th>$lt</th>     <th>    Less than      {       "time.start": {         "$lt": "2018-08-28T05:56"       }     }    </tr>   <tr>     <th>$gt</th>     <th>    Greater than      {       "ageRange.maxValue": {         "$gt": "50"       }     }    </tr>   <tr>     <th>$le</th>     <th>    Less than or equal to      {       "ageRange.maxValue": {         "$le": "40"       }     }    </tr>   <tr>     <th>$ge</th>     <th>    Greater than or equal to      {       "time.end": {         "$ge":  "2018-08-28T05:56"       }     }    </tr>   <tr>     <th>$between</th>     <th>    An array that must contain exactly two elements with which the result is between.      {       "time.end": {         "$between":  ["2018-08-28T05:56", "2018-08-29T05:56"]       }     }    </tr>   <tr>     <th>Combinations</th>     <th>    In addition to between, it is possible to combine multiple matchers for a result similar to an "and" operation:      {       "ageRange.maxValue" : {         "$gt" : 10,         "$lt": 20       }     }    </tr> </table>
  --facetFilters: string # This parameter represents the state of the currently checked facet options. This parameter should be provided as a URL-encoded string containing a JSON object.  The JSON object contains a key for each facet category that has a checked facet option.  The value for each of these keys is an array of Filter objects that describe the filter that is applied by the facet option.  At the moment, facet options only support `$eq`.  For example, if `Engineering` was checked under the `Category` facet and `Chicago` and `New York` are checked under the `Job Location` facet, the `facetFilters` would look like: ``` {   "c_jobCategory": [     {       "c_jobCategory": {         "$eq": "Engineering"       }     }   ],   "c_jobLocation": [     {       "c_jobLocation": {         "$eq": "Chicago"       }     },     {       "c_jobLocation": {         "$eq": "New York"       }     }   ] } ```
  --retrieveFacets: string@bool-completer # Whether facets should be computed for this vertical query.
  --sortBys: string # This parameter overrides the sort options that are configured on the experience configuration.  This parameter should be provided as a URL-encoded string containing a JSON array.  The input is a JSON array containing each of the sort options in the order in which they should be applied.  Each sort options must contain a `type`  <table style="width:100%">   <tr>     <th>Type</th>     <th>Details</th>   </tr>   <tr>     <th>RELEVANCE</th>     <th>Sorts based on relevance according to the algorithm and, when relevant, location bias</th>   </tr>   <tr>     <th>ENTITY_DISTANCE</th>     <th>Sorts based on entity distance alone</th>   </tr>   <tr>     <th>FIELD</th>     <th>sorts based on a field with the direction specified</th>   </tr> </table>  </br>  If the `type` is `FIELD` the sort options must also specify `field` which is the api name of the field to sort on.  Finally, if the `type` is `FIELD` the sort options must also specify the `direction`.  <table style="width:100%">   <tr>     <th>Direction</th>     <th>Details</th>   </tr>   <tr>     <th>ASC</th>     <th>Sorts in ascending order.  For numbers this is low to high. For text this is alphabetical.  For dates this is chronological order.</th>   </tr>   <tr>     <th>DESC</th>     <th>Sorts in ascending order.  For numbers this is high to low. For text this is reverse alphabetical.  For dates this is reverse chronological order.</th>   </tr> </table>  </br>  **Examples** ``` [   {     "type": "FIELD",     "direction": "ASC",     "field": "startDate"   },   {     "type": "RELEVANCE",     "direction": "ASC"   } ] ```
  --ignoreQueryRules: string@bool-completer # When set to true, ignores any Query Rules that would otherwise affect the results. Defaults to false.
  --queryId: string # UUID of the query; recommended when moving through results, to associate multiple requests to the same query.
  --qp-source: string # Indicates where the query is coming from (e.g. `"HOME_HEADER"` or `"TICKET_FORM"`). Can be used in Analytics reports via the `Integration Source` dimension. Defaults to `"STANDARD"`.
  --jsLibVersion: string # The version of the Search UI used for this request. Deprecated.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "experienceKey" $experienceKey "scalar") (serialize-qp "verticalKey" $verticalKey "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "locationRadius" $locationRadius "scalar") (serialize-qp "session_id" $session_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "queryTrigger" $queryTrigger "scalar") (serialize-qp "context" $context "scalar") (serialize-qp "referrerPageUrl" $referrerPageUrl "scalar") (serialize-qp "skipSpellCheck" $skipSpellCheck "scalar") (serialize-qp "filters" $filters "scalar") (serialize-qp "facetFilters" $facetFilters "scalar") (serialize-qp "retrieveFacets" $retrieveFacets "scalar") (serialize-qp "sortBys" $sortBys "scalar") (serialize-qp "ignoreQueryRules" $ignoreQueryRules "scalar") (serialize-qp "queryId" $queryId "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "jsLibVersion" $jsLibVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/search/vertical/query" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Vertical Search: Filter Search
#
# GET /accounts/{accountId}/search/filtersearch
# operationId: filtersearch
export def "accounts-search-filtersearch filtersearch" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --v: string # A date in `YYYYMMDD` format.
  --experienceKey: string # String key that uniquely identifies the Search experience.
  --verticalKey: string # String key that uniquely identifies the vertical to scope the filter search request to.
  --locale: string # The locale code of the experience (e.g. `en_GB`).
  --input: string # The search term of the user.
  --search-parameters: string # This parameter represents the parameters that should be used for filter search. This parameter should be provided as a URL-encoded string containing a JSON object.  Filter search uses the user's input string to find a set of existing filters that match the user's input query for the fields provided in the parameters.  The JSON object must have a `fields` property made up of a list of `FilterField` objects that have the following properties:  <table style="width:100%">   <tr>     <th>Property</th>     <th>Details</th>   </tr>   <tr>     <th>fieldId</th>     <th>The api name of the field.</th>   </tr>   <tr>     <th>entityTypeId</th>     <th>The api name for the entity type the filter belongs to.</th>   </tr>   <tr>     <th>shouldFetchEntities</th>     <th>Optional boolean.  If true, entities matching each filter will be returned inline with the filter.</th>   </tr> </table>  </br>  Additionally, there is an optional boolean property `sectioned`.  If set to true, the matching filters will be returned in a separate section per field.  By default, they are all returned in the same section.
  --version: string # The label or version number of the experience configuration to use. Label options are `STAGING` or `PRODUCTION`. `STAGING` uses the Latest version of the configuration. If omitted the `PRODUCTION` label will be used.
  --excluded: string # This parameter represents any values which should not be returned. This parameter should be provided as a URL-encoded string containing a JSON array, where each entry of the array is a JSON object representing a field and an excluded value for that field. For example: ``` [   {     "name": {       "$eq": "John"     }   },   {     "c_jobCategory": {       "$eq": "Engineering"     }   } ] ```
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "experienceKey" $experienceKey "scalar") (serialize-qp "verticalKey" $verticalKey "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "input" $input "scalar") (serialize-qp "search_parameters" $search_parameters "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "excluded" $excluded "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/search/filtersearch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Answer: Generate
#
# POST /accounts/{accountId}/search/generateAnswer
# operationId: generateAnswer
export def "accounts-search-generate-answer generateAnswer" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --v: string # A date in `YYYYMMDD` format.
  --experienceKey: string # String key that uniquely identifies the Search experience.
  --locale: string # The locale code of the experience (e.g. `en_GB`). Only returns entities that have an entity profile associated with this locale.
  searchId: string # ID of the search associated to the results.
  searchTerm: string # The search term that was used to generate results.
  results: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "experienceKey" $experienceKey "scalar") (serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/search/generateAnswer" $qp)
  let body = {searchId: $searchId, searchTerm: $searchTerm, results: $results} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
