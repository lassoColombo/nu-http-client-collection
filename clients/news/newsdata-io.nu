# Auto-generated client for NewsData.io API v1.0.0
# Source: https://newsdata.io/openapi.json
# Auth: --token flag or $env.NEWSDATA_IO_API_TOKEN

const BASE_URL = "https://newsdata.io/api"
const DEFAULT_AUTH = "query-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NEWSDATA_IO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
    "x-access-key" => { {headers: {X-ACCESS-KEY: $token_val}, query: ""} }
    "query-access_key" => { {headers: {}, query: $"access_key=($token_val)"} }
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

def base-url-completer [] { ["https://newsdata.io/api"] }
def auth-scheme-completer [] { ["query-apikey" "x-access-key" "query-access_key"] }

# Completers for enum parameters
def prioritydomain-completer [] { ["low" "medium" "top"] }
def image-completer [] { ["0" "1"] }
def video-completer [] { ["0" "1"] }
def full-content-completer [] { ["0" "1"] }
def removeduplicate-completer [] { ["0" "1"] }
def sentiment-completer [] { ["negative" "neutral" "positive"] }
def sort-completer [] { ["fetched_at" "pubdateasc" "pubdatedesc" "relevancy" "source"] }
def adv-completer [] { ["0" "1"] }
def webhook-completer [] { ["0" "1"] }
def interval-completer [] { ["all" "day" "hour"] }
def sort-completer-1 [] { ["pubdateasc" "pubdatedesc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "1 get" } } | get name | first)
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

# Liveness probe
#
# GET /1/
# operationId: getHello
export def "1 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Latest news articles
#
# GET /1/latest
# operationId: getLatest
export def "1-latest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --q: string # Free-text query, matched against `title`, `link`, `full_description`, `description`, `content`, `keywords` with AND-default operator. Maximum length is governed by the user's `q_limit` (default 100). Reserved Elasticsearch characters (`+ - = & | > < ! { } [ ] ^ ~ * ? : \ /`) are auto-escaped. Mutually exclusive with `qInTitle` and `qInMeta`.
  --qInTitle: string # Free-text query, matched against `title` only. Mutually exclusive with `q` and `qInMeta`.
  --qInMeta: string # Free-text query, matched against `title`, `link`, `description`, and `keywords`. Mutually exclusive with `q` and `qInTitle`.
  --country: list # Comma-separated ISO 3166-1 alpha-2 country codes. Max `filter_limit` values (default 5). Mutually exclusive with `excludecountry`.
  --excludecountry: list # Comma-separated ISO country codes to exclude. Mutually exclusive with `country`.
  --category: list # Comma-separated category names. Mutually exclusive with `excludecategory`.
  --excludecategory: list # Comma-separated category names to exclude. Mutually exclusive with `category`.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --excludelanguage: list # Comma-separated language codes to exclude. Mutually exclusive with `language`.
  --domain: list # Comma-separated source identifiers (canonical `name` values from `/1/sources`). Mutually exclusive with `domainurl` and `excludedomain`.
  --domainurl: list # Comma-separated source domain URLs (e.g. `bbc.com`). Mutually exclusive with `domain` and `excludedomain`.
  --excludedomain: list # Comma-separated source URLs to exclude. Mutually exclusive with `domain` and `domainurl`.
  --prioritydomain: string@prioritydomain-completer # Restrict to a source-priority tier. `top` = priorities 0–13000, `medium` = 0–200000, `low` = 0–600000.
  --id: list # Comma-separated `article_id` values (32-character hex). Mutually exclusive with EVERY other filter except `apikey`. Maximum number of IDs equals the caller's `max_response_limit` (default 50 paid, 10 free).
  --qp-url: string # Filter to a specific article URL. Tracking parameters (utm_*, fbclid, gclid, etc.) are stripped server-side. Mutually exclusive with EVERY other filter except `apikey`. Max length 512. (format: uri)
  --timeframe: string # Relative window ending at `now`. Integer = hours (1–48). Integer suffixed with `m` = minutes (1–2880). Mutually exclusive with `from_date` and `to_date`. Not available to free callers.
  --timezone: string # IANA timezone name. When set, `pubDate` and `fetched_at` in the response are converted to this zone and `pubDateTZ` carries the zone name. Default `UTC`.
  --image: string@image-completer # `1` → only articles that have an image; `0` → strip `image_url` from response. Default `1`.
  --video: string@video-completer # `1` → only articles that have a video; `0` → strip `video_url` from response.
  --full-content: string@full-content-completer # `1` → require articles to have full extracted content; `0` → strip `content`. Requires the `is_full_content_user` plan flag.
  --removeduplicate: string@removeduplicate-completer # `1` → exclude articles marked as duplicates (`is_duplicate=true`). Only applies to data from 2024-07-24 onward.
  --sentiment: string@sentiment-completer # Filter on dominant sentiment label. Requires the `is_ml_access` plan flag ∈ {1, 2}. Only applies to data from 2024-01-12 onward.
  --sentiment-score: float # Minimum confidence for the chosen `sentiment` (1–100, two-decimal precision). Requires `sentiment` to also be set.
  --tag: list # Comma-separated ML-derived topic tags (e.g. `politics,technology`). Requires `is_ml_access` ∈ {1, 2}. Only applies to data from 2024-01-12 onward. Tag vocabulary differs for crypto vs general news.
  --region: list # Comma-separated ML-extracted geographic regions. Each value may itself contain `-`-joined sub-regions (`paris-france`). Requires `is_ml_access` = 2. Only applies to data from 2024-01-29 onward.
  --organization: list # Comma-separated ML-extracted organization names. Requires `is_ml_access` = 2. Only applies to data from 2024-05-24 onward.
  --creator: list # Comma-separated author/byline names.
  --datatype: list # Comma-separated source types (e.g. `news, blog, podcast`). Only applies to data from 2025-11-28 onward.
  --size: int # Number of articles per page. 1 to `max_response_limit` (50 paid, 10 free).
  --page: string # Pagination cursor. For `sort=pubdateasc|pubdatedesc` (default), pass the value of the previous response's `nextPage` (an opaque 19-character timestamp). For `sort=relevancy|source|fetched_at`, pass an integer page number (max `10000 / size`).
  --qp-sort: string@sort-completer # Result ordering. `pubdatedesc` (default) and `pubdateasc` use cursor pagination; the others use integer pagination with a 10k-result ceiling. (default: pubdatedesc)
  --adv: string@adv-completer # `1` → response includes the `*_id` fields (`link_hash`, `domain_id`, `country_id`, `category_id`, `language_id`). Default `0`.
  --excludefield: list # Comma-separated response field names to omit. `article_id` cannot be excluded. Only fields listed in this endpoint's response model are accepted.
  --webhook: string@webhook-completer # `1` → on any non-200 response, the HTTP status is rewritten to 202 (the JSON body is unchanged). Used by webhook delivery systems that treat 4xx/5xx as terminal.
]: nothing -> record<status: string, totalResults: int, results: table<article_id: string, link_hash: string, link: string, title: string, description: string, content: string, keywords: list, creator: list, language: string, language_id: int, country: list, country_id: list, category: list, category_id: list, datatype: string, pubDate: string, pubDateTZ: string, fetched_at: string, image_url: string, video_url: string, source_id: string, domain_id: int, source_name: string, source_priority: int, source_url: string, source_icon: string, sentiment: string, sentiment_stats: any, ai_tag: list, ai_region: list, ai_org: list, ai_summary: string, duplicate: bool>, nextPage: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "qInTitle" $qInTitle "scalar") (serialize-qp "qInMeta" $qInMeta "scalar") (serialize-qp "country" $country "csv") (serialize-qp "excludecountry" $excludecountry "csv") (serialize-qp "category" $category "csv") (serialize-qp "excludecategory" $excludecategory "csv") (serialize-qp "language" $language "csv") (serialize-qp "excludelanguage" $excludelanguage "csv") (serialize-qp "domain" $domain "csv") (serialize-qp "domainurl" $domainurl "csv") (serialize-qp "excludedomain" $excludedomain "csv") (serialize-qp "prioritydomain" $prioritydomain "scalar") (serialize-qp "id" $id "csv") (serialize-qp "url" $qp_url "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "video" $video "scalar") (serialize-qp "full_content" $full_content "scalar") (serialize-qp "removeduplicate" $removeduplicate "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "sentiment_score" $sentiment_score "scalar") (serialize-qp "tag" $tag "csv") (serialize-qp "region" $region "csv") (serialize-qp "organization" $organization "csv") (serialize-qp "creator" $creator "csv") (serialize-qp "datatype" $datatype "csv") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "adv" $adv "scalar") (serialize-qp "excludefield" $excludefield "csv") (serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Latest news articles (alias of /1/latest)
#
# GET /1/news
# DEPRECATED
# operationId: getNewsAlias
@deprecated
export def "1-news get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --q: string # Free-text query, matched against `title`, `link`, `full_description`, `description`, `content`, `keywords` with AND-default operator. Maximum length is governed by the user's `q_limit` (default 100). Reserved Elasticsearch characters (`+ - = & | > < ! { } [ ] ^ ~ * ? : \ /`) are auto-escaped. Mutually exclusive with `qInTitle` and `qInMeta`.
  --country: list # Comma-separated ISO 3166-1 alpha-2 country codes. Max `filter_limit` values (default 5). Mutually exclusive with `excludecountry`.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --size: int # Number of articles per page. 1 to `max_response_limit` (50 paid, 10 free).
  --page: string # Pagination cursor. For `sort=pubdateasc|pubdatedesc` (default), pass the value of the previous response's `nextPage` (an opaque 19-character timestamp). For `sort=relevancy|source|fetched_at`, pass an integer page number (max `10000 / size`).
]: nothing -> record<status: string, totalResults: int, results: table<article_id: string, link_hash: string, link: string, title: string, description: string, content: string, keywords: list, creator: list, language: string, language_id: int, country: list, country_id: list, category: list, category_id: list, datatype: string, pubDate: string, pubDateTZ: string, fetched_at: string, image_url: string, video_url: string, source_id: string, domain_id: int, source_name: string, source_priority: int, source_url: string, source_icon: string, sentiment: string, sentiment_stats: any, ai_tag: list, ai_region: list, ai_org: list, ai_summary: string, duplicate: bool>, nextPage: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "country" $country "csv") (serialize-qp "language" $language "csv") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/news" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Historical news archive
#
# GET /1/archive
# operationId: getArchive
export def "1-archive get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --q: string # Free-text query, matched against `title`, `link`, `full_description`, `description`, `content`, `keywords` with AND-default operator. Maximum length is governed by the user's `q_limit` (default 100). Reserved Elasticsearch characters (`+ - = & | > < ! { } [ ] ^ ~ * ? : \ /`) are auto-escaped. Mutually exclusive with `qInTitle` and `qInMeta`.
  --qInTitle: string # Free-text query, matched against `title` only. Mutually exclusive with `q` and `qInMeta`.
  --qInMeta: string # Free-text query, matched against `title`, `link`, `description`, and `keywords`. Mutually exclusive with `q` and `qInTitle`.
  --country: list # Comma-separated ISO 3166-1 alpha-2 country codes. Max `filter_limit` values (default 5). Mutually exclusive with `excludecountry`.
  --excludecountry: list # Comma-separated ISO country codes to exclude. Mutually exclusive with `country`.
  --category: list # Comma-separated category names. Mutually exclusive with `excludecategory`.
  --excludecategory: list # Comma-separated category names to exclude. Mutually exclusive with `category`.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --excludelanguage: list # Comma-separated language codes to exclude. Mutually exclusive with `language`.
  --domain: list # Comma-separated source identifiers (canonical `name` values from `/1/sources`). Mutually exclusive with `domainurl` and `excludedomain`.
  --domainurl: list # Comma-separated source domain URLs (e.g. `bbc.com`). Mutually exclusive with `domain` and `excludedomain`.
  --excludedomain: list # Comma-separated source URLs to exclude. Mutually exclusive with `domain` and `domainurl`.
  --prioritydomain: string@prioritydomain-completer # Restrict to a source-priority tier. `top` = priorities 0–13000, `medium` = 0–200000, `low` = 0–600000.
  --id: list # Comma-separated `article_id` values (32-character hex). Mutually exclusive with EVERY other filter except `apikey`. Maximum number of IDs equals the caller's `max_response_limit` (default 50 paid, 10 free).
  --qp-url: string # Filter to a specific article URL. Tracking parameters (utm_*, fbclid, gclid, etc.) are stripped server-side. Mutually exclusive with EVERY other filter except `apikey`. Max length 512. (format: uri)
  --from-date: string # Lower bound on `pubDate`. ISO 8601 in UTC (`YYYY-MM-DD HH:MM:SS`). Cannot be in the future. Non-admin callers cannot go back further than their plan `timeperiod`. (format: date-time)
  --to-date: string # Upper bound on `pubDate`. ISO 8601 in UTC. Cannot be in the future. (format: date-time)
  --timezone: string # IANA timezone name. When set, `pubDate` and `fetched_at` in the response are converted to this zone and `pubDateTZ` carries the zone name. Default `UTC`.
  --image: string@image-completer # `1` → only articles that have an image; `0` → strip `image_url` from response. Default `1`.
  --video: string@video-completer # `1` → only articles that have a video; `0` → strip `video_url` from response.
  --full-content: string@full-content-completer # `1` → require articles to have full extracted content; `0` → strip `content`. Requires the `is_full_content_user` plan flag.
  --removeduplicate: string@removeduplicate-completer # `1` → exclude articles marked as duplicates (`is_duplicate=true`). Only applies to data from 2024-07-24 onward.
  --sentiment: string@sentiment-completer # Filter on dominant sentiment label. Requires the `is_ml_access` plan flag ∈ {1, 2}. Only applies to data from 2024-01-12 onward.
  --sentiment-score: float # Minimum confidence for the chosen `sentiment` (1–100, two-decimal precision). Requires `sentiment` to also be set.
  --tag: list # Comma-separated ML-derived topic tags (e.g. `politics,technology`). Requires `is_ml_access` ∈ {1, 2}. Only applies to data from 2024-01-12 onward. Tag vocabulary differs for crypto vs general news.
  --region: list # Comma-separated ML-extracted geographic regions. Each value may itself contain `-`-joined sub-regions (`paris-france`). Requires `is_ml_access` = 2. Only applies to data from 2024-01-29 onward.
  --organization: list # Comma-separated ML-extracted organization names. Requires `is_ml_access` = 2. Only applies to data from 2024-05-24 onward.
  --creator: list # Comma-separated author/byline names.
  --datatype: list # Comma-separated source types (e.g. `news, blog, podcast`). Only applies to data from 2025-11-28 onward.
  --size: int # Number of articles per page. 1 to `max_response_limit` (50 paid, 10 free).
  --page: string # Pagination cursor. For `sort=pubdateasc|pubdatedesc` (default), pass the value of the previous response's `nextPage` (an opaque 19-character timestamp). For `sort=relevancy|source|fetched_at`, pass an integer page number (max `10000 / size`).
  --qp-sort: string@sort-completer # Result ordering. `pubdatedesc` (default) and `pubdateasc` use cursor pagination; the others use integer pagination with a 10k-result ceiling. (default: pubdatedesc)
  --adv: string@adv-completer # `1` → response includes the `*_id` fields (`link_hash`, `domain_id`, `country_id`, `category_id`, `language_id`). Default `0`.
  --excludefield: list # Comma-separated response field names to omit. `article_id` cannot be excluded. Only fields listed in this endpoint's response model are accepted.
  --webhook: string@webhook-completer # `1` → on any non-200 response, the HTTP status is rewritten to 202 (the JSON body is unchanged). Used by webhook delivery systems that treat 4xx/5xx as terminal.
]: nothing -> record<status: string, totalResults: int, results: table<article_id: string, link_hash: string, link: string, title: string, description: string, content: string, keywords: list, creator: list, language: string, language_id: int, country: list, country_id: list, category: list, category_id: list, datatype: string, pubDate: string, pubDateTZ: string, fetched_at: string, image_url: string, video_url: string, source_id: string, domain_id: int, source_name: string, source_priority: int, source_url: string, source_icon: string, sentiment: string, sentiment_stats: any, ai_tag: list, ai_region: list, ai_org: list, ai_summary: string, duplicate: bool>, nextPage: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "qInTitle" $qInTitle "scalar") (serialize-qp "qInMeta" $qInMeta "scalar") (serialize-qp "country" $country "csv") (serialize-qp "excludecountry" $excludecountry "csv") (serialize-qp "category" $category "csv") (serialize-qp "excludecategory" $excludecategory "csv") (serialize-qp "language" $language "csv") (serialize-qp "excludelanguage" $excludelanguage "csv") (serialize-qp "domain" $domain "csv") (serialize-qp "domainurl" $domainurl "csv") (serialize-qp "excludedomain" $excludedomain "csv") (serialize-qp "prioritydomain" $prioritydomain "scalar") (serialize-qp "id" $id "csv") (serialize-qp "url" $qp_url "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "video" $video "scalar") (serialize-qp "full_content" $full_content "scalar") (serialize-qp "removeduplicate" $removeduplicate "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "sentiment_score" $sentiment_score "scalar") (serialize-qp "tag" $tag "csv") (serialize-qp "region" $region "csv") (serialize-qp "organization" $organization "csv") (serialize-qp "creator" $creator "csv") (serialize-qp "datatype" $datatype "csv") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "adv" $adv "scalar") (serialize-qp "excludefield" $excludefield "csv") (serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cryptocurrency news
#
# GET /1/crypto
# operationId: getCrypto
export def "1-crypto get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --q: string # Free-text query, matched against `title`, `link`, `full_description`, `description`, `content`, `keywords` with AND-default operator. Maximum length is governed by the user's `q_limit` (default 100). Reserved Elasticsearch characters (`+ - = & | > < ! { } [ ] ^ ~ * ? : \ /`) are auto-escaped. Mutually exclusive with `qInTitle` and `qInMeta`.
  --qInTitle: string # Free-text query, matched against `title` only. Mutually exclusive with `q` and `qInMeta`.
  --qInMeta: string # Free-text query, matched against `title`, `link`, `description`, and `keywords`. Mutually exclusive with `q` and `qInTitle`.
  --coin: list # Comma-separated cryptocurrency tickers (e.g. `btc,eth`). Validated against the crypto-keyword vocabulary.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --excludelanguage: list # Comma-separated language codes to exclude. Mutually exclusive with `language`.
  --domain: list # Comma-separated source identifiers (canonical `name` values from `/1/sources`). Mutually exclusive with `domainurl` and `excludedomain`.
  --domainurl: list # Comma-separated source domain URLs (e.g. `bbc.com`). Mutually exclusive with `domain` and `excludedomain`.
  --excludedomain: list # Comma-separated source URLs to exclude. Mutually exclusive with `domain` and `domainurl`.
  --prioritydomain: string@prioritydomain-completer # Restrict to a source-priority tier. `top` = priorities 0–13000, `medium` = 0–200000, `low` = 0–600000.
  --id: list # Comma-separated `article_id` values (32-character hex). Mutually exclusive with EVERY other filter except `apikey`. Maximum number of IDs equals the caller's `max_response_limit` (default 50 paid, 10 free).
  --qp-url: string # Filter to a specific article URL. Tracking parameters (utm_*, fbclid, gclid, etc.) are stripped server-side. Mutually exclusive with EVERY other filter except `apikey`. Max length 512. (format: uri)
  --from-date: string # Lower bound on `pubDate`. ISO 8601 in UTC (`YYYY-MM-DD HH:MM:SS`). Cannot be in the future. Non-admin callers cannot go back further than their plan `timeperiod`. (format: date-time)
  --to-date: string # Upper bound on `pubDate`. ISO 8601 in UTC. Cannot be in the future. (format: date-time)
  --timeframe: string # Relative window ending at `now`. Integer = hours (1–48). Integer suffixed with `m` = minutes (1–2880). Mutually exclusive with `from_date` and `to_date`. Not available to free callers.
  --timezone: string # IANA timezone name. When set, `pubDate` and `fetched_at` in the response are converted to this zone and `pubDateTZ` carries the zone name. Default `UTC`.
  --image: string@image-completer # `1` → only articles that have an image; `0` → strip `image_url` from response. Default `1`.
  --video: string@video-completer # `1` → only articles that have a video; `0` → strip `video_url` from response.
  --full-content: string@full-content-completer # `1` → require articles to have full extracted content; `0` → strip `content`. Requires the `is_full_content_user` plan flag.
  --removeduplicate: string@removeduplicate-completer # `1` → exclude articles marked as duplicates (`is_duplicate=true`). Only applies to data from 2024-07-24 onward.
  --sentiment: string@sentiment-completer # Filter on dominant sentiment label. Requires the `is_ml_access` plan flag ∈ {1, 2}. Only applies to data from 2024-01-12 onward.
  --tag: list # Comma-separated ML-derived topic tags (e.g. `politics,technology`). Requires `is_ml_access` ∈ {1, 2}. Only applies to data from 2024-01-12 onward. Tag vocabulary differs for crypto vs general news.
  --size: int # Number of articles per page. 1 to `max_response_limit` (50 paid, 10 free).
  --page: string # Pagination cursor. For `sort=pubdateasc|pubdatedesc` (default), pass the value of the previous response's `nextPage` (an opaque 19-character timestamp). For `sort=relevancy|source|fetched_at`, pass an integer page number (max `10000 / size`).
  --qp-sort: string@sort-completer # Result ordering. `pubdatedesc` (default) and `pubdateasc` use cursor pagination; the others use integer pagination with a 10k-result ceiling. (default: pubdatedesc)
  --adv: string@adv-completer # `1` → response includes the `*_id` fields (`link_hash`, `domain_id`, `country_id`, `category_id`, `language_id`). Default `0`.
  --excludefield: list # Comma-separated response field names to omit. `article_id` cannot be excluded. Only fields listed in this endpoint's response model are accepted.
  --webhook: string@webhook-completer # `1` → on any non-200 response, the HTTP status is rewritten to 202 (the JSON body is unchanged). Used by webhook delivery systems that treat 4xx/5xx as terminal.
]: nothing -> record<status: string, totalResults: int, results: table<article_id: string, link_hash: string, link: string, title: string, description: string, content: string, keywords: list, creator: list, coin: list, language: string, language_id: int, pubDate: string, pubDateTZ: string, fetched_at: string, image_url: string, video_url: string, source_id: string, domain_id: int, source_name: string, source_priority: int, source_url: string, source_icon: string, sentiment: string, sentiment_stats: any, ai_tag: list, duplicate: bool>, nextPage: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "qInTitle" $qInTitle "scalar") (serialize-qp "qInMeta" $qInMeta "scalar") (serialize-qp "coin" $coin "csv") (serialize-qp "language" $language "csv") (serialize-qp "excludelanguage" $excludelanguage "csv") (serialize-qp "domain" $domain "csv") (serialize-qp "domainurl" $domainurl "csv") (serialize-qp "excludedomain" $excludedomain "csv") (serialize-qp "prioritydomain" $prioritydomain "scalar") (serialize-qp "id" $id "csv") (serialize-qp "url" $qp_url "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "video" $video "scalar") (serialize-qp "full_content" $full_content "scalar") (serialize-qp "removeduplicate" $removeduplicate "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "tag" $tag "csv") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "adv" $adv "scalar") (serialize-qp "excludefield" $excludefield "csv") (serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/crypto" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Financial-market news
#
# GET /1/market
# operationId: getMarket
export def "1-market get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --q: string # Free-text query, matched against `title`, `link`, `full_description`, `description`, `content`, `keywords` with AND-default operator. Maximum length is governed by the user's `q_limit` (default 100). Reserved Elasticsearch characters (`+ - = & | > < ! { } [ ] ^ ~ * ? : \ /`) are auto-escaped. Mutually exclusive with `qInTitle` and `qInMeta`.
  --qInTitle: string # Free-text query, matched against `title` only. Mutually exclusive with `q` and `qInMeta`.
  --qInMeta: string # Free-text query, matched against `title`, `link`, `description`, and `keywords`. Mutually exclusive with `q` and `qInTitle`.
  --symbol: list # Comma-separated financial-instrument symbols (e.g. `AAPL,MSFT`). Validated against the configured ticker file.
  --country: list # Comma-separated ISO 3166-1 alpha-2 country codes. Max `filter_limit` values (default 5). Mutually exclusive with `excludecountry`.
  --excludecountry: list # Comma-separated ISO country codes to exclude. Mutually exclusive with `country`.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --excludelanguage: list # Comma-separated language codes to exclude. Mutually exclusive with `language`.
  --domain: list # Comma-separated source identifiers (canonical `name` values from `/1/sources`). Mutually exclusive with `domainurl` and `excludedomain`.
  --domainurl: list # Comma-separated source domain URLs (e.g. `bbc.com`). Mutually exclusive with `domain` and `excludedomain`.
  --excludedomain: list # Comma-separated source URLs to exclude. Mutually exclusive with `domain` and `domainurl`.
  --prioritydomain: string@prioritydomain-completer # Restrict to a source-priority tier. `top` = priorities 0–13000, `medium` = 0–200000, `low` = 0–600000.
  --id: list # Comma-separated `article_id` values (32-character hex). Mutually exclusive with EVERY other filter except `apikey`. Maximum number of IDs equals the caller's `max_response_limit` (default 50 paid, 10 free).
  --qp-url: string # Filter to a specific article URL. Tracking parameters (utm_*, fbclid, gclid, etc.) are stripped server-side. Mutually exclusive with EVERY other filter except `apikey`. Max length 512. (format: uri)
  --from-date: string # Lower bound on `pubDate`. ISO 8601 in UTC (`YYYY-MM-DD HH:MM:SS`). Cannot be in the future. Non-admin callers cannot go back further than their plan `timeperiod`. (format: date-time)
  --to-date: string # Upper bound on `pubDate`. ISO 8601 in UTC. Cannot be in the future. (format: date-time)
  --timeframe: string # Relative window ending at `now`. Integer = hours (1–48). Integer suffixed with `m` = minutes (1–2880). Mutually exclusive with `from_date` and `to_date`. Not available to free callers.
  --timezone: string # IANA timezone name. When set, `pubDate` and `fetched_at` in the response are converted to this zone and `pubDateTZ` carries the zone name. Default `UTC`.
  --image: string@image-completer # `1` → only articles that have an image; `0` → strip `image_url` from response. Default `1`.
  --video: string@video-completer # `1` → only articles that have a video; `0` → strip `video_url` from response.
  --full-content: string@full-content-completer # `1` → require articles to have full extracted content; `0` → strip `content`. Requires the `is_full_content_user` plan flag.
  --removeduplicate: string@removeduplicate-completer # `1` → exclude articles marked as duplicates (`is_duplicate=true`). Only applies to data from 2024-07-24 onward.
  --sentiment: string@sentiment-completer # Filter on dominant sentiment label. Requires the `is_ml_access` plan flag ∈ {1, 2}. Only applies to data from 2024-01-12 onward.
  --sentiment-score: float # Minimum confidence for the chosen `sentiment` (1–100, two-decimal precision). Requires `sentiment` to also be set.
  --tag: list # Comma-separated ML-derived topic tags (e.g. `politics,technology`). Requires `is_ml_access` ∈ {1, 2}. Only applies to data from 2024-01-12 onward. Tag vocabulary differs for crypto vs general news.
  --organization: list # Comma-separated ML-extracted organization names. Requires `is_ml_access` = 2. Only applies to data from 2024-05-24 onward.
  --creator: list # Comma-separated author/byline names.
  --datatype: list # Comma-separated source types (e.g. `news, blog, podcast`). Only applies to data from 2025-11-28 onward.
  --size: int # Number of articles per page. 1 to `max_response_limit` (50 paid, 10 free).
  --page: string # Pagination cursor. For `sort=pubdateasc|pubdatedesc` (default), pass the value of the previous response's `nextPage` (an opaque 19-character timestamp). For `sort=relevancy|source|fetched_at`, pass an integer page number (max `10000 / size`).
  --qp-sort: string@sort-completer # Result ordering. `pubdatedesc` (default) and `pubdateasc` use cursor pagination; the others use integer pagination with a 10k-result ceiling. (default: pubdatedesc)
  --adv: string@adv-completer # `1` → response includes the `*_id` fields (`link_hash`, `domain_id`, `country_id`, `category_id`, `language_id`). Default `0`.
  --excludefield: list # Comma-separated response field names to omit. `article_id` cannot be excluded. Only fields listed in this endpoint's response model are accepted.
  --webhook: string@webhook-completer # `1` → on any non-200 response, the HTTP status is rewritten to 202 (the JSON body is unchanged). Used by webhook delivery systems that treat 4xx/5xx as terminal.
]: nothing -> record<status: string, totalResults: int, results: table<article_id: string, link: string, title: string, description: string, content: string, keywords: list, creator: list, symbol: list, language: string, country: list, datatype: string, pubDate: string, pubDateTZ: string, fetched_at: string, image_url: string, video_url: string, source_id: string, source_name: string, source_url: string, source_icon: string, sentiment: string, sentiment_stats: any, ai_tag: list, ai_org: list, ai_summary: string, duplicate: bool>, nextPage: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "qInTitle" $qInTitle "scalar") (serialize-qp "qInMeta" $qInMeta "scalar") (serialize-qp "symbol" $symbol "csv") (serialize-qp "country" $country "csv") (serialize-qp "excludecountry" $excludecountry "csv") (serialize-qp "language" $language "csv") (serialize-qp "excludelanguage" $excludelanguage "csv") (serialize-qp "domain" $domain "csv") (serialize-qp "domainurl" $domainurl "csv") (serialize-qp "excludedomain" $excludedomain "csv") (serialize-qp "prioritydomain" $prioritydomain "scalar") (serialize-qp "id" $id "csv") (serialize-qp "url" $qp_url "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "timezone" $timezone "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "video" $video "scalar") (serialize-qp "full_content" $full_content "scalar") (serialize-qp "removeduplicate" $removeduplicate "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "sentiment_score" $sentiment_score "scalar") (serialize-qp "tag" $tag "csv") (serialize-qp "organization" $organization "csv") (serialize-qp "creator" $creator "csv") (serialize-qp "datatype" $datatype "csv") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "adv" $adv "scalar") (serialize-qp "excludefield" $excludefield "csv") (serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/market" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List news sources
#
# GET /1/sources
# operationId: getSources
export def "1-sources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --country: list # Comma-separated ISO 3166-1 alpha-2 country codes. Max `filter_limit` values (default 5). Mutually exclusive with `excludecountry`.
  --category: list # Comma-separated category names. Mutually exclusive with `excludecategory`.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --domainurl: list # Comma-separated source domain URLs (e.g. `bbc.com`). Mutually exclusive with `domain` and `excludedomain`.
  --prioritydomain: string@prioritydomain-completer # Restrict to a source-priority tier. `top` = priorities 0–13000, `medium` = 0–200000, `low` = 0–600000.
  --webhook: string@webhook-completer # `1` → on any non-200 response, the HTTP status is rewritten to 202 (the JSON body is unchanged). Used by webhook delivery systems that treat 4xx/5xx as terminal.
]: nothing -> record<status: string, totalResults: int, results: table<id: string, name: string, url: string, icon: string, priority: int, description: string, category: list, language: list, country: list, total_article: int, last_fetch: string>, nextPage: any> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "country" $country "csv") (serialize-qp "category" $category "csv") (serialize-qp "language" $language "csv") (serialize-qp "domainurl" $domainurl "csv") (serialize-qp "prioritydomain" $prioritydomain "scalar") (serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Article count, with optional time-bucketing
#
# GET /1/count
# operationId: getCount
export def "1-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --q: string # Free-text query, matched against `title`, `link`, `full_description`, `description`, `content`, `keywords` with AND-default operator. Maximum length is governed by the user's `q_limit` (default 100). Reserved Elasticsearch characters (`+ - = & | > < ! { } [ ] ^ ~ * ? : \ /`) are auto-escaped. Mutually exclusive with `qInTitle` and `qInMeta`.
  --qInTitle: string # Free-text query, matched against `title` only. Mutually exclusive with `q` and `qInMeta`.
  --qInMeta: string # Free-text query, matched against `title`, `link`, `description`, and `keywords`. Mutually exclusive with `q` and `qInTitle`.
  --country: list # Comma-separated ISO 3166-1 alpha-2 country codes. Max `filter_limit` values (default 5). Mutually exclusive with `excludecountry`.
  --excludecountry: list # Comma-separated ISO country codes to exclude. Mutually exclusive with `country`.
  --category: list # Comma-separated category names. Mutually exclusive with `excludecategory`.
  --excludecategory: list # Comma-separated category names to exclude. Mutually exclusive with `category`.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --excludelanguage: list # Comma-separated language codes to exclude. Mutually exclusive with `language`.
  --domain: list # Comma-separated source identifiers (canonical `name` values from `/1/sources`). Mutually exclusive with `domainurl` and `excludedomain`.
  --domainurl: list # Comma-separated source domain URLs (e.g. `bbc.com`). Mutually exclusive with `domain` and `excludedomain`.
  --excludedomain: list # Comma-separated source URLs to exclude. Mutually exclusive with `domain` and `domainurl`.
  --prioritydomain: string@prioritydomain-completer # Restrict to a source-priority tier. `top` = priorities 0–13000, `medium` = 0–200000, `low` = 0–600000.
  --from-date: string # Lower bound on `pubDate`. ISO 8601 in UTC (`YYYY-MM-DD HH:MM:SS`). Cannot be in the future. Non-admin callers cannot go back further than their plan `timeperiod`. (format: date-time)
  --to-date: string # Upper bound on `pubDate`. ISO 8601 in UTC. Cannot be in the future. (format: date-time)
  --image: string@image-completer # `1` → only articles that have an image; `0` → strip `image_url` from response. Default `1`.
  --video: string@video-completer # `1` → only articles that have a video; `0` → strip `video_url` from response.
  --full-content: string@full-content-completer # `1` → require articles to have full extracted content; `0` → strip `content`. Requires the `is_full_content_user` plan flag.
  --removeduplicate: string@removeduplicate-completer # `1` → exclude articles marked as duplicates (`is_duplicate=true`). Only applies to data from 2024-07-24 onward.
  --sentiment: string@sentiment-completer # Filter on dominant sentiment label. Requires the `is_ml_access` plan flag ∈ {1, 2}. Only applies to data from 2024-01-12 onward.
  --sentiment-score: float # Minimum confidence for the chosen `sentiment` (1–100, two-decimal precision). Requires `sentiment` to also be set.
  --tag: list # Comma-separated ML-derived topic tags (e.g. `politics,technology`). Requires `is_ml_access` ∈ {1, 2}. Only applies to data from 2024-01-12 onward. Tag vocabulary differs for crypto vs general news.
  --region: list # Comma-separated ML-extracted geographic regions. Each value may itself contain `-`-joined sub-regions (`paris-france`). Requires `is_ml_access` = 2. Only applies to data from 2024-01-29 onward.
  --organization: list # Comma-separated ML-extracted organization names. Requires `is_ml_access` = 2. Only applies to data from 2024-05-24 onward.
  --creator: list # Comma-separated author/byline names.
  --datatype: list # Comma-separated source types (e.g. `news, blog, podcast`). Only applies to data from 2025-11-28 onward.
  --interval: string@interval-completer # Bucket size for count endpoints. `all` returns a single total; `hour` and `day` return a time-bucketed histogram. (default: all)
  --size: int # Number of articles per page. 1 to `max_response_limit` (50 paid, 10 free).
  --page: string # Pagination cursor. For `sort=pubdateasc|pubdatedesc` (default), pass the value of the previous response's `nextPage` (an opaque 19-character timestamp). For `sort=relevancy|source|fetched_at`, pass an integer page number (max `10000 / size`).
  --qp-sort: string@sort-completer-1 # Result ordering for count endpoints. Only `pubdateasc` and `pubdatedesc` are valid. (default: pubdatedesc)
  --webhook: string@webhook-completer # `1` → on any non-200 response, the HTTP status is rewritten to 202 (the JSON body is unchanged). Used by webhook delivery systems that treat 4xx/5xx as terminal.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "qInTitle" $qInTitle "scalar") (serialize-qp "qInMeta" $qInMeta "scalar") (serialize-qp "country" $country "csv") (serialize-qp "excludecountry" $excludecountry "csv") (serialize-qp "category" $category "csv") (serialize-qp "excludecategory" $excludecategory "csv") (serialize-qp "language" $language "csv") (serialize-qp "excludelanguage" $excludelanguage "csv") (serialize-qp "domain" $domain "csv") (serialize-qp "domainurl" $domainurl "csv") (serialize-qp "excludedomain" $excludedomain "csv") (serialize-qp "prioritydomain" $prioritydomain "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "video" $video "scalar") (serialize-qp "full_content" $full_content "scalar") (serialize-qp "removeduplicate" $removeduplicate "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "sentiment_score" $sentiment_score "scalar") (serialize-qp "tag" $tag "csv") (serialize-qp "region" $region "csv") (serialize-qp "organization" $organization "csv") (serialize-qp "creator" $creator "csv") (serialize-qp "datatype" $datatype "csv") (serialize-qp "interval" $interval "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Crypto article count
#
# GET /1/crypto/count
# operationId: getCryptoCount
export def "1-crypto-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --q: string # Free-text query, matched against `title`, `link`, `full_description`, `description`, `content`, `keywords` with AND-default operator. Maximum length is governed by the user's `q_limit` (default 100). Reserved Elasticsearch characters (`+ - = & | > < ! { } [ ] ^ ~ * ? : \ /`) are auto-escaped. Mutually exclusive with `qInTitle` and `qInMeta`.
  --qInTitle: string # Free-text query, matched against `title` only. Mutually exclusive with `q` and `qInMeta`.
  --qInMeta: string # Free-text query, matched against `title`, `link`, `description`, and `keywords`. Mutually exclusive with `q` and `qInTitle`.
  --coin: list # Comma-separated cryptocurrency tickers (e.g. `btc,eth`). Validated against the crypto-keyword vocabulary.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --excludelanguage: list # Comma-separated language codes to exclude. Mutually exclusive with `language`.
  --domain: list # Comma-separated source identifiers (canonical `name` values from `/1/sources`). Mutually exclusive with `domainurl` and `excludedomain`.
  --domainurl: list # Comma-separated source domain URLs (e.g. `bbc.com`). Mutually exclusive with `domain` and `excludedomain`.
  --excludedomain: list # Comma-separated source URLs to exclude. Mutually exclusive with `domain` and `domainurl`.
  --prioritydomain: string@prioritydomain-completer # Restrict to a source-priority tier. `top` = priorities 0–13000, `medium` = 0–200000, `low` = 0–600000.
  --from-date: string # Lower bound on `pubDate`. ISO 8601 in UTC (`YYYY-MM-DD HH:MM:SS`). Cannot be in the future. Non-admin callers cannot go back further than their plan `timeperiod`. (format: date-time)
  --to-date: string # Upper bound on `pubDate`. ISO 8601 in UTC. Cannot be in the future. (format: date-time)
  --image: string@image-completer # `1` → only articles that have an image; `0` → strip `image_url` from response. Default `1`.
  --video: string@video-completer # `1` → only articles that have a video; `0` → strip `video_url` from response.
  --full-content: string@full-content-completer # `1` → require articles to have full extracted content; `0` → strip `content`. Requires the `is_full_content_user` plan flag.
  --removeduplicate: string@removeduplicate-completer # `1` → exclude articles marked as duplicates (`is_duplicate=true`). Only applies to data from 2024-07-24 onward.
  --sentiment: string@sentiment-completer # Filter on dominant sentiment label. Requires the `is_ml_access` plan flag ∈ {1, 2}. Only applies to data from 2024-01-12 onward.
  --tag: list # Comma-separated ML-derived topic tags (e.g. `politics,technology`). Requires `is_ml_access` ∈ {1, 2}. Only applies to data from 2024-01-12 onward. Tag vocabulary differs for crypto vs general news.
  --interval: string@interval-completer # Bucket size for count endpoints. `all` returns a single total; `hour` and `day` return a time-bucketed histogram. (default: all)
  --size: int # Number of articles per page. 1 to `max_response_limit` (50 paid, 10 free).
  --page: string # Pagination cursor. For `sort=pubdateasc|pubdatedesc` (default), pass the value of the previous response's `nextPage` (an opaque 19-character timestamp). For `sort=relevancy|source|fetched_at`, pass an integer page number (max `10000 / size`).
  --qp-sort: string@sort-completer-1 # Result ordering for count endpoints. Only `pubdateasc` and `pubdatedesc` are valid. (default: pubdatedesc)
  --webhook: string@webhook-completer # `1` → on any non-200 response, the HTTP status is rewritten to 202 (the JSON body is unchanged). Used by webhook delivery systems that treat 4xx/5xx as terminal.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "qInTitle" $qInTitle "scalar") (serialize-qp "qInMeta" $qInMeta "scalar") (serialize-qp "coin" $coin "csv") (serialize-qp "language" $language "csv") (serialize-qp "excludelanguage" $excludelanguage "csv") (serialize-qp "domain" $domain "csv") (serialize-qp "domainurl" $domainurl "csv") (serialize-qp "excludedomain" $excludedomain "csv") (serialize-qp "prioritydomain" $prioritydomain "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "video" $video "scalar") (serialize-qp "full_content" $full_content "scalar") (serialize-qp "removeduplicate" $removeduplicate "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "tag" $tag "csv") (serialize-qp "interval" $interval "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/crypto/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Market article count
#
# GET /1/market/count
# operationId: getMarketCount
export def "1-market-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apikey: string # User API key. Alternatively, send the `X-ACCESS-KEY` HTTP header. One of the two MUST be present.
  --q: string # Free-text query, matched against `title`, `link`, `full_description`, `description`, `content`, `keywords` with AND-default operator. Maximum length is governed by the user's `q_limit` (default 100). Reserved Elasticsearch characters (`+ - = & | > < ! { } [ ] ^ ~ * ? : \ /`) are auto-escaped. Mutually exclusive with `qInTitle` and `qInMeta`.
  --symbol: list # Comma-separated financial-instrument symbols (e.g. `AAPL,MSFT`). Validated against the configured ticker file.
  --country: list # Comma-separated ISO 3166-1 alpha-2 country codes. Max `filter_limit` values (default 5). Mutually exclusive with `excludecountry`.
  --excludecountry: list # Comma-separated ISO country codes to exclude. Mutually exclusive with `country`.
  --language: list # Comma-separated ISO 639-1 language codes. Mutually exclusive with `excludelanguage`.
  --excludelanguage: list # Comma-separated language codes to exclude. Mutually exclusive with `language`.
  --domain: list # Comma-separated source identifiers (canonical `name` values from `/1/sources`). Mutually exclusive with `domainurl` and `excludedomain`.
  --domainurl: list # Comma-separated source domain URLs (e.g. `bbc.com`). Mutually exclusive with `domain` and `excludedomain`.
  --excludedomain: list # Comma-separated source URLs to exclude. Mutually exclusive with `domain` and `domainurl`.
  --prioritydomain: string@prioritydomain-completer # Restrict to a source-priority tier. `top` = priorities 0–13000, `medium` = 0–200000, `low` = 0–600000.
  --from-date: string # Lower bound on `pubDate`. ISO 8601 in UTC (`YYYY-MM-DD HH:MM:SS`). Cannot be in the future. Non-admin callers cannot go back further than their plan `timeperiod`. (format: date-time)
  --to-date: string # Upper bound on `pubDate`. ISO 8601 in UTC. Cannot be in the future. (format: date-time)
  --image: string@image-completer # `1` → only articles that have an image; `0` → strip `image_url` from response. Default `1`.
  --video: string@video-completer # `1` → only articles that have a video; `0` → strip `video_url` from response.
  --full-content: string@full-content-completer # `1` → require articles to have full extracted content; `0` → strip `content`. Requires the `is_full_content_user` plan flag.
  --removeduplicate: string@removeduplicate-completer # `1` → exclude articles marked as duplicates (`is_duplicate=true`). Only applies to data from 2024-07-24 onward.
  --sentiment: string@sentiment-completer # Filter on dominant sentiment label. Requires the `is_ml_access` plan flag ∈ {1, 2}. Only applies to data from 2024-01-12 onward.
  --sentiment-score: float # Minimum confidence for the chosen `sentiment` (1–100, two-decimal precision). Requires `sentiment` to also be set.
  --tag: list # Comma-separated ML-derived topic tags (e.g. `politics,technology`). Requires `is_ml_access` ∈ {1, 2}. Only applies to data from 2024-01-12 onward. Tag vocabulary differs for crypto vs general news.
  --organization: list # Comma-separated ML-extracted organization names. Requires `is_ml_access` = 2. Only applies to data from 2024-05-24 onward.
  --creator: list # Comma-separated author/byline names.
  --datatype: list # Comma-separated source types (e.g. `news, blog, podcast`). Only applies to data from 2025-11-28 onward.
  --interval: string@interval-completer # Bucket size for count endpoints. `all` returns a single total; `hour` and `day` return a time-bucketed histogram. (default: all)
  --size: int # Number of articles per page. 1 to `max_response_limit` (50 paid, 10 free).
  --page: string # Pagination cursor. For `sort=pubdateasc|pubdatedesc` (default), pass the value of the previous response's `nextPage` (an opaque 19-character timestamp). For `sort=relevancy|source|fetched_at`, pass an integer page number (max `10000 / size`).
  --qp-sort: string@sort-completer-1 # Result ordering for count endpoints. Only `pubdateasc` and `pubdatedesc` are valid. (default: pubdatedesc)
  --webhook: string@webhook-completer # `1` → on any non-200 response, the HTTP status is rewritten to 202 (the JSON body is unchanged). Used by webhook delivery systems that treat 4xx/5xx as terminal.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apikey" $apikey "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "symbol" $symbol "csv") (serialize-qp "country" $country "csv") (serialize-qp "excludecountry" $excludecountry "csv") (serialize-qp "language" $language "csv") (serialize-qp "excludelanguage" $excludelanguage "csv") (serialize-qp "domain" $domain "csv") (serialize-qp "domainurl" $domainurl "csv") (serialize-qp "excludedomain" $excludedomain "csv") (serialize-qp "prioritydomain" $prioritydomain "scalar") (serialize-qp "from_date" $from_date "scalar") (serialize-qp "to_date" $to_date "scalar") (serialize-qp "image" $image "scalar") (serialize-qp "video" $video "scalar") (serialize-qp "full_content" $full_content "scalar") (serialize-qp "removeduplicate" $removeduplicate "scalar") (serialize-qp "sentiment" $sentiment "scalar") (serialize-qp "sentiment_score" $sentiment_score "scalar") (serialize-qp "tag" $tag "csv") (serialize-qp "organization" $organization "csv") (serialize-qp "creator" $creator "csv") (serialize-qp "datatype" $datatype "csv") (serialize-qp "interval" $interval "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "webhook" $webhook "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/market/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List curated topics
#
# GET /1/topic/all
# operationId: getAllTopics
export def "1-topic-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string, result: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/topic/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Articles in a curated topic
#
# GET /1/topic/view
# operationId: getTopicView
export def "1-topic-view get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: int # Numeric topic id from `/1/topic/all`.
  --page: int # 1-based page number.
]: nothing -> record<status: string, results: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/topic/view" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Per-API-key access statistics (admin)
#
# GET /1/log/user
# operationId: getUserAccessLog
export def "1-log-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-key: string # Server-side admin secret (`LOG_VIEW_SECRET`).
  --apikey: string # The user's API key whose log is being requested.
]: nothing -> record<status: string, result: record<apikey: string, name: string, stats: list<record>, details: list<list>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access_key" $access_key "scalar") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/log/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download access log as ZIP (admin)
#
# GET /1/log/user/download
# operationId: downloadUserAccessLog
export def "1-log-user-download downloadUserAccessLog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-key: string # Server-side admin secret (`LOG_VIEW_SECRET`).
  --apikey: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-access_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access_key" $access_key "scalar") (serialize-qp "apikey" $apikey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/log/user/download" $qp)
  let accept_val = "application/zip"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Tail of the server-side API log (admin)
#
# GET /1/log/api
# operationId: getApiLog
export def "1-log get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-key: string # Server-side admin secret (`LOG_VIEW_SECRET`).
  --size: int # Number of log lines to tail (1–2000, default 500). (default: 500)
]: nothing -> record<status: string, result: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-access_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access_key" $access_key "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/log/api" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
