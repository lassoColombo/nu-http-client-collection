# Auto-generated client for World News API v2.2.0
# Source: https://raw.githubusercontent.com/ddsky/world-news-api-clients/main/world-news-api-openapi-3.json
# Auth: --token flag or $env.WORLD_NEWS_API_TOKEN

const BASE_URL = "https://api.worldnewsapi.com"
const DEFAULT_AUTH = "query-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WORLD_NEWS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api-key" => { {headers: {}, query: $"api-key=($token_val)"} }
    "x-api-key" => { {headers: {x-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.worldnewsapi.com"] }
def auth-scheme-completer [] { ["query-api-key" "x-api-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "search-news searchNews" } } | get name | first)
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

# Search News
#
# GET /search-news
# Docs: https://worldnewsapi.com/docs/search-news/ — Read entire docs
# operationId: searchNews
export def "search-news searchNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # The text to match in the news content (at least 3 characters, maximum 100 characters). By default all query terms are expected, you can use an uppercase OR to search for any terms, e.g. tesla OR ford. You can also exclude terms by putting a minus sign (-) in front of the term, e.g. tesla -ford. For exact matches just put your term in quotes, e.g. "elon musk". (e.g. tesla)
  --text-match-indexes: string # If a "text" is given to search for, you can specify where this text is searched for. Possible values are title, content, or both separated by a comma. By default, both title and content are searched. (e.g. title,content)
  --source-country: string # The ISO 3166 country code from which the news should originate. (e.g. us)
  --language: string # The ISO 6391 language code of the news. (e.g. en)
  --min-sentiment: float # The minimal sentiment of the news in range [-1,1]. (format: double, e.g. -0.8)
  --max-sentiment: float # The maximal sentiment of the news in range [-1,1]. (format: double, e.g. 0.8)
  --earliest-publish-date: string # The news must have been published after this date. (e.g. 2022-04-22 16:12:35)
  --latest-publish-date: string # The news must have been published before this date. (e.g. 2022-04-22 16:12:35)
  --news-sources: string # A comma-separated list of news sources from which the news should originate. (e.g. https://www.bbc.co.uk)
  --authors: string # A comma-separated list of author names. Only news from any of the given authors will be returned. (e.g. John Doe)
  --categories: string # A comma-separated list of categories. Only news from any of the given categories will be returned. Possible categories are politics, sports, business, technology, entertainment, health, science, lifestyle, travel, culture, education, environment, other. Please note that the filter might leave out news, especially in non-English languages. If too few results are returned, use the text parameter instead. (e.g. politics,sports)
  --entities: string # Filter news by entities (see semantic types). (e.g. ORG:Tesla,PER:Elon Musk)
  --location-filter: string # Filter news by radius around a certain location. Format is "latitude,longitude,radius in kilometers". Radius must be between 1 and 100 kilometers. (e.g. 51.050407, 13.737262, 20)
  --qp-sort: string # The sorting criteria (publish-time). (e.g. publish-time)
  --sort-direction: string # Whether to sort ascending or descending (ASC or DESC). (e.g. ASC)
  --offset: int # The number of news to skip in range [0,100000] (format: int32, e.g. 0)
  --number: int # The number of news to return in range [1,100] (format: int32, e.g. 10)
]: nothing -> record<offset: int, number: int, available: int, news: table<summary: string, image: string, sentiment: float, language: string, video: string, title: string, url: string, source_country: string, id: int, text: string, category: string, publish_date: string, authors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "text-match-indexes" $text_match_indexes "scalar") (serialize-qp "source-country" $source_country "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "min-sentiment" $min_sentiment "scalar") (serialize-qp "max-sentiment" $max_sentiment "scalar") (serialize-qp "earliest-publish-date" $earliest_publish_date "scalar") (serialize-qp "latest-publish-date" $latest_publish_date "scalar") (serialize-qp "news-sources" $news_sources "scalar") (serialize-qp "authors" $authors "scalar") (serialize-qp "categories" $categories "scalar") (serialize-qp "entities" $entities "scalar") (serialize-qp "location-filter" $location_filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort-direction" $sort_direction "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "number" $number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-news" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Top News
#
# GET /top-news
# Docs: https://worldnewsapi.com/docs/top-news/ — Read entire docs
# operationId: topNews
export def "top-news topNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-country: string # The ISO 3166 country code of the country for which top news should be retrieved. (e.g. us)
  --language: string # The ISO 6391 language code of the top news. The language must be one spoken in the source-country. (e.g. en)
  --date: string # The date for which the top news should be retrieved. If no date is given, the current day is assumed. (e.g. 2024-05-30)
  --headlines-only: oneof<nothing, bool> # Whether to only return basic information such as id, title, and url of the news. (e.g. false)
]: nothing -> record<top_news: table<news: list>, language: string, country: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source-country" $source_country "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "headlines-only" $headlines_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/top-news" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Newspaper Front Page
#
# GET /retrieve-front-page
# Docs: https://worldnewsapi.com/docs/newspaper-front-pages/ — Read entire docs
# operationId: retrieveNewspaperFrontPage
export def "retrieve-front-page retrieveNewspaperFrontPage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --source-country: string # The ISO 3166 country code of the newspaper publication. (e.g. au)
  --source-name: string # The identifier of the publication see attached list. (e.g. herald-sun)
  --date: string # The date for which the front page should be retrieved. You can also go into the past, the earliest date is 2024-07-09. (e.g. 2024-07-09)
]: nothing -> record<front_page: record<name: string, date: string, country: string, image: string, language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source-country" $source_country "scalar") (serialize-qp "source-name" $source_name "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/retrieve-front-page" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve News Articles by Ids
#
# GET /retrieve-news
# Docs: https://worldnewsapi.com/docs/retrieve-news/ — Read entire docs
# operationId: retrieveNewsArticlesByIds
export def "retrieve-news retrieveNewsArticlesByIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # A comma separated list of news ids. (e.g. 2352,2354)
]: nothing -> record<news: table<summary: string, image: string, sentiment: float, language: string, title: string, url: string, source_country: string, id: int, text: string, category: string, publish_date: string, authors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/retrieve-news" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extract News
#
# GET /extract-news
# Docs: https://worldnewsapi.com/docs/extract-news/ — Read entire docs
# operationId: extractNews
export def "extract-news extractNews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # The url of the news. (e.g. https://www.bbc.com/news/world-us-canada-59340789)
  --analyze: oneof<nothing, bool> # Whether to analyze the extracted news (extract entities, detect sentiment etc.) (e.g. true)
]: nothing -> record<title: string, text: string, url: string, image: string, images: table<width: int, title: string, url: string, height: int>, video: string, videos: table<summary: string, duration: int, thumbnail: string, title: string, url: string>, publish_date: string, author: string, authors: list<string>, language: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "analyze" $analyze "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extract-news" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extract News Links
#
# GET /extract-news-links
# Docs: https://worldnewsapi.com/docs/extract-news-links/ — Read entire docs
# operationId: extractNewsLinks
export def "extract-news-links extractNewsLinks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # The url of the news. (e.g. https://www.bbc.com/news/world-us-canada-59340789)
  --analyze: oneof<nothing, bool> # Whether to analyze the extracted news (extract entities, detect sentiment etc.) (e.g. true)
]: nothing -> record<news_links: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "analyze" $analyze "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/extract-news-links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search News Sources
#
# GET /search-news-sources
# Docs: https://worldnewsapi.com/docs/search-news-sources/ — Read entire docs
# operationId: searchNewsSources
export def "search-news-sources searchNewsSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The (partial) name of the source. (e.g. bbc)
]: nothing -> record<available: int, sources: table<name: string, url: string, language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-news-sources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# News Website to RSS Feed
#
# GET /feed.rss
# Docs: https://worldnewsapi.com/docs/website-to-rss-feed/ — Read entire docs
# operationId: newsWebsiteToRSSFeed
export def "feedrss newsWebsiteToRSSFeed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # The url of the site for which an RSS feed should be created. (e.g. https://www.bbc.com/)
  --extract-news: oneof<nothing, bool> # Whether to extract the news for each link instead of just returning the link. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "extract-news" $extract_news "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/feed.rss" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Geo Coordinates
#
# GET /geo-coordinates
# Docs: https://worldnewsapi.com/docs/get-geo-coordinates/ — Read entire docs
# operationId: getGeoCoordinates
export def "geo-coordinates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --location: string # The address or name of the location. (e.g. Tokyo, Japan)
]: nothing -> record<latitude: float, longitude: float, city: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geo-coordinates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
