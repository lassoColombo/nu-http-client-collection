# Auto-generated client for VocaDbWeb v1.0
# Source: https://api.apis.guru/v2/specs/vocadb.net/1.0/openapi.json
# Auth: --token flag or $env.VOCADBWEB_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VOCADBWEB_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def edit-event-completer [] { ["Created" "Deleted" "Restored" "Updated"] }
def entry-type-completer [] { ["Album" "Artist" "DiscussionTopic" "PV" "ReleaseEvent" "ReleaseEventSeries" "Song" "SongList" "Tag" "Undefined" "User" "Venue"] }
def fields-completer [] { ["ArchivedVersion" "Entry" "None"] }
def entry-fields-completer [] { ["AdditionalNames" "Description" "MainPicture" "Names" "None" "PVs" "Tags" "WebLinks"] }
def lang-completer [] { ["Default" "English" "Japanese" "Romaji"] }
def sort-rule-completer [] { ["CreateDate" "CreateDateDescending"] }
def accept-completer [] { ["application/json" "text/json" "text/plain"] }
def disc-types-completer [] { ["Album" "Artbook" "Compilation" "EP" "Fanmade" "Game" "Instrumental" "Other" "Single" "SplitAlbum" "Unknown" "Video"] }
def artist-participation-status-completer [] { ["Everything" "OnlyCollaborations" "OnlyMainAlbums"] }
def status-completer [] { ["Approved" "Draft" "Finished" "Locked"] }
def sort-completer [] { ["AdditionDate" "CollectionCount" "Name" "NameThenReleaseDate" "None" "RatingAverage" "RatingTotal" "ReleaseDate" "ReleaseDateWithNulls"] }
def name-match-mode-completer [] { ["Auto" "Exact" "Partial" "StartsWith" "Words"] }
def fields-completer-1 [] { ["AdditionalNames" "Artists" "Description" "Discs" "Identifiers" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "Tracks" "WebLinks"] }
def language-preference-completer [] { ["Default" "English" "Japanese" "Romaji"] }
def song-fields-completer [] { ["AdditionalNames" "Albums" "Artists" "Bpm" "Lyrics" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "ThumbUrl" "WebLinks"] }
def fields-completer-2 [] { ["AdditionalNames" "Albums" "Artists" "Bpm" "Lyrics" "MainPicture" "Names" "None" "PVs" "ReleaseEvent" "Tags" "ThumbUrl" "WebLinks"] }
def sort-completer-1 [] { ["AdditionDate" "AdditionDateAsc" "ArtistType" "FollowerCount" "Name" "None" "ReleaseDate" "SongCount" "SongRating"] }
def fields-completer-3 [] { ["AdditionalNames" "ArtistLinks" "ArtistLinksReverse" "BaseVoicebank" "Description" "MainPicture" "Names" "None" "Tags" "WebLinks"] }
def relations-completer [] { ["All" "LatestAlbums" "LatestEvents" "LatestSongs" "None" "PopularAlbums" "PopularSongs"] }
def fields-completer-4 [] { ["Entry" "None"] }
def fields-completer-5 [] { ["LastTopic" "None" "TopicCount"] }
def fields-completer-6 [] { ["All" "CommentCount" "Comments" "Content" "LastComment" "None"] }
def sort-completer-2 [] { ["DateCreated" "LastCommentDate" "Name" "None"] }
def entry-types-completer [] { ["Album" "Artist" "DiscussionTopic" "Nothing" "PV" "ReleaseEvent" "ReleaseEventSeries" "Song" "SongList" "Tag" "User" "Venue"] }
def sort-completer-3 [] { ["ActivityDate" "AdditionDate" "Name" "None"] }
def fields-completer-7 [] { ["AdditionalNames" "Description" "MainPicture" "Names" "None" "PVs" "Tags" "WebLinks"] }
def fields-completer-8 [] { ["AdditionalNames" "AliasedTo" "Description" "MainPicture" "Names" "None" "Parent" "RelatedTags" "TranslatedDescription" "WebLinks"] }
def service-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def fields-completer-9 [] { ["AdditionalNames" "Description" "Events" "MainPicture" "Names" "None" "WebLinks"] }
def category-completer [] { ["AlbumRelease" "Anniversary" "Club" "Concert" "Contest" "Convention" "Festival" "Other" "Unspecified"] }
def sort-completer-4 [] { ["AdditionDate" "Date" "Name" "None" "SeriesName" "VenueName"] }
def fields-completer-10 [] { ["AdditionalNames" "Artists" "Description" "MainPicture" "Names" "None" "PVs" "Series" "SongList" "Tags" "Venue" "WebLinks"] }
def sort-direction-completer [] { ["Ascending" "Descending"] }
def report-type-completer [] { ["Duplicate" "Inappropriate" "InvalidInfo" "Other"] }
def featured-category-completer [] { ["Concerts" "Nothing" "Other" "Pools" "VocaloidRanking"] }
def sort-completer-5 [] { ["CreateDate" "Date" "Name" "None"] }
def fields-completer-11 [] { ["Description" "Events" "MainPicture" "None" "Tags"] }
def pv-services-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Nothing" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def sort-completer-6 [] { ["AdditionDate" "FavoritedTimes" "Name" "None" "PublishDate" "RatingScore" "SongType" "TagUsageCount"] }
def pv-service-completer [] { ["Bandcamp" "Bilibili" "Creofuga" "File" "LocalFile" "NicoNicoDouga" "Piapro" "SoundCloud" "Vimeo" "Youtube"] }
def filter-by-completer [] { ["CreateDate" "Popularity" "PublishDate"] }
def vocalist-completer [] { ["Nothing" "Other" "UTAU" "Vocaloid"] }
def user-fields-completer [] { ["KnownLanguages" "MainPicture" "None" "OldUsernames"] }
def rating-completer [] { ["Dislike" "Favorite" "Like" "Nothing"] }
def sort-completer-7 [] { ["AdditionDate" "Name" "Nothing" "UsageCount"] }
def target-completer [] { ["Album" "AlbumArtist" "AlbumSong" "All" "Artist" "ArtistSong" "Event" "Nothing" "Song" "SongList"] }
def groups-completer [] { ["Admin" "Limited" "Moderator" "Nothing" "Regular" "Trusted"] }
def sort-completer-8 [] { ["Group" "Name" "RegisterDate"] }
def fields-completer-12 [] { ["KnownLanguages" "MainPicture" "None" "OldUsernames"] }
def collection-status-completer [] { ["Nothing" "Ordered" "Owned" "Wishlisted"] }
def media-type-completer [] { ["DigitalDownload" "Other" "PhysicalDisc"] }
def purchase-statuses-completer [] { ["All" "Nothing" "Ordered" "Owned" "Wishlisted"] }
def album-types-completer [] { ["Album" "Artbook" "Compilation" "EP" "Fanmade" "Game" "Instrumental" "Other" "Single" "SplitAlbum" "Unknown" "Video"] }
def relationship-type-completer [] { ["Attending" "Interested"] }
def artist-type-completer [] { ["Animator" "Band" "CeVIO" "Character" "Circle" "CoverArtist" "Illustrator" "Label" "Lyricist" "OtherGroup" "OtherIndividual" "OtherVocalist" "OtherVoiceSynthesizer" "Producer" "SynthesizerV" "UTAU" "Unknown" "Utaite" "Vocalist" "Vocaloid"] }
def inbox-completer [] { ["Nothing" "Notifications" "Received" "Sent"] }
def artist-grouping-completer [] { ["And" "Or"] }
def sort-completer-9 [] { ["AdditionDate" "FavoritedTimes" "Name" "None" "PublishDate" "RatingDate" "RatingScore"] }
def report-type-completer-1 [] { ["MaliciousIP" "Other" "RemovePermissions" "Spamming"] }
def fields-completer-13 [] { ["AdditionalNames" "Description" "Events" "Names" "None" "WebLinks"] }
def sort-rule-completer-1 [] { ["Distance" "Name" "None"] }
def distance-unit-completer [] { ["Kilometers" "Miles"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "activity-entries get" } } | get name | first)
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

# GET /api/activityEntries
export def "activity-entries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --before: string # format: date-time
  --since: string # format: date-time
  --user-id: int # format: int32
  --edit-event: string@edit-event-completer
  --entry-type: string@entry-type-completer
  --max-results: int # format: int32, default: 50
  --get-total-count: oneof<nothing, bool> # default: false
  --fields: string@fields-completer
  --entry-fields: string@entry-fields-completer
  --lang: string@lang-completer
  --sort-rule: string@sort-rule-completer
]: nothing -> record<items: table<archivedVersion: record, author: record, createDate: string, editEvent: string, entry: record>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "editEvent" $edit_event "scalar") (serialize-qp "entryType" $entry_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "entryFields" $entry_fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "sortRule" $sort_rule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/activityEntries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"before": $before, "since": $since, "userId": $user_id, "editEvent": $edit_event, "entryType": $entry_type, "maxResults": $max_results, "getTotalCount": $get_total_count, "fields": $fields, "entryFields": $entry_fields, "lang": $lang, "sortRule": $sort_rule} | compact), body: null}
}

# GET /api/albums
export def "albums list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --disc-types: string@disc-types-completer
  --tag-name: list<string>
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --artist-id: list<int>
  --artist-participation-status: string@artist-participation-status-completer
  --child-voicebanks: oneof<nothing, bool> # default: false
  --include-members: oneof<nothing, bool> # default: false
  --barcode: string
  --status: string@status-completer
  --release-date-after: string # format: date-time
  --release-date-before: string # format: date-time
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer
  --prefer-accurate-matches: oneof<nothing, bool> # default: false
  --deleted: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-1
  --lang: string@lang-completer
]: nothing -> record<items: table<additionalNames: string, artistString: string, artists: list, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list, id: int, identifiers: list, mainPicture: record, mergedTo: int, name: string, names: list, pvs: list, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, tags: list, tracks: list, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "discTypes" $disc_types "scalar") (serialize-qp "tagName[]" $tag_name "multi") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "childTags" $child_tags "scalar") (serialize-qp "artistId[]" $artist_id "multi") (serialize-qp "artistParticipationStatus" $artist_participation_status "scalar") (serialize-qp "childVoicebanks" $child_voicebanks "scalar") (serialize-qp "includeMembers" $include_members "scalar") (serialize-qp "barcode" $barcode "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "releaseDateAfter" $release_date_after "scalar") (serialize-qp "releaseDateBefore" $release_date_before "scalar") (serialize-qp "advancedFilters" $advanced_filters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "preferAccurateMatches" $prefer_accurate_matches "scalar") (serialize-qp "deleted" $deleted "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/albums" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "discTypes": $disc_types, "tagName[]": $tag_name, "tagId[]": $tag_id, "childTags": $child_tags, "artistId[]": $artist_id, "artistParticipationStatus": $artist_participation_status, "childVoicebanks": $child_voicebanks, "includeMembers": $include_members, "barcode": $barcode, "status": $status, "releaseDateAfter": $release_date_after, "releaseDateBefore": $release_date_before, "advancedFilters": $advanced_filters, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "preferAccurateMatches": $prefer_accurate_matches, "deleted": $deleted, "nameMatchMode": $name_match_mode, "fields": $fields, "lang": $lang} | compact), body: null}
}

# DELETE /api/albums/comments/{commentId}
export def "albums-comments delete" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/albums/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/albums/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "albums-comments create-by-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/albums/comments/{comment_id}"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/albums/names
export def "albums-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 15
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/albums/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "nameMatchMode": $name_match_mode, "maxResults": $max_results} | compact), body: null}
}

# GET /api/albums/new
export def "albums-new get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --language-preference: string@language-preference-completer
  --fields: string@fields-completer-1
]: nothing -> table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languagePreference" $language_preference "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/albums/new" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"languagePreference": $language_preference, "fields": $fields} | compact), body: null}
}

# GET /api/albums/top
export def "albums-top get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ignore-ids: list<int>
  --language-preference: string@language-preference-completer
  --fields: string@fields-completer-1
]: nothing -> table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignoreIds[]" $ignore_ids "multi") (serialize-qp "languagePreference" $language_preference "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/albums/top" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ignoreIds[]": $ignore_ids, "languagePreference": $language_preference, "fields": $fields} | compact), body: null}
}

# DELETE /api/albums/{id}
export def "albums delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "notes" $notes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"notes": $notes} | compact), body: null}
}

# GET /api/albums/{id}
export def "albums get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-1
  --song-fields: string@song-fields-completer
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, isSupport: bool, name: string, roles: string>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: table<discNumber: int, id: int, mediaType: string, name: string>, id: int, identifiers: table<value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: table<language: string, value: string>, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, status: string, tags: table<count: int, tag: record>, tracks: table<discNumber: int, id: int, name: string, rating: string, song: record, trackNumber: int>, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "songFields" $song_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "songFields": $song_fields, "lang": $lang} | compact), body: null}
}

# GET /api/albums/{id}/comments
export def "albums-comments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/albums/{id}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "albums-comments create-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --body-id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}/comments"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $body_id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/albums/{id}/reviews
export def "albums-reviews get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --language-code: string
]: nothing -> table<albumId: int, date: string, id: int, languageCode: string, text: string, title: string, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "languageCode" $language_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}/reviews") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"languageCode": $language_code} | compact), body: null}
}

# POST /api/albums/{id}/reviews
#
# --user shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
export def "albums-reviews create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --album-id: int # format: int32
  --date: string # format: date-time
  --body-id: int # format: int32
  --language-code: string # nullable
  --text: string # nullable
  --title: string # nullable
  --user: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
]: any -> record<albumId: int, date: string, id: int, languageCode: string, text: string, title: string, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}/reviews"))
  let req_body = {"albumId": $album_id, "date": $date, "id": $body_id, "languageCode": $language_code, "text": $text, "title": $title, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DELETE /api/albums/{id}/reviews/{reviewId}
export def "albums-reviews delete" [
  id: string
  review_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($review_id | is-empty) { error make --unspanned { msg: "path parameter 'reviewId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), review_id: (encode-path-segment $review_id)} | format pattern "/api/albums/{id}/reviews/{review_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /api/albums/{id}/tracks
export def "albums-tracks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> table<discNumber: int, id: int, name: string, rating: string, song: record<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, trackNumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}/tracks") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/albums/{id}/tracks/fields
export def "albums-tracks-fields get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --field: list<string>
  --disc-number: int # format: int32
  --lang: string@lang-completer
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "field[]" $field "multi") (serialize-qp "discNumber" $disc_number "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}/tracks/fields") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"field[]": $field, "discNumber": $disc_number, "lang": $lang} | compact), body: null}
}

# GET /api/albums/{id}/user-collections
export def "albums-user-collections get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --language-preference: string@language-preference-completer
]: nothing -> table<album: record<additionalNames: string, artistString: string, artists: list, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list, id: int, identifiers: list, mainPicture: record, mergedTo: int, name: string, names: list, pvs: list, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, tags: list, tracks: list, version: int, webLinks: list>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "languagePreference" $language_preference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/albums/{id}/user-collections") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"languagePreference": $language_preference} | compact), body: null}
}

# GET /api/artists
export def "artists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --artist-types: string
  --allow-base-voicebanks: oneof<nothing, bool> # default: true
  --tag-name: list<string>
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --followed-by-user-id: int # format: int32
  --status: string@status-completer
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-1
  --prefer-accurate-matches: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-3
  --lang: string@lang-completer
]: nothing -> record<items: table<additionalNames: string, artistLinks: list, artistLinksReverse: list, artistType: string, baseVoicebank: record, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record, mergedTo: int, name: string, names: list, pictureMime: string, relations: record, releaseDate: string, status: string, tags: list, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "artistTypes" $artist_types "scalar") (serialize-qp "allowBaseVoicebanks" $allow_base_voicebanks "scalar") (serialize-qp "tagName[]" $tag_name "multi") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "childTags" $child_tags "scalar") (serialize-qp "followedByUserId" $followed_by_user_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "advancedFilters" $advanced_filters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "preferAccurateMatches" $prefer_accurate_matches "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/artists" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "artistTypes": $artist_types, "allowBaseVoicebanks": $allow_base_voicebanks, "tagName[]": $tag_name, "tagId[]": $tag_id, "childTags": $child_tags, "followedByUserId": $followed_by_user_id, "status": $status, "advancedFilters": $advanced_filters, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "preferAccurateMatches": $prefer_accurate_matches, "nameMatchMode": $name_match_mode, "fields": $fields, "lang": $lang} | compact), body: null}
}

# DELETE /api/artists/comments/{commentId}
export def "artists-comments delete" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/artists/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/artists/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "artists-comments create-by-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/artists/comments/{comment_id}"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/artists/names
export def "artists-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 15
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/artists/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "nameMatchMode": $name_match_mode, "maxResults": $max_results} | compact), body: null}
}

# DELETE /api/artists/{id}
export def "artists delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "notes" $notes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/artists/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"notes": $notes} | compact), body: null}
}

# GET /api/artists/{id}
export def "artists get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-3
  --relations: string@relations-completer
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, artistLinks: table<artist: record, linkType: string>, artistLinksReverse: table<artist: record, linkType: string>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: table<language: string, value: string>, pictureMime: string, relations: record<latestAlbums: list<record>, latestEvents: list<record>, latestSongs: list<record>, popularAlbums: list<record>, popularSongs: list<record>>, releaseDate: string, status: string, tags: table<count: int, tag: record>, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "relations" $relations "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/artists/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "relations": $relations, "lang": $lang} | compact), body: null}
}

# GET /api/artists/{id}/comments
export def "artists-comments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/artists/{id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/artists/{id}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "artists-comments create-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --body-id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/artists/{id}/comments"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $body_id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/comments
export def "comments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --before: string # format: date-time
  --since: string # format: date-time
  --user-id: int # format: int32
  --entry-type: string@entry-type-completer
  --max-results: int # format: int32, default: 50
  --get-total-count: oneof<nothing, bool> # default: false
  --fields: string@fields-completer-4
  --entry-fields: string@entry-fields-completer
  --lang: string@lang-completer
  --sort-rule: string@sort-rule-completer
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "entryType" $entry_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "entryFields" $entry_fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "sortRule" $sort_rule "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/comments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"before": $before, "since": $since, "userId": $user_id, "entryType": $entry_type, "maxResults": $max_results, "getTotalCount": $get_total_count, "fields": $fields, "entryFields": $entry_fields, "lang": $lang, "sortRule": $sort_rule} | compact), body: null}
}

# GET /api/comments/{entryType}-comments
export def "comments get" [
  entry_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --entry-id: int # format: int32
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entry_type | is-empty) { error make --unspanned { msg: "path parameter 'entryType' must be non-empty" } }
  let qp = [(serialize-qp "entryId" $entry_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entry_type: (encode-path-segment $entry_type)} | format pattern "/api/comments/{entry_type}-comments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entryId": $entry_id} | compact), body: null}
}

# POST /api/comments/{entryType}-comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "comments create-by-entry-type" [
  entry_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entry_type | is-empty) { error make --unspanned { msg: "path parameter 'entryType' must be non-empty" } }
  let full_url = (build-url $base ({entry_type: (encode-path-segment $entry_type)} | format pattern "/api/comments/{entry_type}-comments"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DELETE /api/comments/{entryType}-comments/{commentId}
export def "comments delete" [
  entry_type: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entry_type | is-empty) { error make --unspanned { msg: "path parameter 'entryType' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({entry_type: (encode-path-segment $entry_type), comment_id: (encode-path-segment $comment_id)} | format pattern "/api/comments/{entry_type}-comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/comments/{entryType}-comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "comments create-by-entry-type-comment-id" [
  entry_type: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entry_type | is-empty) { error make --unspanned { msg: "path parameter 'entryType' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({entry_type: (encode-path-segment $entry_type), comment_id: (encode-path-segment $comment_id)} | format pattern "/api/comments/{entry_type}-comments/{comment_id}"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DELETE /api/discussions/comments/{commentId}
export def "discussions-comments delete" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/discussions/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/discussions/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "discussions-comments create" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/discussions/comments/{comment_id}"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/discussions/folders
export def "discussions-folders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-5
]: nothing -> table<description: string, id: int, lastTopicAuthor: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, lastTopicDate: string, name: string, topicCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/discussions/folders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# POST /api/discussions/folders
#
# --lastTopicAuthor shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
export def "discussions-folders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --description: string # nullable
  --id: int # format: int32
  --last-topic-author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --last-topic-date: string # nullable, format: date-time
  --name: string # nullable
  --topic-count: int # format: int32
]: any -> record<description: string, id: int, lastTopicAuthor: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, lastTopicDate: string, name: string, topicCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/discussions/folders")
  let req_body = {"description": $description, "id": $id, "lastTopicAuthor": $last_topic_author, "lastTopicDate": $last_topic_date, "name": $name, "topicCount": $topic_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/discussions/folders/{folderId}/topics
#
# DEPRECATED
@deprecated
export def "discussions-folders-topics get" [
  folder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-6
]: nothing -> table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, commentCount: int, comments: list<record>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record, authorName: string, created: string, entry: record, id: int, message: string>, locked: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'folderId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/api/discussions/folders/{folder_id}/topics") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# POST /api/discussions/folders/{folderId}/topics
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --comments item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
# --lastComment shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
export def "discussions-folders-topics create" [
  folder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --comment-count: int # format: int32
  --comments: list # nullable — item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --content: string # nullable
  --created: string # format: date-time
  --body-folder-id: int # format: int32
  --id: int # format: int32
  --last-comment: record # shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --locked: oneof<nothing, bool>
  --name: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, commentCount: int, comments: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>, locked: bool, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($folder_id | is-empty) { error make --unspanned { msg: "path parameter 'folderId' must be non-empty" } }
  let full_url = (build-url $base ({folder_id: (encode-path-segment $folder_id)} | format pattern "/api/discussions/folders/{folder_id}/topics"))
  let req_body = {"author": $author, "commentCount": $comment_count, "comments": $comments, "content": $content, "created": $created, "folderId": $body_folder_id, "id": $id, "lastComment": $last_comment, "locked": $locked, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/discussions/topics
export def "discussions-topics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --folder-id: int # format: int32
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-2
  --fields: string@fields-completer-6
]: nothing -> record<items: table<author: record, commentCount: int, comments: list, content: string, created: string, folderId: int, id: int, lastComment: record, locked: bool, name: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "folderId" $folder_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/discussions/topics" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"folderId": $folder_id, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "fields": $fields} | compact), body: null}
}

# DELETE /api/discussions/topics/{topicId}
export def "discussions-topics delete" [
  topic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($topic_id | is-empty) { error make --unspanned { msg: "path parameter 'topicId' must be non-empty" } }
  let full_url = (build-url $base ({topic_id: (encode-path-segment $topic_id)} | format pattern "/api/discussions/topics/{topic_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /api/discussions/topics/{topicId}
export def "discussions-topics get" [
  topic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-6
]: nothing -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, commentCount: int, comments: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, content: string, created: string, folderId: int, id: int, lastComment: record<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string>, locked: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($topic_id | is-empty) { error make --unspanned { msg: "path parameter 'topicId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({topic_id: (encode-path-segment $topic_id)} | format pattern "/api/discussions/topics/{topic_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# POST /api/discussions/topics/{topicId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --comments item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
# --lastComment shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
export def "discussions-topics create" [
  topic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --comment-count: int # format: int32
  --comments: list # nullable — item shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --content: string # nullable
  --created: string # format: date-time
  --folder-id: int # format: int32
  --id: int # format: int32
  --last-comment: record # shape: {author?: record, authorName?: string, created?: string, entry?: record, id?: int, message?: string}
  --locked: oneof<nothing, bool>
  --name: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($topic_id | is-empty) { error make --unspanned { msg: "path parameter 'topicId' must be non-empty" } }
  let full_url = (build-url $base ({topic_id: (encode-path-segment $topic_id)} | format pattern "/api/discussions/topics/{topic_id}"))
  let req_body = {"author": $author, "commentCount": $comment_count, "comments": $comments, "content": $content, "created": $created, "folderId": $folder_id, "id": $id, "lastComment": $last_comment, "locked": $locked, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /api/discussions/topics/{topicId}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "discussions-topics-comments create" [
  topic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($topic_id | is-empty) { error make --unspanned { msg: "path parameter 'topicId' must be non-empty" } }
  let full_url = (build-url $base ({topic_id: (encode-path-segment $topic_id)} | format pattern "/api/discussions/topics/{topic_id}/comments"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/entries
export def "entries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --tag-name: list<string>
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --entry-types: string@entry-types-completer
  --status: string@status-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-3
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-7
  --lang: string@lang-completer
]: nothing -> record<items: table<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "tagName[]" $tag_name "multi") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "childTags" $child_tags "scalar") (serialize-qp "entryTypes" $entry_types "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "tagName[]": $tag_name, "tagId[]": $tag_id, "childTags": $child_tags, "entryTypes": $entry_types, "status": $status, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "nameMatchMode": $name_match_mode, "fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/entries/names
export def "entries-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 10
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entries/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "nameMatchMode": $name_match_mode, "maxResults": $max_results} | compact), body: null}
}

# GET /api/entry-types/{entryType}/{subType}/tag
export def "entry-types-tag get" [
  entry_type: string
  sub_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-8
]: nothing -> record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($entry_type | is-empty) { error make --unspanned { msg: "path parameter 'entryType' must be non-empty" } }
  if ($sub_type | is-empty) { error make --unspanned { msg: "path parameter 'subType' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({entry_type: (encode-path-segment $entry_type), sub_type: (encode-path-segment $sub_type)} | format pattern "/api/entry-types/{entry_type}/{sub_type}/tag") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# GET /api/pvs/for-songs
export def "pvs-for-songs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string
  --author: string
  --service: string@service-completer
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --lang: string@lang-completer
]: nothing -> record<items: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, song: record, thumbUrl: string, url: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "service" $service "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/pvs/for-songs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name, "author": $author, "service": $service, "maxResults": $max_results, "getTotalCount": $get_total_count, "lang": $lang} | compact), body: null}
}

# GET /api/releaseEventSeries
export def "release-event-series list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --fields: string@fields-completer-9
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --lang: string@lang-completer
]: nothing -> record<items: table<additionalNames: string, category: string, description: string, events: list, id: int, mainPicture: record, name: string, names: list, status: string, urlSlug: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/releaseEventSeries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "fields": $fields, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "nameMatchMode": $name_match_mode, "lang": $lang} | compact), body: null}
}

# DELETE /api/releaseEventSeries/{id}
export def "release-event-series delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/releaseEventSeries/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"notes": $notes, "hardDelete": $hard_delete} | compact), body: null}
}

# GET /api/releaseEventSeries/{id}
export def "release-event-series get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-9
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, category: string, description: string, events: table<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<language: string, value: string>, status: string, urlSlug: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/releaseEventSeries/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/releaseEventSeries/{id}/for-edit
export def "release-event-series-for-edit get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<category: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, status: string, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/releaseEventSeries/{id}/for-edit"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /api/releaseEvents
export def "release-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --name-match-mode: string@name-match-mode-completer
  --series-id: int # format: int32, default: 0
  --after-date: string # format: date-time
  --before-date: string # format: date-time
  --category: string@category-completer
  --user-collection-id: int # format: int32
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --artist-id: list<int>
  --child-voicebanks: oneof<nothing, bool> # default: false
  --include-members: oneof<nothing, bool> # default: false
  --status: string@status-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-4
  --fields: string@fields-completer-10
  --lang: string@lang-completer
  --sort-direction: string@sort-direction-completer
]: nothing -> record<items: table<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "seriesId" $series_id "scalar") (serialize-qp "afterDate" $after_date "scalar") (serialize-qp "beforeDate" $before_date "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "userCollectionId" $user_collection_id "scalar") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "childTags" $child_tags "scalar") (serialize-qp "artistId[]" $artist_id "multi") (serialize-qp "childVoicebanks" $child_voicebanks "scalar") (serialize-qp "includeMembers" $include_members "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "sortDirection" $sort_direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/releaseEvents" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "nameMatchMode": $name_match_mode, "seriesId": $series_id, "afterDate": $after_date, "beforeDate": $before_date, "category": $category, "userCollectionId": $user_collection_id, "tagId[]": $tag_id, "childTags": $child_tags, "artistId[]": $artist_id, "childVoicebanks": $child_voicebanks, "includeMembers": $include_members, "status": $status, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "fields": $fields, "lang": $lang, "sortDirection": $sort_direction} | compact), body: null}
}

# GET /api/releaseEvents/names
export def "release-events-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --max-results: int # format: int32, default: 10
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/releaseEvents/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "maxResults": $max_results} | compact), body: null}
}

# GET /api/releaseEvents/{eventId}/albums
export def "release-events-albums get" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-1
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/api/releaseEvents/{event_id}/albums") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/releaseEvents/{eventId}/published-songs
export def "release-events-published-songs get" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/api/releaseEvents/{event_id}/published-songs") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# POST /api/releaseEvents/{eventId}/reports
export def "release-events-reports create" [
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer
  --notes: string
  --version-number: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_id | is-empty) { error make --unspanned { msg: "path parameter 'eventId' must be non-empty" } }
  let qp = [(serialize-qp "reportType" $report_type "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "versionNumber" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/api/releaseEvents/{event_id}/reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportType": $report_type, "notes": $notes, "versionNumber": $version_number} | compact), body: null}
}

# DELETE /api/releaseEvents/{id}
export def "release-events delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/releaseEvents/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"notes": $notes, "hardDelete": $hard_delete} | compact), body: null}
}

# GET /api/releaseEvents/{id}
export def "release-events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-10
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, artists: table<artist: record, effectiveRoles: string, id: int, name: string, roles: string>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<language: string, value: string>, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list<record>>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: table<count: int, tag: record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record<formatted: string, hasValue: bool, latitude: float, longitude: float>, deleted: bool, description: string, events: list<record>, id: int, name: string, names: list<record>, status: string, version: int, webLinks: list<record>>, venueName: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/releaseEvents/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/resources/{cultureCode}
export def "resources get" [
  culture_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --set-names: list<string>
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($culture_code | is-empty) { error make --unspanned { msg: "path parameter 'cultureCode' must be non-empty" } }
  let qp = [(serialize-qp "setNames[]" $set_names "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({culture_code: (encode-path-segment $culture_code)} | format pattern "/api/resources/{culture_code}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"setNames[]": $set_names} | compact), body: null}
}

# POST /api/songLists
#
# --mainPicture shape: {mime?: string, name?: string, urlOriginal?: string, urlSmallThumb?: string, urlThumb?: string, urlTinyThumb?: string}
# --songLinks item shape: {notes?: string, order?: int, song?: record, songInListId?: int}
export def "song-lists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --deleted: oneof<nothing, bool>
  --description: string # nullable
  --event-date: string # nullable, format: date-time
  --featured-category: string@featured-category-completer
  --id: int # format: int32
  --main-picture: record # shape: {mime?: string, name?: string, urlOriginal?: string, urlSmallThumb?: string, urlThumb?: string, urlTinyThumb?: string}
  --name: string # nullable
  --song-links: list # nullable — item shape: {notes?: string, order?: int, song?: record, songInListId?: int}
  --status: string@status-completer
  --update-notes: string # nullable
]: any -> oneof<int, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/songLists")
  let req_body = {"deleted": $deleted, "description": $description, "eventDate": $event_date, "featuredCategory": $featured_category, "id": $id, "mainPicture": $main_picture, "name": $name, "songLinks": $song_links, "status": $status, "updateNotes": $update_notes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# DELETE /api/songLists/comments/{commentId}
export def "song-lists-comments delete" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/songLists/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/songLists/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "song-lists-comments create-by-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/songLists/comments/{comment_id}"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/songLists/featured
export def "song-lists-featured get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --featured-category: string@featured-category-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-5
  --fields: string@fields-completer-11
  --lang: string@lang-completer
]: nothing -> record<items: table<author: record, deleted: bool, description: string, eventDate: string, events: list, featuredCategory: string, id: int, latestComments: list, mainPicture: record, name: string, status: string, tags: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "childTags" $child_tags "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "featuredCategory" $featured_category "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songLists/featured" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "tagId[]": $tag_id, "childTags": $child_tags, "nameMatchMode": $name_match_mode, "featuredCategory": $featured_category, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/songLists/featured/names
export def "song-lists-featured-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --name-match-mode: string@name-match-mode-completer
  --featured-category: string@featured-category-completer
  --max-results: int # format: int32, default: 10
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "featuredCategory" $featured_category "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songLists/featured/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "nameMatchMode": $name_match_mode, "featuredCategory": $featured_category, "maxResults": $max_results} | compact), body: null}
}

# DELETE /api/songLists/{id}
export def "song-lists delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songLists/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"notes": $notes, "hardDelete": $hard_delete} | compact), body: null}
}

# GET /api/songLists/{listId}/comments
export def "song-lists-comments get" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/api/songLists/{list_id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/songLists/{listId}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "song-lists-comments create-by-list-id" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/api/songLists/{list_id}/comments"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/songLists/{listId}/songs
export def "song-lists-songs get" [
  list_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --song-types: string
  --pv-services: string@pv-services-completer
  --tag-id: list<int>
  --artist-id: list<int>
  --child-voicebanks: oneof<nothing, bool> # default: false
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-6
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<items: table<notes: string, order: int, song: record>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($list_id | is-empty) { error make --unspanned { msg: "path parameter 'listId' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "songTypes" $song_types "scalar") (serialize-qp "pvServices" $pv_services "scalar") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "artistId[]" $artist_id "multi") (serialize-qp "childVoicebanks" $child_voicebanks "scalar") (serialize-qp "advancedFilters" $advanced_filters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({list_id: (encode-path-segment $list_id)} | format pattern "/api/songLists/{list_id}/songs") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "songTypes": $song_types, "pvServices": $pv_services, "tagId[]": $tag_id, "artistId[]": $artist_id, "childVoicebanks": $child_voicebanks, "advancedFilters": $advanced_filters, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "nameMatchMode": $name_match_mode, "fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/songs
export def "songs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --song-types: string
  --after-date: string # format: date-time
  --before-date: string # format: date-time
  --tag-name: list<string>
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --unify-types-and-tags: oneof<nothing, bool> # default: false
  --artist-id: list<int>
  --artist-participation-status: string@artist-participation-status-completer
  --child-voicebanks: oneof<nothing, bool> # default: false
  --include-members: oneof<nothing, bool> # default: false
  --only-with-pvs: oneof<nothing, bool> # default: false
  --pv-services: string@pv-services-completer
  --since: int # format: int32
  --min-score: int # format: int32
  --user-collection-id: int # format: int32
  --release-event-id: int # format: int32
  --parent-song-id: int # format: int32
  --status: string@status-completer
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-6
  --prefer-accurate-matches: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-2
  --lang: string@lang-completer
  --min-milli-bpm: int # format: int32
  --max-milli-bpm: int # format: int32
  --min-length: int # format: int32
  --max-length: int # format: int32
]: nothing -> record<items: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "songTypes" $song_types "scalar") (serialize-qp "afterDate" $after_date "scalar") (serialize-qp "beforeDate" $before_date "scalar") (serialize-qp "tagName[]" $tag_name "multi") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "childTags" $child_tags "scalar") (serialize-qp "unifyTypesAndTags" $unify_types_and_tags "scalar") (serialize-qp "artistId[]" $artist_id "multi") (serialize-qp "artistParticipationStatus" $artist_participation_status "scalar") (serialize-qp "childVoicebanks" $child_voicebanks "scalar") (serialize-qp "includeMembers" $include_members "scalar") (serialize-qp "onlyWithPvs" $only_with_pvs "scalar") (serialize-qp "pvServices" $pv_services "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "minScore" $min_score "scalar") (serialize-qp "userCollectionId" $user_collection_id "scalar") (serialize-qp "releaseEventId" $release_event_id "scalar") (serialize-qp "parentSongId" $parent_song_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "advancedFilters" $advanced_filters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "preferAccurateMatches" $prefer_accurate_matches "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "minMilliBpm" $min_milli_bpm "scalar") (serialize-qp "maxMilliBpm" $max_milli_bpm "scalar") (serialize-qp "minLength" $min_length "scalar") (serialize-qp "maxLength" $max_length "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "songTypes": $song_types, "afterDate": $after_date, "beforeDate": $before_date, "tagName[]": $tag_name, "tagId[]": $tag_id, "childTags": $child_tags, "unifyTypesAndTags": $unify_types_and_tags, "artistId[]": $artist_id, "artistParticipationStatus": $artist_participation_status, "childVoicebanks": $child_voicebanks, "includeMembers": $include_members, "onlyWithPvs": $only_with_pvs, "pvServices": $pv_services, "since": $since, "minScore": $min_score, "userCollectionId": $user_collection_id, "releaseEventId": $release_event_id, "parentSongId": $parent_song_id, "status": $status, "advancedFilters": $advanced_filters, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "preferAccurateMatches": $prefer_accurate_matches, "nameMatchMode": $name_match_mode, "fields": $fields, "lang": $lang, "minMilliBpm": $min_milli_bpm, "maxMilliBpm": $max_milli_bpm, "minLength": $min_length, "maxLength": $max_length} | compact), body: null}
}

# GET /api/songs/byPv
export def "songs-by-pv get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --pv-service: string@pv-service-completer
  --pv-id: string
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, albums: table<additionalNames: string, artistString: string, coverPictureMime: string, createDate: string, deleted: bool, discType: string, id: int, name: string, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, version: int>, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, id: int, isCustomName: bool, isSupport: bool, name: string, roles: string>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: table<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: table<language: string, value: string>, originalVersionId: int, publishDate: string, pvServices: string, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, songType: string, status: string, tags: table<count: int, tag: record>, thumbUrl: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pvService" $pv_service "scalar") (serialize-qp "pvId" $pv_id "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs/byPv" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pvService": $pv_service, "pvId": $pv_id, "fields": $fields, "lang": $lang} | compact), body: null}
}

# DELETE /api/songs/comments/{commentId}
export def "songs-comments delete" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/songs/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/songs/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "songs-comments create-by-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/songs/comments/{comment_id}"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/songs/highlighted
export def "songs-highlighted get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --language-preference: string@language-preference-completer
  --fields: string@fields-completer-2
]: nothing -> table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "languagePreference" $language_preference "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs/highlighted" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"languagePreference": $language_preference, "fields": $fields} | compact), body: null}
}

# GET /api/songs/lyrics/{lyricsId}
export def "songs-lyrics get" [
  lyrics_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($lyrics_id | is-empty) { error make --unspanned { msg: "path parameter 'lyricsId' must be non-empty" } }
  let full_url = (build-url $base ({lyrics_id: (encode-path-segment $lyrics_id)} | format pattern "/api/songs/lyrics/{lyrics_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /api/songs/names
export def "songs-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 15
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "nameMatchMode": $name_match_mode, "maxResults": $max_results} | compact), body: null}
}

# GET /api/songs/top-rated
export def "songs-top-rated get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --duration-hours: int # format: int32
  --start-date: string # format: date-time
  --filter-by: string@filter-by-completer
  --vocalist: string@vocalist-completer
  --max-results: int # format: int32, default: 25
  --fields: string@fields-completer-2
  --language-preference: string@language-preference-completer
]: nothing -> table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "durationHours" $duration_hours "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "filterBy" $filter_by "scalar") (serialize-qp "vocalist" $vocalist "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "languagePreference" $language_preference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/songs/top-rated" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"durationHours": $duration_hours, "startDate": $start_date, "filterBy": $filter_by, "vocalist": $vocalist, "maxResults": $max_results, "fields": $fields, "languagePreference": $language_preference} | compact), body: null}
}

# DELETE /api/songs/{id}
export def "songs delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "notes" $notes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songs/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"notes": $notes} | compact), body: null}
}

# GET /api/songs/{id}
export def "songs get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, albums: table<additionalNames: string, artistString: string, coverPictureMime: string, createDate: string, deleted: bool, discType: string, id: int, name: string, ratingAverage: float, ratingCount: int, releaseDate: record, releaseEvent: record, status: string, version: int>, artistString: string, artists: table<artist: record, categories: string, effectiveRoles: string, id: int, isCustomName: bool, isSupport: bool, name: string, roles: string>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: table<cultureCode: string, id: int, source: string, translationType: string, url: string, value: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: table<language: string, value: string>, originalVersionId: int, publishDate: string, pvServices: string, pvs: table<author: string, createdBy: int, disabled: bool, extendedMetadata: record, id: int, length: int, name: string, publishDate: string, pvId: string, pvType: string, service: string, thumbUrl: string, url: string>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>>, songType: string, status: string, tags: table<count: int, tag: record>, thumbUrl: string, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songs/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/songs/{id}/comments
export def "songs-comments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> table<author: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record, name: string, names: list, pvs: list, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list, urlSlug: string, version: int, webLinks: list>, id: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songs/{id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/songs/{id}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "songs-comments create-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --body-id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songs/{id}/comments"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $body_id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/songs/{id}/derived
export def "songs-derived get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, albums: list<record>, artistString: string, artists: list<record>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list<record>, originalVersionId: int, publishDate: string, pvServices: string, pvs: list<record>, ratingScore: int, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, songType: string, status: string, tags: list<record>, thumbUrl: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songs/{id}/derived") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/songs/{id}/ratings
export def "songs-ratings get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --user-fields: string@user-fields-completer
  --lang: string@lang-completer
]: nothing -> table<date: string, rating: string, song: record<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, user: record<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "userFields" $user_fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songs/{id}/ratings") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"userFields": $user_fields, "lang": $lang} | compact), body: null}
}

# POST /api/songs/{id}/ratings
export def "songs-ratings create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rating: string@rating-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songs/{id}/ratings"))
  let req_body = {"rating": $rating} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/songs/{id}/related
export def "songs-related get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<artistMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, likeMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>, tagMatches: table<additionalNames: string, albums: list, artistString: string, artists: list, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, favoritedTimes: int, id: int, lengthSeconds: int, lyrics: list, mainPicture: record, maxMilliBpm: int, mergedTo: int, minMilliBpm: int, name: string, names: list, originalVersionId: int, publishDate: string, pvServices: string, pvs: list, ratingScore: int, releaseEvent: record, songType: string, status: string, tags: list, thumbUrl: string, version: int, webLinks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/songs/{id}/related") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/tags
export def "tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --allow-children: oneof<nothing, bool> # default: true
  --category-name: string # default: 
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --qp-sort: string@sort-completer-7
  --prefer-accurate-matches: oneof<nothing, bool> # default: false
  --fields: string@fields-completer-8
  --lang: string@lang-completer
  --target: string@target-completer
]: nothing -> record<items: table<additionalNames: string, aliasedTo: record, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record, name: string, names: list, parent: record, relatedTags: list, status: string, targets: int, translatedDescription: record, urlSlug: string, usageCount: int, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "allowChildren" $allow_children "scalar") (serialize-qp "categoryName" $category_name "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "preferAccurateMatches" $prefer_accurate_matches "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "target" $target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "allowChildren": $allow_children, "categoryName": $category_name, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "nameMatchMode": $name_match_mode, "sort": $qp_sort, "preferAccurateMatches": $prefer_accurate_matches, "fields": $fields, "lang": $lang, "target": $target} | compact), body: null}
}

# POST /api/tags
export def "tags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string
]: nothing -> record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"name": $name} | compact), body: null}
}

# GET /api/tags/byName/{name}
#
# DEPRECATED
@deprecated
export def "tags-by-name get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/api/tags/byName/{name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/tags/categoryNames
export def "tags-category-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --name-match-mode: string@name-match-mode-completer
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags/categoryNames" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "nameMatchMode": $name_match_mode} | compact), body: null}
}

# DELETE /api/tags/comments/{commentId}
export def "tags-comments delete" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/tags/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/tags/comments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "tags-comments create-by-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/tags/comments/{comment_id}"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/tags/names
export def "tags-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --allow-aliases: oneof<nothing, bool> # default: true
  --max-results: int # format: int32, default: 10
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "allowAliases" $allow_aliases "scalar") (serialize-qp "maxResults" $max_results "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "allowAliases": $allow_aliases, "maxResults": $max_results} | compact), body: null}
}

# GET /api/tags/top
export def "tags-top get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --category-name: string
  --entry-type: string@entry-type-completer
  --max-results: int # format: int32, default: 15
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryName" $category_name "scalar") (serialize-qp "entryType" $entry_type "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags/top" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"categoryName": $category_name, "entryType": $entry_type, "maxResults": $max_results, "lang": $lang} | compact), body: null}
}

# DELETE /api/tags/{id}
export def "tags delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/tags/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"notes": $notes, "hardDelete": $hard_delete} | compact), body: null}
}

# GET /api/tags/{id}
export def "tags get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> record<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: table<id: int, language: string, value: string>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: table<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: table<category: string, description: string, descriptionOrUrl: string, disabled: bool, id: int, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/tags/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/tags/{tagId}/children
export def "tags-children get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-8
  --lang: string@lang-completer
]: nothing -> table<additionalNames: string, aliasedTo: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, categoryName: string, createDate: string, defaultNameLanguage: string, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, parent: record<additionalNames: string, categoryName: string, id: int, name: string, urlSlug: string>, relatedTags: list<record>, status: string, targets: int, translatedDescription: record<english: string, original: string>, urlSlug: string, usageCount: int, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/api/tags/{tag_id}/children") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/tags/{tagId}/comments
export def "tags-comments get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/api/tags/{tag_id}/comments"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/tags/{tagId}/comments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "tags-comments create-by-tag-id" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/api/tags/{tag_id}/comments"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /api/tags/{tagId}/reports
export def "tags-reports create" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer
  --notes: string
  --version-number: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "reportType" $report_type "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "versionNumber" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/api/tags/{tag_id}/reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportType": $report_type, "notes": $notes, "versionNumber": $version_number} | compact), body: null}
}

# GET /api/users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --groups: string@groups-completer
  --join-date-after: string # format: date-time
  --join-date-before: string # format: date-time
  --name-match-mode: string@name-match-mode-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-8
  --include-disabled: oneof<nothing, bool> # default: false
  --only-verified: oneof<nothing, bool> # default: false
  --knows-language: string
  --fields: string@fields-completer-12
]: nothing -> record<items: table<active: bool, groupId: string, id: int, knownLanguages: list, mainPicture: record, memberSince: string, name: string, oldUsernames: list, verifiedArtist: bool>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "groups" $groups "scalar") (serialize-qp "joinDateAfter" $join_date_after "scalar") (serialize-qp "joinDateBefore" $join_date_before "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "includeDisabled" $include_disabled "scalar") (serialize-qp "onlyVerified" $only_verified "scalar") (serialize-qp "knowsLanguage" $knows_language "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "groups": $groups, "joinDateAfter": $join_date_after, "joinDateBefore": $join_date_before, "nameMatchMode": $name_match_mode, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "includeDisabled": $include_disabled, "onlyVerified": $only_verified, "knowsLanguage": $knows_language, "fields": $fields} | compact), body: null}
}

# GET /api/users/current
export def "users-current get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-12
]: nothing -> record<active: bool, groupId: string, id: int, knownLanguages: table<cultureCode: string, proficiency: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: table<date: string, oldName: string>, verifiedArtist: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/current" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# GET /api/users/current/album-collection-statuses/{albumId}
export def "users-current-album-collection-statuses get" [
  album_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<album: record<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'albumId' must be non-empty" } }
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id)} | format pattern "/api/users/current/album-collection-statuses/{album_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/users/current/albums/{albumId}
export def "users-current-albums create" [
  album_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --collection-status: string@collection-status-completer
  --media-type: string@media-type-completer
  --rating: int # format: int32
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'albumId' must be non-empty" } }
  let qp = [(serialize-qp "collectionStatus" $collection_status "scalar") (serialize-qp "mediaType" $media_type "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({album_id: (encode-path-segment $album_id)} | format pattern "/api/users/current/albums/{album_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"collectionStatus": $collection_status, "mediaType": $media_type, "rating": $rating} | compact), body: null}
}

# GET /api/users/current/followedArtists/{artistId}
export def "users-current-followed-artists get" [
  artist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<artist: record<additionalNames: string, artistLinks: list<record>, artistLinksReverse: list<record>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pictureMime: string, relations: record<latestAlbums: list, latestEvents: list, latestSongs: list, popularAlbums: list, popularSongs: list>, releaseDate: string, status: string, tags: list<record>, version: int, webLinks: list<record>>, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($artist_id | is-empty) { error make --unspanned { msg: "path parameter 'artistId' must be non-empty" } }
  let full_url = (build-url $base ({artist_id: (encode-path-segment $artist_id)} | format pattern "/api/users/current/followedArtists/{artist_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /api/users/current/followedTags/{tagId}
export def "users-current-followed-tags delete" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/api/users/current/followedTags/{tag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/users/current/followedTags/{tagId}
export def "users-current-followed-tags create" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/api/users/current/followedTags/{tag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /api/users/current/ratedSongs/{songId}
export def "users-current-rated-songs get" [
  song_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($song_id | is-empty) { error make --unspanned { msg: "path parameter 'songId' must be non-empty" } }
  let full_url = (build-url $base ({song_id: (encode-path-segment $song_id)} | format pattern "/api/users/current/ratedSongs/{song_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/users/current/refreshEntryEdit
export def "users-current-refresh-entry-edit create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --entry-type: string@entry-type-completer
  --entry-id: int # format: int32
]: nothing -> record<time: string, userId: int, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entryType" $entry_type "scalar") (serialize-qp "entryId" $entry_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/current/refreshEntryEdit" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"entryType": $entry_type, "entryId": $entry_id} | compact), body: null}
}

# POST /api/users/current/songTags/{songId}
export def "users-current-song-tags create" [
  song_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($song_id | is-empty) { error make --unspanned { msg: "path parameter 'songId' must be non-empty" } }
  let full_url = (build-url $base ({song_id: (encode-path-segment $song_id)} | format pattern "/api/users/current/songTags/{song_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /api/users/messages/{messageId}
export def "users-messages get-by-message-id" [
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, sender: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'messageId' must be non-empty" } }
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/api/users/messages/{message_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /api/users/names
export def "users-names get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --name-match-mode: string@name-match-mode-completer
  --max-results: int # format: int32, default: 10
  --include-disabled: oneof<nothing, bool> # default: false
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "includeDisabled" $include_disabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/users/names" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "nameMatchMode": $name_match_mode, "maxResults": $max_results, "includeDisabled": $include_disabled} | compact), body: null}
}

# DELETE /api/users/profileComments/{commentId}
export def "users-profile-comments delete" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/users/profileComments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/users/profileComments/{commentId}
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "users-profile-comments create-by-comment-id" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --id: int # format: int32
  --message: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({comment_id: (encode-path-segment $comment_id)} | format pattern "/api/users/profileComments/{comment_id}"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/users/{id}
export def "users get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: string@fields-completer-12
]: nothing -> record<active: bool, groupId: string, id: int, knownLanguages: table<cultureCode: string, proficiency: string>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: table<date: string, oldName: string>, verifiedArtist: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields} | compact), body: null}
}

# GET /api/users/{id}/album-collection-statuses/{albumId}
export def "users-album-collection-statuses get" [
  id: int
  album_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<album: record<additionalNames: string, artistString: string, artists: list<record>, barcode: string, catalogNumber: string, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, discType: string, discs: list<record>, id: int, identifiers: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pvs: list<record>, ratingAverage: float, ratingCount: int, releaseDate: record<day: int, formatted: string, isEmpty: bool, month: int, year: int>, releaseEvent: record<additionalNames: string, artists: list, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record, name: string, names: list, pvs: list, series: record, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record, status: string, tags: list, urlSlug: string, venue: record, venueName: string, version: int, webLinks: list>, status: string, tags: list<record>, tracks: list<record>, version: int, webLinks: list<record>>, mediaType: string, purchaseStatus: string, rating: int, user: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($album_id | is-empty) { error make --unspanned { msg: "path parameter 'albumId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), album_id: (encode-path-segment $album_id)} | format pattern "/api/users/{id}/album-collection-statuses/{album_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /api/users/{id}/albums
export def "users-albums get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --tag-id: int # format: int32
  --tag: string
  --artist-id: int # format: int32
  --purchase-statuses: string@purchase-statuses-completer
  --release-event-id: int # format: int32, default: 0
  --album-types: string@album-types-completer
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-1
  --lang: string@lang-completer
  --media-type: string@media-type-completer
]: nothing -> record<items: table<album: record, mediaType: string, purchaseStatus: string, rating: int, user: record>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "tagId" $tag_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "artistId" $artist_id "scalar") (serialize-qp "purchaseStatuses" $purchase_statuses "scalar") (serialize-qp "releaseEventId" $release_event_id "scalar") (serialize-qp "albumTypes" $album_types "scalar") (serialize-qp "advancedFilters" $advanced_filters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "mediaType" $media_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/albums") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "tagId": $tag_id, "tag": $tag, "artistId": $artist_id, "purchaseStatuses": $purchase_statuses, "releaseEventId": $release_event_id, "albumTypes": $album_types, "advancedFilters": $advanced_filters, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "nameMatchMode": $name_match_mode, "fields": $fields, "lang": $lang, "mediaType": $media_type} | compact), body: null}
}

# GET /api/users/{id}/events
export def "users-events get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --relationship-type: string@relationship-type-completer
]: nothing -> table<additionalNames: string, artists: list<record>, category: string, date: string, description: string, endDate: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, series: record<additionalNames: string, category: string, deleted: bool, description: string, id: int, name: string, pictureMime: string, status: string, urlSlug: string, version: int, webLinks: list>, seriesId: int, seriesNumber: int, seriesSuffix: string, songList: record<featuredCategory: string, id: int, name: string>, status: string, tags: list<record>, urlSlug: string, venue: record<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, venueName: string, version: int, webLinks: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "relationshipType" $relationship_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/events") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"relationshipType": $relationship_type} | compact), body: null}
}

# GET /api/users/{id}/followedArtists
export def "users-followed-artists list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --tag-id: list<int>
  --artist-type: string@artist-type-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-1
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-3
  --lang: string@lang-completer
]: nothing -> record<items: table<artist: record, id: int>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "artistType" $artist_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/followedArtists") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "tagId[]": $tag_id, "artistType": $artist_type, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "nameMatchMode": $name_match_mode, "fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/users/{id}/followedArtists/{artistId}
export def "users-followed-artists get" [
  id: int
  artist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<artist: record<additionalNames: string, artistLinks: list<record>, artistLinksReverse: list<record>, artistType: string, baseVoicebank: record<additionalNames: string, artistType: string, deleted: bool, id: int, name: string, pictureMime: string, releaseDate: string, status: string, version: int>, createDate: string, defaultName: string, defaultNameLanguage: string, deleted: bool, description: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, mergedTo: int, name: string, names: list<record>, pictureMime: string, relations: record<latestAlbums: list, latestEvents: list, latestSongs: list, popularAlbums: list, popularSongs: list>, releaseDate: string, status: string, tags: list<record>, version: int, webLinks: list<record>>, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($artist_id | is-empty) { error make --unspanned { msg: "path parameter 'artistId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), artist_id: (encode-path-segment $artist_id)} | format pattern "/api/users/{id}/followedArtists/{artist_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE /api/users/{id}/messages
export def "users-messages delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message-id: list<int>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "messageId" $message_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"messageId": $message_id} | compact), body: null}
}

# GET /api/users/{id}/messages
export def "users-messages get-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --inbox: string@inbox-completer
  --unread: oneof<nothing, bool> # default: false
  --another-user-id: int # format: int32
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
]: nothing -> record<items: table<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record, sender: record, subject: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "inbox" $inbox "scalar") (serialize-qp "unread" $unread "scalar") (serialize-qp "anotherUserId" $another_user_id "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/messages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"inbox": $inbox, "unread": $unread, "anotherUserId": $another_user_id, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count} | compact), body: null}
}

# POST /api/users/{id}/messages
#
# --receiver shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --sender shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
export def "users-messages create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body: string # nullable
  --created-formatted: string # nullable
  --high-priority: oneof<nothing, bool>
  --body-id: int # format: int32
  --inbox: string@inbox-completer
  --read: oneof<nothing, bool>
  --receiver: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --sender: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --subject: string # nullable
]: any -> record<body: string, createdFormatted: string, highPriority: bool, id: int, inbox: string, read: bool, receiver: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, sender: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, subject: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/messages"))
  let req_body = {"body": $body, "createdFormatted": $created_formatted, "highPriority": $high_priority, "id": $body_id, "inbox": $inbox, "read": $read, "receiver": $receiver, "sender": $sender, "subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/users/{id}/profileComments
export def "users-profile-comments get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
]: nothing -> record<items: table<author: record, authorName: string, created: string, entry: record, id: int, message: string>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/profileComments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count} | compact), body: null}
}

# POST /api/users/{id}/profileComments
#
# --author shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
# --entry shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
export def "users-profile-comments create-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --author: record # shape: {active?: bool, groupId?: "Nothing"|"Limited"|"Regular"|"Trusted"|"Moderator"|"Admin", id?: int, knownLanguages?: list, mainPicture?: record, memberSince?: string, name?: string, oldUsernames?: list, verifiedArtist?: bool}
  --author-name: string # nullable
  --created: string # format: date-time
  --entry: record # shape: {activityDate?: string, additionalNames?: string, artistString?: string, artistType?: "Unknown"|"Circle"|"Label"|"Producer"|"Animator"|"Illustrator"|"Lyricist"|"Vocaloid"|"UTAU"|"CeVIO"|"OtherVoiceSynthesizer"|"OtherVocalist"|"OtherGroup"|"OtherIndividual"|"Utaite"|"Band"|"Vocalist"|"Character"|"SynthesizerV"|"CoverArtist", createDate?: string, defaultName?: string, defaultNameLanguage?: "Unspecified"|"Japanese"|"Romaji"|"English", description?: string, ... (17 more fields)}
  --body-id: int # format: int32
  --message: string # nullable
]: any -> record<author: record<active: bool, groupId: string, id: int, knownLanguages: list<record>, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, memberSince: string, name: string, oldUsernames: list<record>, verifiedArtist: bool>, authorName: string, created: string, entry: record<activityDate: string, additionalNames: string, artistString: string, artistType: string, createDate: string, defaultName: string, defaultNameLanguage: string, description: string, discType: string, entryType: string, eventCategory: string, id: int, mainPicture: record<mime: string, name: string, urlOriginal: string, urlSmallThumb: string, urlThumb: string, urlTinyThumb: string>, name: string, names: list<record>, pvs: list<record>, releaseEventSeriesName: string, songListFeaturedCategory: string, songType: string, status: string, tagCategoryName: string, tags: list<record>, urlSlug: string, version: int, webLinks: list<record>>, id: int, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/profileComments"))
  let req_body = {"author": $author, "authorName": $author_name, "created": $created, "entry": $entry, "id": $body_id, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/users/{id}/ratedSongs
export def "users-rated-songs list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --tag-name: string
  --tag-id: list<int>
  --artist-id: list<int>
  --child-voicebanks: oneof<nothing, bool> # default: false
  --artist-grouping: string@artist-grouping-completer
  --rating: string@rating-completer
  --song-list-id: int # format: int32
  --group-by-rating: oneof<nothing, bool> # default: true
  --pv-services: string@pv-services-completer
  --advanced-filters: list
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-9
  --name-match-mode: string@name-match-mode-completer
  --fields: string@fields-completer-2
  --lang: string@lang-completer
]: nothing -> record<items: table<date: string, rating: string, song: record, user: record>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "tagName" $tag_name "scalar") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "artistId[]" $artist_id "multi") (serialize-qp "childVoicebanks" $child_voicebanks "scalar") (serialize-qp "artistGrouping" $artist_grouping "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "songListId" $song_list_id "scalar") (serialize-qp "groupByRating" $group_by_rating "scalar") (serialize-qp "pvServices" $pv_services "scalar") (serialize-qp "advancedFilters" $advanced_filters "multi") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/ratedSongs") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "tagName": $tag_name, "tagId[]": $tag_id, "artistId[]": $artist_id, "childVoicebanks": $child_voicebanks, "artistGrouping": $artist_grouping, "rating": $rating, "songListId": $song_list_id, "groupByRating": $group_by_rating, "pvServices": $pv_services, "advancedFilters": $advanced_filters, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "nameMatchMode": $name_match_mode, "fields": $fields, "lang": $lang} | compact), body: null}
}

# GET /api/users/{id}/ratedSongs/{songId}
export def "users-rated-songs get" [
  id: int
  song_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($song_id | is-empty) { error make --unspanned { msg: "path parameter 'songId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), song_id: (encode-path-segment $song_id)} | format pattern "/api/users/{id}/ratedSongs/{song_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /api/users/{id}/reports
export def "users-reports create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --reason: string # nullable
  --report-type: string@report-type-completer-1
]: any -> oneof<bool, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/reports"))
  let req_body = {"reason": $reason, "reportType": $report_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /api/users/{id}/settings/{settingName}
export def "users-settings create" [
  id: int
  setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($setting_name | is-empty) { error make --unspanned { msg: "path parameter 'settingName' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), setting_name: (encode-path-segment $setting_name)} | format pattern "/api/users/{id}/settings/{setting_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# GET /api/users/{id}/songLists
export def "users-song-lists get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --tag-id: list<int>
  --child-tags: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --qp-sort: string@sort-completer-5
  --fields: string@fields-completer-11
]: nothing -> record<items: table<author: record, deleted: bool, description: string, eventDate: string, events: list, featuredCategory: string, id: int, latestComments: list, mainPicture: record, name: string, status: string, tags: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "tagId[]" $tag_id "multi") (serialize-qp "childTags" $child_tags "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/users/{id}/songLists") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "tagId[]": $tag_id, "childTags": $child_tags, "nameMatchMode": $name_match_mode, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "sort": $qp_sort, "fields": $fields} | compact), body: null}
}

# GET /api/venues
export def "venues get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --query: string # default: 
  --fields: string@fields-completer-13
  --start: int # format: int32, default: 0
  --max-results: int # format: int32, default: 10
  --get-total-count: oneof<nothing, bool> # default: false
  --name-match-mode: string@name-match-mode-completer
  --lang: string@lang-completer
  --sort-rule: string@sort-rule-completer-1
  --latitude: float # format: double
  --longitude: float # format: double
  --radius: float # format: double
  --distance-unit: string@distance-unit-completer
]: nothing -> record<items: table<additionalNames: string, address: string, addressCountryCode: string, coordinates: record, deleted: bool, description: string, events: list, id: int, name: string, names: list, status: string, version: int, webLinks: list>, term: string, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "maxResults" $max_results "scalar") (serialize-qp "getTotalCount" $get_total_count "scalar") (serialize-qp "nameMatchMode" $name_match_mode "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "sortRule" $sort_rule "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/venues" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "fields": $fields, "start": $start, "maxResults": $max_results, "getTotalCount": $get_total_count, "nameMatchMode": $name_match_mode, "lang": $lang, "sortRule": $sort_rule, "latitude": $latitude, "longitude": $longitude, "radius": $radius, "distanceUnit": $distance_unit} | compact), body: null}
}

# DELETE /api/venues/{id}
export def "venues delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string # default: 
  --hard-delete: oneof<nothing, bool> # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "notes" $notes "scalar") (serialize-qp "hardDelete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/venues/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"notes": $notes, "hardDelete": $hard_delete} | compact), body: null}
}

# POST /api/venues/{id}/reports
export def "venues-reports create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --report-type: string@report-type-completer
  --notes: string
  --version-number: int # format: int32
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "reportType" $report_type "scalar") (serialize-qp "notes" $notes "scalar") (serialize-qp "versionNumber" $version_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/venues/{id}/reports") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reportType": $report_type, "notes": $notes, "versionNumber": $version_number} | compact), body: null}
}
