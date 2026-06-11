# Auto-generated client for Books API v3.0.0
# Source: https://api.apis.guru/v2/specs/nytimes.com/books_api/3.0.0/openapi.json
# Auth: --token flag or $env.BOOKS_API_TOKEN

const BASE_URL = "https://api.nytimes.com/svc/books/v3"
const DEFAULT_AUTH = "query-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BOOKS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api-key" => { {headers: {}, query: $"api-key=($token_val)"} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://api.nytimes.com/svc/books/v3"] }
def auth-scheme-completer [] { ["query-api-key"] }

# Completers for enum parameters
def sort-order-completer [] { ["ASC" "DESC"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "lists-format lists-format" } } | get name | first)
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

# Best Seller List
#
# GET /lists.{format}
# operationId: GET_lists-format
export def "lists-format lists-format" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --list: string # The name of the Times best-seller list. To get valid values, use a list names request.  Be sure to replace spaces with hyphens (e.g., e-book-fiction or hardcover-fiction, not E-Book Fiction or Hardcover Fiction). (The parameter is not case sensitive.)
  --weeks-on-list: int # The number of weeks that the best seller has been on list-name, as of bestsellers-date
  --bestsellers-date: string # YYYY-MM-DD  The week-ending date for the sales reflected on list-name. Times best-seller lists are compiled using available book sale data. The bestsellers-date may be significantly earlier than published-date. For additional information, see the explanation at the bottom of any best-seller list page on NYTimes.com (example: Hardcover Fiction, published Dec. 5 but reflecting sales to Nov. 29). (format: date-time)
  --date: string # YYYY-MM-DD  The date the best-seller list was published on NYTimes.com (compare bestsellers-date)
  --isbn: string # International Standard Book Number, 10 or 13 digits
  --published-date: string # YYYY-MM-DD  The date the best-seller list was published on NYTimes.com (compare bestsellers-date)
  --rank: int # The rank of the best seller on list-name as of bestsellers-date
  --rank-last-week: int # The rank of the best seller on list-name one week prior to bestsellers-date
  --offset: int # Sets the starting point of the result set
  --sort-order: string@sort-order-completer # Sets the sort order of the result set
]: nothing -> record<copyright: string, last_modified: string, num_results: int, results: table<amazon_product_url: string, asterisk: int, bestsellers_date: string, book_details: list, dagger: int, display_name: string, isbns: list, list_name: string, published_date: string, rank: int, rank_last_week: int, reviews: list, weeks_on_list: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "list" $list "scalar") (serialize-qp "weeks-on-list" $weeks_on_list "scalar") (serialize-qp "bestsellers-date" $bestsellers_date "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "isbn" $isbn "scalar") (serialize-qp "published-date" $published_date "scalar") (serialize-qp "rank" $rank "scalar") (serialize-qp "rank-last-week" $rank_last_week "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort-order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists.($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Best Seller History List
#
# GET /lists/best-sellers/history.json
# operationId: GET_lists-best-sellers-history-json
export def "lists-best-sellers-historyjson lists-best-sellers-history-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --age-group: string # The target age group for the best seller.
  --author: string # The author of the best seller. The author field does not include additional contributors (see Data Structure for more details about the author and contributor fields).  When searching the author field, you can specify any combination of first, middle and last names.  When sort-by is set to author, the results will be sorted by author's first name. 
  --contributor: string # The author of the best seller, as well as other contributors such as the illustrator (to search or sort by author name only, use author instead).  When searching, you can specify any combination of first, middle and last names of any of the contributors.  When sort-by is set to contributor, the results will be sorted by the first name of the first contributor listed. 
  --isbn: string # International Standard Book Number, 10 or 13 digits  A best seller may have both 10-digit and 13-digit ISBNs, and may have multiple ISBNs of each type. To search on multiple ISBNs, separate the ISBNs with semicolons (example: 9780446579933;0061374229).
  --price: string # The publisher's list price of the best seller, including decimal point
  --publisher: string # The standardized name of the publisher
  --title: string # The title of the best seller  When searching, you can specify a portion of a title or a full title.
]: nothing -> record<copyright: string, num_results: int, results: table<age_group: string, author: string, contributor: string, contributor_note: string, description: string, isbns: list, price: int, publisher: string, ranks_history: list, reviews: list, title: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "age-group" $age_group "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "contributor" $contributor "scalar") (serialize-qp "isbn" $isbn "scalar") (serialize-qp "price" $price "scalar") (serialize-qp "publisher" $publisher "scalar") (serialize-qp "title" $title "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lists/best-sellers/history.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Best Seller List Names
#
# GET /lists/names.{format}
# operationId: GET_lists-names-format
export def "lists-names-format lists-names-format" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-key: string
]: nothing -> record<copyright: string, num_results: int, results: table<display_name: string, list_name: string, list_name_encoded: string, newest_published_date: string, oldest_published_date: string, updated: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/names.($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Best Seller List Overview
#
# GET /lists/overview.{format}
# operationId: GET_lists-overview-format
export def "lists-overview-format lists-overview-format" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --published-date: string # The best-seller list publication date. YYYY-MM-DD  You do not have to specify the exact date the list was published. The service will search forward (into the future) for the closest publication date to the date you specify. For example, a request for lists/overview/2013-05-22 will retrieve the list that was published on 05-26.  If you do not include a published_date, the current week's best-sellers lists will be returned.
  --api-key: string
]: nothing -> record<copyright: string, num_results: int, results: record<bestsellers_date: string, lists: list<record>, published_date: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "published_date" $published_date "scalar") (serialize-qp "api-key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/overview.($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Best Seller List by Date
#
# GET /lists/{date}/{list}.json
# operationId: GET_lists-date-list-json
export def "lists lists-date-list-json" [
  date: string
  list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isbn: int # International Standard Book Number, 10 or 13 digits
  --list-name: string # The name of the Times best-seller list. To get valid values, use a list names request.  Be sure to replace spaces with hyphens (e.g., e-book-fiction or hardcover-fiction, not E-Book Fiction or Hardcover Fiction). (The parameter is not case sensitive.)
  --published-date: string # YYYY-MM-DD  The date the best-seller list was published on NYTimes.com (compare bestsellers-date) (format: date-time)
  --bestsellers-date: string # YYYY-MM-DD  The week-ending date for the sales reflected on list-name. Times best-seller lists are compiled using available book sale data. The bestsellers-date may be significantly earlier than published-date. For additional information, see the explanation at the bottom of any best-seller list page on NYTimes.com (example: Hardcover Fiction, published Dec. 5 but reflecting sales to Nov. 29).
  --weeks-on-list: int # The number of weeks that the best seller has been on list-name, as of bestsellers-date
  --rank: string # The rank of the best seller on list-name as of bestsellers-date
  --rank-last-week: int # The rank of the best seller on list-name one week prior to bestsellers-date
  --offset: int # Sets the starting point of the result set
  --sort-order: string@sort-order-completer # The default is ASC (ascending). The sort-order parameter is used with the sort-by parameter — for details, see each request type.
]: nothing -> record<copyright: string, last_modified: string, num_results: int, results: record<bestsellers_date: string, books: list<record>, corrections: list<record>, display_name: string, list_name: string, normal_list_ends_at: int, published_date: string, updated: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isbn" $isbn "scalar") (serialize-qp "list-name" $list_name "scalar") (serialize-qp "published-date" $published_date "scalar") (serialize-qp "bestsellers-date" $bestsellers_date "scalar") (serialize-qp "weeks-on-list" $weeks_on_list "scalar") (serialize-qp "rank" $rank "scalar") (serialize-qp "rank-last-week" $rank_last_week "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort-order" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lists/($date)/($list).json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reviews
#
# GET /reviews.{format}
# operationId: GET_reviews-format
export def "reviews-format reviews-format" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isbn: int # Searching by ISBN is the recommended method. You can enter 10- or 13-digit ISBNs.
  --title: string # You’ll need to enter the full title of the book. Spaces in the title will be converted into the characters %20.
  --author: string # You’ll need to enter the author’s first and last name, separated by a space. This space will be converted into the characters %20.
  --api-key: string
]: nothing -> record<copyright: string, num_results: int, results: table<book_author: string, book_title: string, byline: string, isbn13: list, publication_dt: string, summary: string, url: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isbn" $isbn "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "api-key" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/reviews.($format)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
